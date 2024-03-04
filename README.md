# Scripts

#### `auto-restart-502.sh`
- At times, I get some inexplicable 502 errors for some services that I run. This script restarts any services with a 502 error.

#### `dynamic-seedbox.sh`
- Sends the IP of qbittorrent to MyAnonamouse, which requires the correct IP in order to record ratios.

#### `ha-notify.py`
- A python script to easily send a notification to the Home Assistant app on my phone.
- Make sure to fill in `HA_NOTIFY_WEBHOOK_ENDPOINT` in `sample.env`.

#### `restart.sh`
- This script restarts all running docker containers, installs packages that Nextcloud needs to provide video file previews, and updates the MyAnonamouse seedbox IP address (see `dynamic-seedbox.sh` section)

#### `scan-nextcloud-files.sh`
- This script sets all file permissions and ownerships for my Nextcloud files. This ensures proper access controls for the Nextcloud web UI. Afterwards, it has Nextcloud scan all files, ensuring that the web UI is aware of and displays all present files.

#### `smartctl-summary.sh`
- This script sends a drive health summary email to my inbox.
- Make sure to fill in `EMAIL` in `sample.env`

#### `update.sh`
- This script updates all installed packages on this system, and updates all running docker containers.

*Make sure to `mv sample.env .env` for environment variables to take effect*

#### `manual-usbs-misc-backup.sh`
- As part of my 3-2-1 backup system, I have 2x USB sticks in a fireproof safe with the very basics that I would need to restore backups in a worst-case-scenario.
