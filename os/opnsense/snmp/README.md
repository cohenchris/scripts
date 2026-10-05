# OPNSense SNMP Extensions

Scripts and configuration to expose custom metrics over SNMP on a machine running the FreeBSD-based OPNSense distribution.




# Table of Contents

- [SNMP System Monitor Extension](#SNMP-System-Monitor-Extension)
  - [OID Layout](#OID-Layout)
  - [Use](#Use)
- [SNMP Setup Script](#SNMP-Setup-Script)
  - [Prerequisites](#Prerequisites)
  - [Use](#Use-1)




## SNMP System Monitor Extension
[`snmp-sysmon.py <command> [args...]`](snmp-sysmon.py)

This script is an `snmpd` `pass_persist` handler which exposes the output of any JSON-producing command over SNMP.
It is intended to be used with [`system-monitor.py`](../../../system/system-monitor.py), so that system health metrics (uptime, CPU usage, memory/swap usage, temperatures, disk usage, etc.) can be polled over SNMP.

On each refresh, the given command is run, and its JSON output is flattened into dotted metric names (e.g. `memory.used`, `disks.0.percent`).
Results are cached for 10 seconds, since a single SNMP walk queries many OIDs. If the command fails, the last good data is kept.

A few things to note:
- SNMP has no float type, so floats (and strings) are exposed as `STRING`. Integers and booleans are exposed as `INTEGER`.
- `null` values (e.g. no GPU present) are skipped entirely.
- The subtree is read-only. Any `set` request is rejected as `not-writable`.

### OID Layout
All metrics are exposed under the private subtree `.1.3.6.1.4.1.99999.1` (change `BASE` within the script to use a different one).

| OID                                | Description                                                                 |
| ---------------------------------- | --------------------------------------------------------------------------- |
| `<BASE>.0`                         | Number of metrics                                                           |
| `<BASE>.1.<index>`                 | Metric name, by index                                                       |
| `<BASE>.2.<index>`                 | Metric value, by index                                                      |
| `<BASE>.3.<length>.<ascii chars>`  | Metric value, by name (stable, unlike indices, which shift if metrics change) |

### Use
This script is not meant to be run by hand. Instead, it's registered with `snmpd` via a `pass_persist` line:
```
pass_persist .1.3.6.1.4.1.99999.1 /path/to/snmp-sysmon.py /usr/local/bin/python3 /path/to/system-monitor.py
```

This is done automatically by the [SNMP setup script](#SNMP-Setup-Script).




## SNMP Setup Script
[`setup.sh`](setup.sh)

This script registers the [SNMP system monitor extension](#SNMP-System-Monitor-Extension) with OPNSense's `snmpd` by writing a `pass_persist` entry to `/usr/local/etc/snmp/snmpd.local.conf`, then restarts the SNMP service.

**NOTE:** This overwrites any existing `/usr/local/etc/snmp/snmpd.local.conf`.

### Prerequisites
- The `os-net-snmp` plugin is installed, and SNMP is enabled from the OPNSense web UI (Services --> Net-SNMP)
- `python3` is installed and in your `PATH`
- Optionally, you have populated the [`.env`](../../../system/sample.env) file for [`system-monitor.py`](../../../system/system-monitor.py) (`SYSTEM_MONITOR_DISKS`)

### Use
Must be run as root, from within this directory, since the base of this git repository is resolved relative to the current working directory:
```sh
cd os/opnsense/snmp
./setup.sh
```

Then, verify from another machine by walking the subtree:
```sh
snmpwalk -v2c -c <community> <opnsense-host> .1.3.6.1.4.1.99999.1
```
