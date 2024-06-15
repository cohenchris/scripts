#!/bin/bash
# Backup music
# To restore: borg extract /backups/music::<backup_name>
#   note: execute this where you would like the 'music' folder to be placed

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" 
    exit 1
fi

# Set up environment
WORKING_DIR=$(dirname "$(realpath "$0")")
source $WORKING_DIR/.env

# Stop Lidarr to prevent files changing while backing up
docker stop lidarr

# 1. Create a borg backup on the local drive
echo "Music Local Backup" >> ${MAIL_FILE}
borg_backup ${MUSIC_DIR_TO_BACKUP} ${MUSIC_LOCAL_BACKUP_DIR}

# 2. Create a borg backup on the remote backup server
echo "Music Remote Backup" >> ${MAIL_FILE}
borg_backup ${MUSIC_DIR_TO_BACKUP} ${REMOTE_BACKUP_SERVER}:${MUSIC_REMOTE_BACKUP_DIR}

# Resume Lidarr
docker start lidarr

# Make a backup of music videos on local and remote backup directories
echo "Music Videos Backup" >> ${MAIL_FILE}
rsync -r --delete --update --progress ${MUSICVIDEOS_DIR_TO_BACKUP}/ ${MUSICVIDEOS_LOCAL_BACKUP_DIR}
mail_log "music videos local backup" $?
rsync -r --delete --update --progress ${MUSICVIDEOS_DIR_TO_BACKUP}/ ${REMOTE_BACKUP_SERVER}:${MUSICVIDEOS_REMOTE_BACKUP_DIR}
mail_log "music videos remote backup" $?

finish
