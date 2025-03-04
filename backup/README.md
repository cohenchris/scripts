# Backups

Scripts to seamlessly backup different parts of the system.

Unless otherwise documented, the behavior of each of these scripts will be as follows:
1. Backup whatever the script is for
2. Place one copy of backup in a local directory
3. Place one copy of backup in a remote backup server directory
4. Email the results

### Prerequisites and Use
Unless you would like to change exactly *how* step #1 is performed, every script is driven from the .env file.
Before you run any script, check the .env file for a section about that script and fill it in.


This diagram is a visual representation of how I use these scripts to construct a completely automated, redundant, and extensible backup system in my own home:

![Diagram of Backup Flow](backup-diagram.png)

Useful Terminology:
- "local machine" will refer to each of these clients that is present in this network.
- "backup server" will refer to the central server that all of these aforementioned clients backup to.

NOTE: You MUST run `cp sample.env .env` and fill out the required variables for each script you will be running.

---

## Backblaze Remote Backup
[`backblaze.sh`](backblaze.sh)

This script backs up a single directory tree to a remote Backblaze B2 bucket.
Think of this as the "1" in "3-2-1 backup system".

### Prerequisites
- [`.env`](sample.env) file is filled out for `backblaze.sh`
- Backblaze package is installed
- Have an authorized Backblaze session to your bucket of choice under the root account

### Use
Since this script is intended to backup all backup directories to ONE Backblaze bucket, it should be scheduled as a cron job on the backup server.

This script will have conflicts with **every** other script in this directory. Please ensure that there are ZERO backups in-progress before running this script.




## Switch Backup
[`backup-switch.cmd`](backup-switch.cmd)

This script is a unique case.
I have a Cisco SG300-28PP, which is unable to execute cron jobs.
I don't update the switch very often, so I only back it up when I do change something.
The command present in this file will export a backup directly to the backups server (edit the exact IP to match yours).




## Batocera Console Backup
[`batocera.sh`](batocera.sh)

[Batocera]() is a console emulation project.
All of the save data, configuration data, game downloads, and more are saved in `/userdata`.
This script is responsible for backing up this `/userdata` directory.


### Use
On the backup destination server, set up a cron job to execute this scriipt when desired.
Batocera is a firmware image and cannot be modified (no installing new packages). Therefore, the backup must be triggered by the backup destination server, rather than Batocera itself.





## Common Backup Functions
[`common.sh`](common.sh)

This script functions as a common library for all other backup scripts - it should **NEVER** be run from the command line.

### Use
To use from another script, please do the following:

```sh
source ./common.sh
```

Now, all of the functions declared in `common.sh` will be available for use.




## Critical Data Backup
[`critical-data.sh`](critical-data.sh)

This script compiles all of the most critical data that I own - data that I would need to restore my data in absolute worst-case scenarios, including:
- Mobile 2FA Authenticator Backup
- Bitwarden Password Manager Backup
- Encrypted file including critical passwords and 2FA recovery codes.

It stores this data on both the backup server AND a directory in your nextcloud installation.

### Prerequisites
- [`.env`](sample.env) file is filled out for `critical-data.sh`
- Bitwarden CLI package is installed
- Have an authorized Bitwarden session to your server of choice under the root account

### Use
On your local machine of choice, set up a cron job to execute this script when desired.

Due to the Nextcloud facet of this script, it will conflict with `server.sh`.
Also, please do not run `manual-usbs-critical-data.sh` during this script's execution, as that script works off of the same directories that this script uses.




## "Cloud" Files Backup
[`files.sh`](files.sh)

...
### Use




## Critical Data Backup - 2x Manual USB Cold Backup
[`manual-usbs-critical-data.sh`](manual-usbs-critical-data.sh)

...
### Use




## Music Backup
[`music.sh`](music.sh)

...
### Use




## OpenWRT Backup
[`openwrt.sh`](openwrt.sh)

...
### Use




## OPNSense + AdGuard Backup
[`opnsense.sh`](opnsense.sh)

...
### Use




## Server Backup
[`server.sh`](server.sh)

...
### Use








## Setup
5. Set up a cron job to execute files.sh, server.sh, music.sh, and critical-data.sh when desired.
    - Make sure to stagger to prevent backup corruption. For example, I execute critical-data.sh and music.sh at 3am, files.sh at 4am, and server.sh at 5am daily.

## Manual Double USB Cold Backups
- As part of my 3-2-1 backup system, I have 2x USB sticks in a fireproof safe with the very basics that I would need to restore backups in a worst-case-scenario.


## Interacting with borg backups
To list the backups present in a borg archive store, run the following:

`sudo borg mount /path/to/borg/repository::<backup_name> /path/to/mountpoint`


To extract a given borg backup into the current directory, run the following:

`sudo borg extract /path/to/borg/repository::<backup_name>`


To mount a given borg backup to a specified mount point and view the backup without fully extracting, run the following:

`sudo borg mount /path/to/borg/repository::<backup_name> /path/to/mountpoint`


## Resources:
- [Backup with Borg](https://jstaf.github.io/2018/03/12/backups-with-borg-rsync.html)
