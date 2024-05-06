#!/bin/bash
# Backup music
# To restore: borg extract /backups/music::<backup_name>
#   note: execute this where you would like the 'music' folder to be placed

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" 
    exit 1
fi

# Set up environment
source $(dirname "$0")/.env

# 1. Create a backup to local drive
borg_backup ${MUSIC_DIR_TO_BACKUP} ${MUSIC_LOCAL_BACKUP_DIR}

# 2. Rsync a copy of the backup to remote backup server
remote_sync ${MUSIC_LOCAL_BACKUP_DIR} ${MUSIC_REMOTE_BACKUP_DIR}

finish
