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

# 1. Create a borg backup on the local drive
echo "Local Backup" >> ${MAIL_FILE}
borg_backup ${MUSIC_DIR_TO_BACKUP} ${MUSIC_LOCAL_BACKUP_DIR}

# 2. Create a borg backup on the remote backup server
echo "Remote Backup" >> ${MAIL_FILE}
borg_backup ${MUSIC_DIR_TO_BACKUP} ${REMOTE_BACKUP_SERVER}:${MUSIC_REMOTE_BACKUP_DIR}

finish
