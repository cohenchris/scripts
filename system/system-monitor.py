#!/usr/bin/env python3
# =============================================================================
# system-monitor.py — Prints a JSON metrics snapshot to stdout
#
# Supports Linux (/proc, /sys) and FreeBSD (sysctl, swapctl).
# =============================================================================
import ctypes
import glob
import json
import os
import re
import subprocess
import sys
import time
from datetime import datetime


def _read_env():
    """Contents of the .env file next to this script, or "" if missing."""
    env_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env")
    try:
        with open(env_path) as f:
            return f.read()
    except OSError:
        return ""


def _load_env_var(name):
    """Read a scalar variable (NAME="value") from .env, or None if missing/empty."""
    match = re.search(rf'^{name}="([^"]*)"', _read_env(), re.M)
    return (match.group(1).strip() or None) if match else None


def _load_env_array(name):
    """Read a bash-array variable from the .env file next to this script.

    .env uses the same bash-array syntax as the other scripts in this repo
    (see sample.env), e.g.:
        SYSTEM_MONITOR_DISKS=(
        "/"
        "/userdata"
        )
    Returns [] if .env or the variable is missing/empty.
    """
    match = re.search(rf"{name}=\((.*?)\)", _read_env(), re.DOTALL)
    if not match:
        return []

    values = []
    for line in match.group(1).splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        quoted = re.match(r'"([^"]*)"', line)
        if quoted:
            values.append(quoted.group(1))

    return values


MONITOR_PATHS = _load_env_array("SYSTEM_MONITOR_DISKS") or ["/"]
# Network stats are only reported when this is set
MONITOR_INTERFACE = _load_env_var("SYSTEM_MONITOR_INTERFACE")

IS_FREEBSD = sys.platform.startswith("freebsd")

# NVML temperature sensor enum: NVML_TEMPERATURE_GPU
NVML_TEMPERATURE_GPU = 0


def get_uptime():
    """Boot time as e.g. 'Mar 17, 2026 at 11:52 PM', from /proc/stat's btime."""
    with open("/proc/stat") as f:
        for line in f:
            if line.startswith("btime"):
                btime = int(line.split()[1])
                return datetime.fromtimestamp(btime).strftime("%B %-d, %Y at %I:%M %p")
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


def get_net_counters(iface):
    """(rx_bytes, tx_bytes) since boot for iface from /proc/net/dev, or None."""
    with open("/proc/net/dev") as f:
        for line in f.readlines()[2:]:
            name, data = line.split(":", 1)
            if name.strip() == iface:
                fields = data.split()
                return int(fields[0]), int(fields[8])
    return None


def get_gpu():
    """NVIDIA GPU stats via NVML, called directly through ctypes.

    nvidia-smi isn't always available (e.g. on immutable OSes), but the NVML
    shared library ships alongside the driver's GL/Vulkan libs, so we bind to
    it directly instead of shelling out to a CLI tool.
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
                "vram_usage": round(mem.used / mem.total * 100, 1) if mem.total else 0.0,
                "temperature": temp.value,
            }
        finally:
            nvml.nvmlShutdown()
    except (OSError, AttributeError):
        return None


# =============================================================================
# FreeBSD — no /proc or /sys, so everything comes from sysctl(8)/swapctl(8)
# =============================================================================
def _sysctl(*args):
    """Run `sysctl <args>` and return stdout, or None on failure."""
    try:
        result = subprocess.run(
            ["sysctl", *args], capture_output=True, text=True, check=True
        )
    except (OSError, subprocess.CalledProcessError):
        return None
    return result.stdout.strip()


def get_uptime_freebsd():
    """Boot time from kern.boottime, e.g. '{ sec = 1742269920, usec = 0 } ...'."""
    out = _sysctl("-n", "kern.boottime")
    match = re.search(r"sec = (\d+)", out or "")
    if not match:
        return None
    btime = int(match.group(1))
    return datetime.fromtimestamp(btime).strftime("%B %-d, %Y at %I:%M %p")


def get_cpu_usage_freebsd():
    """Overall CPU usage %, sampled over 1 second from kern.cp_time.

    kern.cp_time is aggregate ticks: user nice sys intr idle.
    """
    def read_cp_time():
        fields = [int(x) for x in _sysctl("-n", "kern.cp_time").split()]
        return sum(fields), fields[4]

    total1, idle1 = read_cp_time()
    time.sleep(1)
    total2, idle2 = read_cp_time()

    total_delta = total2 - total1
    idle_delta = idle2 - idle1
    if total_delta <= 0:
        return 0.0
    return round((1 - idle_delta / total_delta) * 100, 1)


def get_memory_usage_freebsd():
    """Memory usage %, treating free + inactive pages as available.

    This is the closest FreeBSD analogue to Linux's MemAvailable.
    """
    names = [
        "vm.stats.vm.v_page_count",
        "vm.stats.vm.v_free_count",
        "vm.stats.vm.v_inactive_count",
    ]
    out = _sysctl("-n", *names)
    if out is None:
        return 0.0
    total, free, inactive = (int(x) for x in out.split())
    if total <= 0:
        return 0.0
    return round((total - free - inactive) / total * 100, 1)


def get_swap_usage_freebsd():
    """Swap usage % from `swapctl -sk` ('Total:  <total_kb>  <used_kb>')."""
    try:
        out = subprocess.run(
            ["swapctl", "-sk"], capture_output=True, text=True, check=True
        ).stdout
    except (OSError, subprocess.CalledProcessError):
        return 0.0
    match = re.search(r"Total:\s+(\d+)\s+(\d+)", out)
    if not match:
        return 0.0
    total, used = int(match.group(1)), int(match.group(2))
    if total <= 0:
        return 0.0
    return round(used / total * 100, 1)


def get_cpu_temps_freebsd():
    """Per-CPU temps in Celsius, or None if unavailable.

    dev.cpu.N.temperature requires the coretemp(4) (Intel) or amdtemp(4)
    (AMD) kernel module. Falls back to ACPI thermal zones.
    """
    temps = []

    # `sysctl -e` prints name=value lines, e.g. dev.cpu.0.temperature=45.0C
    out = _sysctl("-e", "dev.cpu") or ""
    per_cpu = {
        int(m.group(1)): float(m.group(2))
        for m in re.finditer(r"^dev\.cpu\.(\d+)\.temperature=([\d.]+)C", out, re.M)
    }
    temps = [round(per_cpu[i], 1) for i in sorted(per_cpu)]

    # --- ACPI thermal zone fallback ---
    if not temps:
        out = _sysctl("-e", "hw.acpi.thermal") or ""
        for m in re.finditer(r"^hw\.acpi\.thermal\.tz\d+\.temperature=([\d.]+)C", out, re.M):
            temps.append(round(float(m.group(1)), 1))

    return temps or None


def get_net_counters_freebsd(iface):
    """(rx_bytes, tx_bytes) since boot for iface, or None.

    From `netstat -ibn -I <iface> --libxo json`.

    Each interface appears once per address; only the link-level
    ('<Link#N>') row carries the full interface counters.
    """
    try:
        out = subprocess.run(
            ["netstat", "-ibn", "-I", iface, "--libxo", "json"],
            capture_output=True, text=True, check=True,
        ).stdout
        rows = json.loads(out)["statistics"]["interface"]
    except (OSError, subprocess.CalledProcessError, ValueError, KeyError):
        return None

    for row in rows:
        if row.get("network", "").startswith("<Link#"):
            return int(row["received-bytes"]), int(row["sent-bytes"])
    return None


def _network_stats(before, after, elapsed):
    """Current speeds (Mb/s) and total data usage since boot (GB, sent +
    received) for MONITOR_INTERFACE, or None if it wasn't found.

    Negative deltas (counter reset) are clamped to 0.
    """
    if before is None or after is None:
        return None
    rx_delta = max(after[0] - before[0], 0)
    tx_delta = max(after[1] - before[1], 0)

    def mbps(byte_delta):
        return round(byte_delta * 8 / elapsed / 1e6, 2) if elapsed > 0 else 0.0

    def gb(total_bytes):
        return round(total_bytes / 1e9, 2)

    return {
        "interface": MONITOR_INTERFACE,
        "download": mbps(rx_delta),
        "upload": mbps(tx_delta),
        "total": gb(after[0] + after[1]),
    }


def get_metrics():
    if IS_FREEBSD:
        uptime, cpu_usage, cpu_temps, mem_usage, swap_usage, net_counters = (
            get_uptime_freebsd,
            get_cpu_usage_freebsd,
            get_cpu_temps_freebsd,
            get_memory_usage_freebsd,
            get_swap_usage_freebsd,
            get_net_counters_freebsd,
        )
    else:
        uptime, cpu_usage, cpu_temps, mem_usage, swap_usage, net_counters = (
            get_uptime,
            get_cpu_usage,
            get_cpu_temps,
            get_memory_usage,
            get_swap_usage,
            get_net_counters,
        )

    # Network speed piggybacks on the CPU usage's 1 second sample window
    # rather than sleeping a second time
    if MONITOR_INTERFACE:
        net_before, t_before = net_counters(MONITOR_INTERFACE), time.monotonic()
    cpu = cpu_usage()
    if MONITOR_INTERFACE:
        net_after, t_after = net_counters(MONITOR_INTERFACE), time.monotonic()

    metrics = {
        "uptime": uptime(),
        "cpu": {
            "usage": cpu,
            "temperature": cpu_temps(),
        },
        "memory": {
            "usage": mem_usage(),
            "swap_usage": swap_usage(),
        },
        "disks": get_disks(),
    }
    if MONITOR_INTERFACE:
        metrics["network"] = _network_stats(net_before, net_after, t_after - t_before)
    metrics["gpu"] = get_gpu()
    return metrics


if __name__ == "__main__":
    print(json.dumps(get_metrics(), indent=2))
