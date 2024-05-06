#!/bin/bash
# Backup files
# To restore: borg extract /backups/files::<backup_name>
#   note: execute this where you would like the 'files' folder to be placed

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" 
    exit 1
fi

# Set up environment
source $(dirname "$0")/.env

# Put Nextcloud in maintenance mode to prevent file changes
docker exec -it -u www-data nextcloud php occ maintenace:mode --on

# 1. Create a backup to local drive
borg_backup ${FILES_DIR_TO_BACKUP} ${FILES_LOCAL_BACKUP_DIR}

# Take Nextcloud out of maintenance mode
docker exec -it -u www-data nextcloud php occ maintenace:mode --off

# 2. Rsync a copy of the backup to remote backup server
remote_sync ${FILES_LOCAL_BACKUP_DIR} ${FILES_REMOTE_BACKUP_DIR}

# 3. Sync a copy of the backup to Backblaze B2
backblaze_sync ${FILES_LOCAL_BACKUP_DIR} ${FILES_BACKUP_BUCKET}

finish
