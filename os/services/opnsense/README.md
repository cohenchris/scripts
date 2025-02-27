# OPNSense

These are scripts and configuration files meant to be installed and used on an OPNSense router.

---

## Glances System Monitoring Startup Service
[`glances`](glances)

This is a FreeBSD service which runs the Glances system monitor in webserver mode.

### Prerequisites
...

### Setup
...


## OPNSense Action to Auto-Restart Glances
[`actions_backupopnsense.conf`](actions_backupopnsense.conf)

This is an "OPNSense action", which is essentially a cron job that can be configured from the OPNSense web UI.
This action will run a script which makes a full backup of OPNSense and AdGuard Home.
For more details on the exact functionality of said script, please check out [`opnsense.sh`](backups/opnsense.sh) in the `backups` directory.

### Prerequisites
...

### Setup
...


## OPNSense Action to Backup OPNSense + AdGuard
[`actions_restartglances.conf`](actions_restartglances.conf)

This is an "OPNSense action", which is essentially a cron job that can be configured from the OPNSense web UI.
This action will run a script which checks if the Glances system monitor has crashed. If it has, the service will be restarted.
For context, there is a known bug in FreeBSD which causes Glances to randomly crash when sensor monitoring is enabled.
Sensor monitoring is the biggest reason that I wanted Glances running in the first place, so this is my fix.
For more details on the exact functionality of said script, please check out [`restart-glances.sh`](system/restart-glances.sh) in the `system` directory.

### Prerequisites
...

### Setup
...
