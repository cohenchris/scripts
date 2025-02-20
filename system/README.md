# Homelab System Scripts

## Requirements
1. Fill out `sample.env`, then `mv sample.env .env` for these scripts to work properly
2. Configure SSMTP and neomutt per instructions in `backups/README.md`, which will enable email notifications

## Drive Health Monitoring + Notifications
`drive-health.sh {test | report}`

This script is used for the monitoring of drive health using smartctl and built-in ZFS monitoring
There are two different functions
1. `test` - full smartctl test, ZFS trim, and ZFS scrub for each drive
2. `report` - email a smartctl and ZFS report for each drive

## Set Proper Permissions on Media Files
`scan-media-files.sh`

This simple script sets the right file ownership/permissions for all of my media files

## Restart Docker Container Stack
`restart.sh`

This script restarts all running docker containers and installs packages that Nextcloud needs to provide video file previews.
