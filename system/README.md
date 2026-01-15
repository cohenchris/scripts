# System Automation

System scripts with dependencies (must fill out .env file) which help manage and interact with the host system.

These focus on automations which can be quite system-specific.
Think of these as scripts that would require a solid amount of effort to port to another system.

**NOTE: You MUST run `cp sample.env .env` and fill out the required variables for each script you will be running.**




# Table of Contents

- [Data Integrity Check](#Data-Integrity-Check)
  - [Prerequisites](#Prerequisites)
  - [Use](#Use)
- [System Update](#System-Update)




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
[`system-update.sh`](system-update.sh)

This script is meant to run on a system running the `paru` AUR helper package manager (likely Arch Linux).
It also assumes that the user has a docker-compose stack located at `/home/${USER}/server.

1. Synchronize, install, and upgrade all packages
2. Clean the package cache to remove unused packages
3. Update all docker-compose images
4. Remove all dangling docker container images
5. Mirror EFI boot partitions on mirrored ZFS root pool
