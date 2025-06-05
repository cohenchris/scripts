# Server Automation

Automation scripts related to homelab services running on the host machine.




# Table of Contents

- [Send Notifications to Phone via HomeAssistant](#Send-Notifications-to-Phone-via-HomeAssistant)
  - [Prerequisites](#Prerequisites)
  - [Use](#Use)
- [Monitor Newly Released Albums on Lidarr](#Monitor-Newly-Released-Albums-on-Lidarr)
  - [Prerequisites](#Prerequisites-1)
  - [Use](#Use-1)
- [Broadcast Plex Shutdown Message](#Broadcast-Plex-Shutdown-Message)
  - [Prerequisites](#Prerequisites-2)
  - [Use](#Use-2)
- [Restart Docker Container Stack](#Restart-Docker-Container-Stack)
  - [Prerequisites](#Prerequisites-3)
  - [Use](#Use-3)
- [Test QBittorrent Connectivity](#Test-QBittorrent-Connectivity)
  - [Prerequisites](#Prerequisites-4)
  - [Use](#Use-4)
- [Music Rating Progress](#Music-Rating-Progress)
  - [Prerequisites](#Prerequisites-5)
  - [Use](#Use-5)
- [Nextcloud](#Nextcloud)




## Send Notifications to Phone via HomeAssistant
[`ha-notify.sh <SUBJECT> <BODY>`](ha-notify.sh)

Used to easily send a notification to the Home Assistant app on my phone.

### Prerequisites
- You have configured a webhook endpoint in HomeAssistant which sends notifications to your desired devices
- You have created and filled out the [`.env` file in `scripts/system`](../sample.env) 

### Use
This script may be called manually at any time to send notifications to the devices which have been configured to receive notifications in HomeAssistant.

**IMPORTANT NOTE**

If you would like to run this on your router, make sure `HA_NOTIFY_WEBHOOK_ENDPOINT` is using the internal http://domain:port format instead of the external domain. Port 443 is used by the OPNSense web GUI, and by default, a HomeAssistant webhook endpoint will use port 443. NAT hairpinning does not work on ports that are being used by the OPNSense web GUI.

For example, instead of:
```
https://homeassistant.example.com/api/webhook/<webhook_id>
```
use:
```
http://homeassistant.lan:8123/api/webhook/<webhook_id>
```
or:
```
http://192.168.24.3:8123/api/webhook/<webhook_id>
```




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
- You have created and filled out the [`.env` file in `scripts/system`](../sample.env) 

### Use
You may either run this script manually or with a scheduled cron job.




## Broadcast Plex Shutdown Message
[`plex-server-maintenance-broadcast.py <plex URL> <plex token>`](plex-server-maintenance-broadcast.py)

Shuts down every active Plex playback session, shows each use a server maintenance message.

### Prerequisites
There are no prerequisites for this script. If the user passes a valid URL and token, it will work as intended.

### Use
To provide a smoother experience for users of your Plex server, this script should be run when shutting down Plex for scheduled maintenance.




## Restart Docker Container Stack
[`restart-docker.sh`](restart-docker.sh)

This script restarts all running docker containers and installs packages that Nextcloud needs to provide video file previews.

### Prerequisites
- You have created and filled out the [`.env` file in `scripts/system`](../sample.env) 

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
- You have created and filled out the [`.env` file in `scripts/system`](../sample.env) 

### Use
This script should be set up as a scheduled cron job.




## Music Rating Progress
[`music-rating-progress-sheet.py`](music-rating-progress-sheet.py)

I love listening to and rating music (see [the ratings page on my website!](https://chriscohen.dev/music)).

This script generates an excel spreadsheet which helps me track my listening progress.
The excel spreadsheet is created in the directory from which this script is invoked.

The spreadsheet contains a table which lists each artist in my Plex music library, each of their albums, and how many of their albums that I have rated.
The album cells are highlighted in green if fully rated, and red otherwise.
The rating progress cells highlighted in the same way - green if I have rated every album, and red otherwise.

At the very bottom, I've also included a cell which calculates my overall listening progress.


### Prerequisites
- You have created and filled out the [`.env` file in `scripts/system`](../sample.env) 


### Use
This script should be run manually.



## Nextcloud
[`nextcloud/`](nextcloud/)

Nextcloud-related scripts.
