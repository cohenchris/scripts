# Homelab Server Scripts

## Drive Health Monitoring + Notifications
`drive-health.sh {test | report}`

This script is used for the monitoring of drive health using smartctl and built-in ZFS monitoring
There are two different functions
1. `test` - full smartctl test, ZFS trim, and ZFS scrub for each drive
2. `report` - email a smartctl and ZFS report for each drive

## Send Notifications to Phone via HomeAssistant
`ha-notify.sh <SUBJECT> <BODY>`

Used to easily send a notification to the Home Assistant app on my phone.

## Set Proper Permissions + Scan Nextcloud Files
`scan-nextcloud-files.sh`

This script sets all file permissions and ownerships for my Nextcloud files. This ensures proper access controls for the Nextcloud web UI. Afterwards, it has Nextcloud scan all files, ensuring that the web UI is aware of and displays all present files.

## Test QBittorrent Connectivity
`test-qbittorrent.sh`

## Monitor Newly Released Albums on Lidarr
`lidarr_monitor_new_albums.sh`

This script monitors albums if:
1. The artist is monitored
2. The album has been released in the last 30 days
3. The album is not a single

This functionality is built into Lidarr, but has been broken for a while

## Nextcloud AI Task Processing
`nextcloud/nextcloud-ai-taskprocessing.sh`

https://docs.nextcloud.com/server/latest/admin_manual/ai/overview.html#systemd-service

This script improves Nextcloud Assistant's AI task pickup speed responsiveness. By default, an assistant query will be processed as a background job, which is run every 5 minutes. This script, along with `nextcloud-ai-worker@.service`, processes AI tasks as soon as they are scheduled, rather than the user having to wait up to 5 minutes.

To use this script, first modify the script path present in `nextcloud-ai-worker@.service` and move it to the systemd services folder:
`mv nextcloud-ai-worker@.service /etc/systemd/system`

Then, enable and start the service 4 or more times:
`for i in {1..4}; do systemctl enable --now nextcloud-ai-worker@$i.service; done`

Check the status for success and ensure the workers have been deployed:
`systemctl status nextcloud-ai-worker@1.service`
`systemctl list-units --type=service | grep nextcloud-ai-worker`

