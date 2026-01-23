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
  - [Prerequisites](#Prerequisites-1)
  - [Use](#Use)
- [Backblaze Bucket Quick Mount + Unmount via RClone](#Backblaze-Bucket-Quick-Mount-+-Unmount-via-RClone)
  - [Prerequisites](#Prerequisites-2)
  - [Use](#Use-2)
- [Music Video Downloader](#Music-Video-Downloader)
  - [Prerequisites](#Prerequisites-3)
  - [Use](#Use-3)



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
It also assumes that the user has a docker-compose stack located at `/home/${USER}/server`.

1. Synchronize, install, and upgrade all packages
2. Clean the package cache to remove unused packages
3. Update all docker-compose images
4. Remove all dangling docker container images
5. Mirror EFI boot partitions on mirrored ZFS root pool

### Prerequisites

### Use



## Backblaze Bucket Quick Mount + Unmount via RClone
[`b2-mount.sh [mount, unmount] [dirname]`](b2-mount.sh)

I store all of my remote backups (the "1" in 3-2-1 backups) in a Backblaze B2 buckets.
Sometimes, it's useful to navigate this bucket manually to check out its contents.
RClone is a fantastic tool that allows mounting of a Backblaze B2 bucket to your local machine, and this script streamlines the rclone mount/unmount process.

Utilizing an rclone remote under the hood, this script cleanly mounts and unmounts a given backblaze bucket under `dirname`.

### Prerequisites
This script assumes that:
- `rclone` is installed on your machine
- You have filled out the [`.env`](sample.env) file
- There is an rclone remote configured for the remote specified in [`.env`](sample.env)

### Use



## Music Video Downloader
[`mvdl.sh [FILE]`](mvdl.sh)

This script reads in a file which contains newline-separated YouTube music video URLs.
If there is a music file and music video file with the same name, Plex can automatically detect this and associate the two files.
If there is a music file with an associated music video file, Plex will allow you to play either file.
This script is an attempt to automate the process of pulling + renaming music videos for this feature.
You may read about this naming process [here](https://support.plex.tv/articles/205568377-adding-local-artist-and-music-videos/).

This script is pretty hardcoded to my personal environment and directory structure.

1. User points the script to music and music video directories
2. Download each video
3. Based on the title of the music video, attempt to find a matching music file
4. If a match is found, rename the downloaded music video according to the standard linked above
5. If a match is not found, rename the downloaded music video to a cleaner, more readable version

### Prerequisites

### Use
