# Server Automation

Automation scripts related to homelab services running on the host machine.

---

## Send Notifications to Phone via HomeAssistant
[`ha-notify.sh <SUBJECT> <BODY>`](ha-notify.sh)

Used to easily send a notification to the Home Assistant app on my phone.

### Prerequisites
- You have configured a webhook endpoint in HomeAssistant which sends notifications to your desired devices
- You have created and filled out the .env file in `scripts/system`

### Use
This script may be called manually at any time to send notifications to the devices which have been configured to receive notifications in HomeAssistant.




## Monitor Newly Released Albums on Lidarr
[`lidarr-monitor-new-albums.sh`](lidarr-monitor-new-albums.sh)

This script monitors albums if:
1. The artist is monitored
2. The album has been released in the last 30 days
3. The album is not a single

This functionality is built into Lidarr, but has been broken for a while

### Prerequisites
This script assumes that:
- You are running Lidarr
- Lidarr is running on port 8686
- You have created and filled out the .env file in `scripts/system`

### Use
You may either run this script manually or with a scheduled cron job.




## Broadcast Plex Shutdown Message
[`plex-server-maintenance-broadcast.py <plex URL> <plex token>`](plex-server-maintenance-broadcast.py)

Shuts down every active Plex playback session, shows each use a server maintenance message.

### Prerequisites
There are no prerequisites for this script. If the user passes a valid URL and token, it will work as intended.

### Use
To provide a smoother experience for users of your Plex server, it is recommended to run this when shutting down your server for scheduled maintenance.




## Restart Docker Container Stack
[`restart.sh`](restart.sh)

This script restarts all running docker containers and installs packages that Nextcloud needs to provide video file previews.

### Prerequisites
- You have created and filled out the .env file in `scripts/system`

### Use
This script may be called manually at any time to cleanly restart your Docker container stack.




## Test QBittorrent Connectivity
[`test-qbittorrent.sh`](test-qbittorrent.sh)

From time to time, qBittorrent running through a VPN stops being connectable from the external VPN IP.
This issue requires manual restart of both qBittorrent and VPN services.

Instead of manually restarting every time, this script will check for connectivity. If qBittorrent is not connectable, both qBittorrent and VPN Docker containers will be restarted.


### Prerequisites
This script assumes that:
- You are running qBittorrent in Docker
- The qBittorrent Docker container is named 'qbittorrent'
- You are running qBittorrent through a VPN
- The VPN is running in Docker (project name 'gluetun' on Docker Hub)
- The VPN Docker container is named 'vpn'
- You have created and filled out the .env file in `scripts/system`

### Use
It is recommended to run this script as a scheduled cron job.




## Nextcloud
[`nextcloud/`](nextcloud/)

Nextcloud-related scripts.
