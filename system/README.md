# System Automation

System scripts with dependencies (must fill out .env file) which help manage and interact with the host system.

These focus on automations which can be quite system-specific.
Think of these as scripts that would require a solid amount of effort to port to another system.

**NOTE: You MUST run `cp sample.env .env` and fill out the required variables for each script you will be running.**




# Table of Contents

- [Batocera Quick Mount + Unmount via SSHFS](#Batocera-Quick-Mount-+-Unmount-via-SSHFS)
  - [Prerequisites](#Prerequisites)
  - [Use](#Use)
- [Data Integrity Check](#Data-Integrity-Check)
  - [Prerequisites](#Prerequisites-1)
  - [Use](#Use-1)
- [System Update](#System-Update)




## Batocera Quick Mount + Unmount via SSHFS
[`batocera-mount.sh [mount, unmount]`](batocera-mount.sh)

I have an Intel NUC [Batocera](https://batocera.org/) emulation station in my living room.
From their website, "Batocera.linux is an open-source and completely free retro-gaming distribution that can be copied to a USB stick or an SD card with the aim of turning any computer/nano computer into a gaming console during a game or permanently."
It's a pain to manually import games from a USB stick, so this script allows mounting/unmounting of Batocera's `/userdata` directory.

### Prerequisites
This scripts assumes that:
- You have a machine running Batocera
- Batocera is accessible from this computer
- You have filled out the [`.env`](sample.env) file

### Use
`batocera-mount.sh mount`

Mounts Batocera's `/userdata` directory to a newly created `./batocera` directory in the current working directory.


`batocera-mount.sh unmount`

Unmounts and removes the local `./batocera` directory.

## Borg Repository Maintenance
[`borg-maintenance.sh`](borg-maintenance.sh)

This script will run some health checks on each targeted borg repository.
Each repository's contents will first be checked for data corruption.
Afterwards, the repository is defragmented by deleting stale segment files.

### Prerequisites
This script assumes that:
- You have filled out the [`.env`](sample.env) file

### Use
This script should be run manually periodically, maybe once per month or less.
It may take a while to complete, and may require manual intervention depending on the health of the targeted borg repositories.
You should avoid modifying any of the targeted repositories while this script is running.


## Data Integrity Check
[`data-integrity.sh {test | report}`](data-integrity.sh)

This script is used for the monitoring of data integrity.
It uses multiple facets, including:
- smartctl
- ZFS scrubbing and trimming
- borg data verification and compaction

There are two different functions:
1. `test` - full smartctl test, ZFS trim, and ZFS scrub for each drive
2. `report` - email a smartctl and ZFS report for each drive

### Prerequisites
This script assumes that:
- You have created and filled out the .env file in `scripts/system`
- You have set up SSMTP for email notifications (see `arch/services/` for more information)

### Use
It is highly recommmended to run this script with an automated cron job.
If running ZFS, please be wary of excessive trim/scrub commands - I personally run this script once per month.




## System Update
[`system-update`](system-update)

This script is meant to run on a system running the `paru` AUR helper package manager (likely Arch Linux).
It also assumes that the user has a docker-compose stack located at `/home/${USER}/server.

1. Synchronize, install, and upgrade all packages
2. Clean the package cache to remove unused packages
3. Update all docker-compose images
4. Remove all dangling docker container images
5. Mirror EFI boot partitions on mirrored ZFS root pool
