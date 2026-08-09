#!/usr/bin/env python3
# =============================================================================
# batocera-metrics.py — Prints a JSON metrics snapshot to stdout
# Called remotely over SSH by Home Assistant
# =============================================================================
import ctypes
import glob
import json
import os
import time
from datetime import datetime

MONITOR_PATHS = ["/", "/userdata"]

# NVML temperature sensor enum: NVML_TEMPERATURE_GPU
NVML_TEMPERATURE_GPU = 0


def get_uptime():
    """Boot time as e.g. 'Mar 17, 2026 at 11:52 PM', from /proc/stat's btime."""
    with open("/proc/stat") as f:
        for line in f:
            if line.startswith("btime"):
                btime = int(line.split()[1])
                return datetime.fromtimestamp(btime).strftime("%b %-d, %Y at %I:%M %p")
    return None


def get_cpu_usage():
    """Overall CPU usage %, sampled over 1 second."""
    def read_cpu_line():
        with open("/proc/stat") as f:
            fields = f.readline().split()
        user, nice, sys_, idle, iowait, irq, softirq = (int(x) for x in fields[1:8])
        total = user + nice + sys_ + idle + iowait + irq + softirq
        idle_total = idle + iowait
        return total, idle_total

    total1, idle1 = read_cpu_line()
    time.sleep(1)
    total2, idle2 = read_cpu_line()

    total_delta = total2 - total1
    idle_delta = idle2 - idle1
    if total_delta <= 0:
        return 0.0
    return round((1 - idle_delta / total_delta) * 100, 1)


def _read_meminfo():
    values = {}
    with open("/proc/meminfo") as f:
        for line in f:
            key, rest = line.split(":", 1)
            values[key] = int(rest.split()[0])
    return values


def get_memory_usage():
    mem = _read_meminfo()
    total, avail = mem["MemTotal"], mem["MemAvailable"]
    if total <= 0:
        return 0.0
    return round((total - avail) / total * 100, 1)


def get_swap_usage():
    mem = _read_meminfo()
    total, free = mem.get("SwapTotal", 0), mem.get("SwapFree", 0)
    if total <= 0:
        return 0.0
    return round((total - free) / total * 100, 1)


def _read_first_line(path):
    try:
        with open(path) as f:
            return f.readline().strip()
    except OSError:
        return None


def get_cpu_temps():
    """Per-core CPU temps in Celsius, or None if unavailable.

    Probes hwmon first (coretemp/k10temp on x86), then falls back to
    thermal_zone devices (common on ARM/SBCs).
    """
    temps = []

    # --- hwmon path ---
    hwmon_dir = None
    for name_file in glob.glob("/sys/class/hwmon/hwmon*/name"):
        if _read_first_line(name_file) in ("coretemp", "k10temp"):
            hwmon_dir = os.path.dirname(name_file)
            break

    if hwmon_dir:
        # coretemp: temp2_input = Core 0, temp3_input = Core 1, etc.
        # k10temp: per-core/per-CCD via Tccd* labels
        for input_file in sorted(glob.glob(os.path.join(hwmon_dir, "temp*_input"))):
            label_file = input_file.replace("_input", "_label")
            label = _read_first_line(label_file) or ""
            if label.startswith("Core") or label.startswith("Tccd"):
                raw = _read_first_line(input_file)
                if raw is not None:
                    temps.append(round(int(raw) / 1000, 1))

    # --- thermal_zone fallback, preferring CPU-labeled zones ---
    if not temps:
        for type_file in sorted(glob.glob("/sys/class/thermal/thermal_zone*/type")):
            zone_type = _read_first_line(type_file) or ""
            if "cpu" in zone_type.lower() or "x86" in zone_type.lower():
                raw = _read_first_line(type_file.replace("/type", "/temp"))
                if raw is not None:
                    temps.append(round(int(raw) / 1000, 1))

    # --- last resort: any thermal zone at all ---
    if not temps:
        for temp_file in sorted(glob.glob("/sys/class/thermal/thermal_zone*/temp")):
            raw = _read_first_line(temp_file)
            if raw is not None:
                temps.append(round(int(raw) / 1000, 1))

    return temps or None


def get_disks():
    """Dict keyed by sanitized path with {"path", "usage"} entries.

    Mirrors `df`'s Use% calculation (used / (used + available)) rather than
    used/total, since total includes blocks reserved for root.
    """
    disks = {}
    for path in MONITOR_PATHS:
        if not os.path.isdir(path):
            continue
        st = os.statvfs(path)
        used = (st.f_blocks - st.f_bfree) * st.f_frsize
        avail = st.f_bavail * st.f_frsize
        denom = used + avail
        pct = round(used / denom * 100, 1) if denom > 0 else 0.0
        key = path.strip("/").replace("/", "_") or "root"
        disks[key] = {"path": path, "usage": pct}
    return disks


def get_gpu():
    """NVIDIA GPU stats via NVML, called directly through ctypes.

    nvidia-smi isn't available on this (immutable) OS, but the NVML shared
    library ships alongside the driver's GL/Vulkan libs, so we bind to it
    directly instead of shelling out to a CLI tool.
    """
    try:
        try:
            nvml = ctypes.CDLL("libnvidia-ml.so.1")
        except OSError:
            nvml = ctypes.CDLL("libnvidia-ml.so")

        if nvml.nvmlInit_v2() != 0:
            return None

        try:
            count = ctypes.c_uint()
            nvml.nvmlDeviceGetCount_v2(ctypes.byref(count))
            if count.value == 0:
                return None

            handle = ctypes.c_void_p()
            nvml.nvmlDeviceGetHandleByIndex_v2(0, ctypes.byref(handle))

            name_buf = ctypes.create_string_buffer(96)
            nvml.nvmlDeviceGetName(handle, name_buf, ctypes.c_uint(96))

            class Utilization(ctypes.Structure):
                _fields_ = [("gpu", ctypes.c_uint), ("memory", ctypes.c_uint)]

            class Memory(ctypes.Structure):
                _fields_ = [
                    ("total", ctypes.c_ulonglong),
                    ("free", ctypes.c_ulonglong),
                    ("used", ctypes.c_ulonglong),
                ]

            util = Utilization()
            nvml.nvmlDeviceGetUtilizationRates(handle, ctypes.byref(util))

            mem = Memory()
            nvml.nvmlDeviceGetMemoryInfo(handle, ctypes.byref(mem))

            temp = ctypes.c_uint()
            nvml.nvmlDeviceGetTemperature(handle, NVML_TEMPERATURE_GPU, ctypes.byref(temp))

            mib = 1024 * 1024
            return {
                "name": name_buf.value.decode(errors="replace"),
                "usage": util.gpu,
                "memory_usage": round(mem.used / mem.total * 100, 1) if mem.total else 0.0,
                "memory_used_mib": mem.used // mib,
                "memory_total_mib": mem.total // mib,
                "temperature": temp.value,
            }
        finally:
            nvml.nvmlShutdown()
    except (OSError, AttributeError):
        return None


def get_metrics():
    return {
        "uptime": get_uptime(),
        "cpu_usage": get_cpu_usage(),
        "memory_usage": get_memory_usage(),
        "swap_usage": get_swap_usage(),
        "cpu_temperature": get_cpu_temps(),
        "disks": get_disks(),
        "gpu": get_gpu(),
    }


if __name__ == "__main__":
    print(json.dumps(get_metrics(), indent=2))
