# OPNSense Services

Custom services and scripts for a FreeBSD-based OPNSense distribution.




# Table of Contents

- [OPNSense Action to Backup OPNSense + AdGuard](#OPNSense-Action-to-Backup-OPNSense-+-AdGuard)
  - [Prerequisites](#Prerequisites)
  - [Use](#Use)
- [OPNSense Action to Check Data Integrity](#OPNSense-Action-to-Check-Data-Integrity)
  - [Prerequisites](#Prerequisites-1)
  - [Use](#Use-1)




## OPNSense Action to Backup OPNSense + AdGuard
[`actions_backupopnsense.conf`](actions_backupopnsense.conf)

This is an "OPNSense action", which is essentially a cron job that can be configured from the OPNSense web UI.
This action will run a script which makes a full backup of OPNSense and AdGuard Home.
For more details on the exact functionality of said script, please check out [`opnsense.sh`](../../../backup/opnsense.sh) in the `backups` directory.

After this action is installed, you may schedule it from the OPNSense web UI (System --> Settings --> Cron).

### Prerequisites
- You have populated the [`.env`](../../../backup/sample.env) file for [`opnsense.sh`](../../../backup/opnsense.sh)

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




2. Automated setup using [`setup.sh`](setup.sh)




## OPNSense Action to Check Data Integrity
[`actions_dataintegrity.conf`](actions_dataintegrity.conf)

This is an "OPNSense action", which is essentially a cron job that can be configured from the OPNSense web UI.
This action will run a script which, depending on the sub-command selected, can either run a data integrity test or send a data integrity report.

After this action is installed, you may schedule it from the OPNSense web UI (System --> Settings --> Cron).

### Prerequisites
- You have populated the [`.env`](../../../system/sample.env) file for [`data-integrity.sh`](../../../system/data-integrity.sh)
- You are able to send email notifications
- Smartmontools is installed
- If you have ZFS pools, ZFS is installed

### Use
Two options are available to setup this OPNSense action:

1. Manual setup
First, edit `actions_dataintegrity.conf` and replace <scriptsdir> with the path to the BASE of this git repository.
Then, run the following:

```sh
cp ./actions_dataintegrity.conf /usr/local/opnsense/service/conf/actions.d
service configd restart
```
Manually test by running:
```sh
configctl dataintegrity backup
```




2. Automated setup using [`setup.sh`](setup.sh)
