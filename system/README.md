# System Automation

System scripts with dependencies (must fill out .env file) which help manage and interact with the host system.

These focus on automations which can be quite system-specific.
Think of these as scripts that would require a solid amount of effort to port to another system.
For example, one of the scripts in here nukes a Docker container stack, cleans things up, and restarts them all - obviously, not all systems will be running a Docker container stack, so this is not immediately portable across different systems.

---

## Drive Health Monitoring + Notifications
`drive-health.sh {test | report}`

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


## Set Proper Permissions on Media Files
`scan-media-files.sh`

This simple script sets correct file ownership/permissions for all of my media files

### Prerequisites
This script assumes that:
- You have a directory mounted which contains all of your media files
- You have created and filled out the .env file in `scripts/system`

### Use
While not required for most day-to-day use, you should run this manually whenever you have manually modified anything on your media drive.
