# System Automation

System scripts with dependencies (must fill out .env file) which help manage and interact with the host system.

These focus on automations which can be quite system-specific.
Think of these as scripts that would require a solid amount of effort to port to another system.
For example, one of the scripts in here nukes a Docker container stack, cleans things up, and restarts them all - obviously, not all systems will be running a Docker container stack, so this is not immediately portable across different systems.

**NOTE: You MUST run `cp sample.env .env` and fill out the required variables for each script you will be running.**




# Table of Contents

- [Backblaze Bucket Quick Mount + Unmount via RClone](#Backblaze-Bucket-Quick-Mount-+-Unmount-via-RClone)
  - [Prerequisites](#Prerequisites)
  - [Use](#Use)
- [Batocera Quick Mount + Unmount via SSHFS](#Batocera-Quick-Mount-+-Unmount-via-SSHFS)
  - [Prerequisites](#Prerequisites-1)
  - [Use](#Use-1)
- [Drive Health Monitoring + Notifications](#Drive-Health-Monitoring-+-Notifications)
  - [Prerequisites](#Prerequisites-2)
  - [Use](#Use-2)
- [Restart Glances Webserver](#Restart-Glances-Webserver)
  - [Prerequisites](#Prerequisites-3)
  - [Use](#Use-3)
- [Set Proper Permissions on Media Files](#Set-Proper-Permissions-on-Media-Files)
  - [Prerequisites](#Prerequisites-4)
  - [Use](#Use-4)
- [Server Automation](#Server-Automation)




## Backblaze Bucket Quick Mount + Unmount via RClone
[`b2-fuse.sh [mount, unmount]`](b2-fuse.sh)

I store all of my remote backups (the "1" in 3-2-1 backups) in a Backblaze B2 buckets.
Sometimes, it's useful to navigate this bucket manually to check out its contents.
RClone is a fantastic tool that allows mounting of a Backblaze B2 bucket to your local machine, and this script streamlines the rclone mount/unmount process.

### Prerequisites
This scripts assumes that:
- `rclone` is installed on your machine
- There is an rclone remote configured which is named `backblaze`
- You have populated the [`.env`](sample.env) file

### Use
`b2-fuse.sh mount <dirname>`

Mounts the Backblaze bucket at the location specified by <dirname>.

`b2-fuse.sh unmount <dirname>`

Unmounts the Backblaze bucket at the location specified by <dirname>.




## Batocera Quick Mount + Unmount via SSHFS
[`batocera.sh [mount, unmount]`](batocera.sh)

I have an Intel NUC [Batocera](https://batocera.org/) emulation station in my living room.
From their website, "Batocera.linux is an open-source and completely free retro-gaming distribution that can be copied to a USB stick or an SD card with the aim of turning any computer/nano computer into a gaming console during a game or permanently."
It's a pain to manually import games from a USB stick, so this script allows mounting/unmounting of Batocera's `/userdata` directory.

### Prerequisites
This scripts assumes that:
- You have a machine running Batocera
- Batocera is accessible from this computer
- You have filled out the [`.env`](sample.env) file

### Use
`batocera.sh mount`

Mounts Batocera's `/userdata` directory to a newly created `./batocera` directory in the current working directory.


`batocera.sh unmount`

Unmounts and removes the local `./batocera` directory.




## Drive Health Monitoring + Notifications
[`drive-health.sh {test | report}`](drive-health.sh)

This script is used for the monitoring of drive health using smartctl and built-in ZFS monitoring
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




## Restart Glances Webserver
[`restart-glances.sh`](restart-glances.sh)

This script checks if the Glances system monitoring service has crashed.
If it has, it will restart the service.

Both FreeBSD and Linux systems are supported.

This is really intended to be run on FreeBSD, as there is a known issue with Glances crashing when using the sensor monitoring function.

### Prerequisites
This script assumes that:
- `glances` package is installed
- Glances is running in webserver mode
- Glances webserver is running on port 61208


### Use
While it can be run manually, I highly recommend running this script as a scheduled cron job.




## Set Proper Permissions on Media Files
[`scan-media-files.sh`](scan-media-files.sh)

This simple script sets correct file ownership/permissions for all of my media files

### Prerequisites
This script assumes that:
- You have a directory mounted which contains all of your media files
- You have created and filled out the .env file in `scripts/system`

### Use
While not required for most day-to-day use, you should run this manually whenever you have manually modified anything on your media drive.




## Server Automation
[`server/`](server/)

Scripts relating to server services running on the host machine.
