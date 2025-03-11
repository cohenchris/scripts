# Nextcloud

Nextcloud-related helper scripts.




# Table of Contents

- [Nextcloud AI Task Processing](#Nextcloud-AI-Task-Processing)
  - [Prerequisites](#Prerequisites)
  - [Use](#Use)
- [Nextcloud ffmpeg Installation](#Nextcloud-ffmpeg-Installation)
  - [Prerequisites](#Prerequisites)
  - [Use](#Use)
- [Set Proper Permissions + Scan Nextcloud Files](#Set-Proper-Permissions-+-Scan-Nextcloud-Files)
  - [Prerequisites](#Prerequisites)
  - [Use](#Use)




## Nextcloud AI Task Processing
[`nextcloud/nextcloud-ai-taskprocessing.sh`](nextcloud-ai-taskprocessing.sh)

https://docs.nextcloud.com/server/latest/admin_manual/ai/overview.html#systemd-service

This script improves Nextcloud Assistant's AI task pickup speed responsiveness. By default, an assistant query will be processed as a background job, which is run every 5 minutes. This script, along with [`nextcloud-ai-worker@.service`](../../../os/services/arch/nextcloud-ai-worker@.service), processes AI tasks as soon as they are scheduled, rather than the user having to wait up to 5 minutes.

### Prerequisites
This script assumes that:
- You have Nextcloud installed with Docker
- The Docker container name is 'nextcloud'
- A working Artifical Intelligence provider is configured

### Use
This script is used as a executable for systemd worker services.
These workers will run in the background and check every few seconds for queued AI queries.
If a new query is detected, the worker will immediately process the query.

Systemd service files and documentation are present in [`os/services/arch`](../../../os/services/arch/), please consult that directory for setup.
This script should **not** be run manually.




## Nextcloud ffmpeg Installation
[`nextcloud-install-ffmpeg.sh`](nextcloud-install-ffmpeg.sh)

ffmpeg is a dependency which is not included by default in Nextcloud's docker image.
This is required for various operations, the most important one being the ability to create preview thumbnails for video files.

### Prerequisites
This script assumes:
- You have Nextcloud installed with Docker
- The Docker container name is 'nextcloud'

### Use
This script will need to be called whenever the Nextcloud docker container is created/recreated.
I highly recommend either running this with a cron job or manually calling it from time to time.




## Set Proper Permissions + Scan Nextcloud Files
[`nextcloud-scan-files.sh`](nextcloud-scan-files.sh)

Sets proper file/directory permissions and ownership for everything in Nextcloud's externally-mounted files directory.
Permissions/ownership ensure that the Nextcloud Docker container is able to interact with the directory tree as expected.
A Nextcloud scan is also run, which will index all newly-added files.
This scan is required only when manually adding files to Nextcloud's externally-mounted drive.

For context, an "externally-mounted drive" is a directory on the host machine which is mounted as "external storage" in Nextcloud.

### Prerequisites
This script assumes:
- You have Nextcloud installed with Docker
- The Docker container name is 'nextcloud'
- Your Nextcloud files are mounted with an 'external storage' share which is mounted on the host system.

### Use
While not required for most day-to-day use of Nextcloud, you should run this manually whenever you have manually modified anything on your Nextcloud storage drive.
