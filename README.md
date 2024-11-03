# Homelab Scripts

\*\*NOTE: Please fill out `sample.env`, then `mv sample.env .env` for these scripts to work properly\*\*

## Drive Health Monitoring + Notifications
`drive-health.sh {test | report}`

This script is used for the monitoring of drive health via smartctl (list your drives inside the script)
There are two different functions
1. `test` - run a full smartctl test on the declared drives
2. `report` - email a comprehensive report on the last executed smartctl job

## Send Notifications to Phone via HomeAssistant
`ha-notify.sh <SUBJECT> <BODY>`

Used to easily send a notification to the Home Assistant app on my phone.

## Set Proper Permissions on Media Files
`media-perms.sh`

This simple script sets the right file ownership/permissions for all of my media files

## Restart Docker Container Stack
`restart.sh`

This script restarts all running docker containers, installs packages that Nextcloud needs to provide video file previews, and updates the MyAnonamouse seedbox IP address (see `dynamic-seedbox.sh` section)

## Set Proper Permissions + Scan Nextcloud Files
`scan-nextcloud-files.sh`

This script sets all file permissions and ownerships for my Nextcloud files. This ensures proper access controls for the Nextcloud web UI. Afterwards, it has Nextcloud scan all files, ensuring that the web UI is aware of and displays all present files.

## Test QBittorrent Connectivity
`test-qbittorrent.sh`

This script checks to see if qBittorrent is connectable. If it is not, it will restart the program.
## Dynamic Seedbox Update
`dynamic-seedbox.sh`

Sends the IP of qbittorrent to MyAnonamouse, which requires the correct IP in order to record ratios.


## Monitor Newly Released Albums on Lidarr
`lidarr_monitor_new_albums.sh`

This script monitors albums if:
1. The artist is monitored
2. The album has been released in the last 30 days
3. The album is not a single

This functionality is built into Lidarr, but has been broken for a while
