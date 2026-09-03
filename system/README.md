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
- [Backblaze Bucket Quick Mount + Unmount via RClone](#Backblaze-Bucket-Quick-Mount--Unmount-via-RClone)
  - [Prerequisites](#Prerequisites-1)
  - [Use](#Use-1)
- [Music Video Downloader](#Music-Video-Downloader)
  - [Prerequisites](#Prerequisites-2)
  - [Use](#Use-2)
- [System Monitor](#System-Monitor)
  - [Use](#Use-3)
- [Systemd Watchdog](#Systemd-Watchdog)
  - [Use](#Use-4)
- [WireGuard Uptime](#WireGuard-Uptime)
  - [Prerequisites](#Prerequisites-3)
  - [Use](#Use-5)



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
- You have filled out the [`.env`](sample.env) file
- You have set up MSMTP for email notifications (see [`os/email/`](os/email/) for more information)

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
To mount a B2 bucket to `/path/to/b2/mount/dir`:
```sh
./b2-mount.sh mount my-bucket-name /path/to/b2/mount/dir
```

To unmount the same B2 bucket:
```sh
./b2-mount.sh umount /path/to/b2/mount/dir
```



## Music Video Downloader
[`mvdl.py (--infile FILE | --playlist URL)`](mvdl.py)

This script downloads YouTube music videos, either from a file containing newline-separated URLs or from a YouTube playlist URL.
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
This script assumes that:
- You have filled out the [`.env`](sample.env) file
- You have `yt-dlp` installed as a Python package (`pip install yt-dlp`)
- You have either a plaintext file with newline-separated YouTube video URLs, or a YouTube playlist URL, to download.

### Use
To use this script, invoke it with either `--infile` (path to a URL file) or `--playlist` (a YouTube playlist URL). These options are mutually exclusive.




## System Monitor
[`system-monitor.py`](system-monitor.py)

This script prints a JSON snapshot of a system's health metrics to stdout, including uptime, CPU usage, memory/swap usage, per-core CPU temperatures, disk usage, and NVIDIA GPU stats (usage, memory, temperature) via direct NVML bindings.

It's dependency-free (standard library only), which matters on immutable OSes that lack `nvidia-smi` or a package manager to install one.

### Use
```sh
python3 system-monitor.py
```




## Systemd Watchdog
[`systemd-watchdog.sh <service>`](systemd-watchdog.sh)

This script checks whether a given systemd service is currently active, and restarts it if it is not. If the given service does not exist, the script exits with an error.

### Use
Must be run as root, with the name of the systemd service to watch as the first argument. Intended to be run periodically via cron.
```sh
sudo ./systemd-watchdog.sh glances
```




## WireGuard Uptime
[`wireguard-uptime.sh`](wireguard-uptime.sh)

This script monitors a WireGuard tunnel and reports its health to a push-monitoring webhook (such as an [Uptime Kuma](https://github.com/louislam/uptime-kuma) push monitor).

1. Check whether the configured WireGuard interface has an established peer
2. If it does, ping a known host through the tunnel to confirm traffic actually flows
3. Push the resulting status (`up`/`down`), a human-readable message, and the round-trip latency to the webhook

### Prerequisites
This script assumes that:
- You have filled out the [`.env`](sample.env) file (`WG_INTERFACE` and `WEBHOOK_URL`)
- `wg`, `ping`, and `curl` are installed on your machine

### Use
It is intended to run periodically via cron. It takes no arguments.
```sh
./wireguard-uptime.sh
```
