# Scripts

**Please fill out `sample.env`, then `mv sample.env .env` for these scripts to work properly**

#### `drive-health.sh {test | report}`
- This script is used for the monitoring of drive health via smartctl (list your drives inside the script)
- There are two different functions
   - `test` - run a full smartctl test on the declared drives
   - `report` - email a comprehensive report on the last executed smartctl job

#### `dynamic-seedbox.sh`
- Sends the IP of qbittorrent to MyAnonamouse, which requires the correct IP in order to record ratios.

#### `ha-notify.sh <SUBJECT> <BODY>`
- Used to easily send a notification to the Home Assistant app on my phone.

#### `media-perms.sh`
- This simple script sets the right file ownership/permissions for all of my media files

#### `restart.sh`
- This script restarts all running docker containers, installs packages that Nextcloud needs to provide video file previews, and updates the MyAnonamouse seedbox IP address (see `dynamic-seedbox.sh` section)

#### `scan-nextcloud-files.sh`
- This script sets all file permissions and ownerships for my Nextcloud files. This ensures proper access controls for the Nextcloud web UI. Afterwards, it has Nextcloud scan all files, ensuring that the web UI is aware of and displays all present files.

#### `test-qbittorrent.sh`
- This script checks to see if qBittorrent is connectable. If it is not, it will restart the program.
