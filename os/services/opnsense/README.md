# OPNSense Services

Custom services and scripts for a FreeBSD-based OPNSense distribution.




# Table of Contents

- [Glances System Monitoring Startup Service](#Glances-System-Monitoring-Startup-Service)
  - [Prerequisites](#Prerequisites)
  - [Use](#Use)
- [OPNSense Action to Auto-Restart Glances](#OPNSense-Action-to-Auto-Restart-Glances)
  - [Prerequisites](#Prerequisites-1)
  - [Use](#Use-1)
- [OPNSense Action to Backup OPNSense + AdGuard](#OPNSense-Action-to-Backup-OPNSense-+-AdGuard)
  - [Prerequisites](#Prerequisites-2)
  - [Use](#Use-2)




## Glances System Monitoring Startup Service
[`glances`](glances)

This is a FreeBSD service which runs the Glances system monitor in webserver mode.

### Prerequisites
- Port 61208 (glances default) is unused by other system services

### Use
There are two options to install this FreeBSD service:

1. Manual setup

```sh
pkg update
pkg install py311-glances
cp ./glances /usr/local/etc/rc.d
echo 'glances_enable="YES"' >> /etc/rc.conf
service glances enable
service glances start
```



2. Automated setup using [`IMPORT.sh`](IMPORT.sh)




## OPNSense Action to Auto-Restart Glances
[`actions_restartglances.conf`](actions_restartglances.conf)

This is an "OPNSense action", which is essentially a cron job that can be configured from the OPNSense web UI.
This action will run a script which checks if the Glances system monitor has crashed. If it has, the service will be restarted.
For context, there is a known bug in FreeBSD which causes Glances to randomly crash when sensor monitoring is enabled.
Sensor monitoring is the biggest reason that I wanted Glances running in the first place, so this is my fix.
For more details on the exact functionality of said script, please check out [`restart-glances.sh`](../../../system/restart-glances.sh) in the `system` directory.

After this action is installed, you may schedule it from the OPNSense web UI (System --> Settings --> Cron).

### Prerequisites
- Prerequisites for the above `glances` script have been met.

### Use
Two options are available to setup this OPNSense action:

1. Manual setup
First, edit `actions_restartglances.conf` and replace <scriptsdir> with the path to the BASE of this git repository.
Then, run the following:

```sh
cp ./actions_restartglances.conf /usr/local/opnsense/service/conf/actions.d
service configd restart
```

Manually test by running:
```sh
configctl backupopnsense backup
```




2. Automated setup using [`IMPORT.sh`](IMPORT.sh)




## OPNSense Action to Backup OPNSense + AdGuard
[`actions_backupopnsense.conf`](actions_backupopnsense.conf)

This is an "OPNSense action", which is essentially a cron job that can be configured from the OPNSense web UI.
This action will run a script which makes a full backup of OPNSense and AdGuard Home.
For more details on the exact functionality of said script, please check out [`opnsense.sh`](../../../backup/opnsense.sh) in the `backups` directory.

After this action is installed, you may schedule it from the OPNSense web UI (System --> Settings --> Cron).

### Prerequisites
- You have populated the [`.env`](../../../backup/sample.env) file for [`opnsense.sh`](../../../backup/opnsense..sh)

### Use
Two options are available to setup this OPNSense action:

1. Manual setup
First, edit `actions_backupopnsense.conf` and replace <scriptsdir> with the path to the BASE of this git repository.
Then, run the following:

```sh
cp ./actions_backupopnsense.conf /usr/local/opnsense/service/conf/actions.d
service configd restart
```
Manually test by running:
```sh
configctl backupopnsense backup
```




2. Automated setup using [`IMPORT.sh`](IMPORT.sh)
