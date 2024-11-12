#!/bin/bash
# Backup music
# To restore: borg extract /backups/music::<backup_name>
#   note: execute this where you would like the 'music' folder to be placed

# Set up environment
WORKING_DIR=$(dirname "$(realpath "$0")")
source ${WORKING_DIR}/.env

require MUSIC_DIR
require MUSIC_LOCAL_BACKUP_DIR
require REMOTE_BACKUP_SERVER
require MUSIC_REMOTE_BACKUP_DIR
require MUSICVIDEOS_DIR
require MUSICVIDEOS_LOCAL_BACKUP_DIR
require MUSICVIDEOS_REMOTE_BACKUP_DIR

# Stop Lidarr to prevent files changing while backing up
docker stop lidarr
mail_log check "lidarr stop" $?

# Create a borg backup on the local drive
mail_log plain "Music Local Backup"
borg_backup ${MUSIC_DIR} ${MUSIC_LOCAL_BACKUP_DIR}

# Create a borg backup on the remote backup server
mail_log plain "Music Remote Backup"
borg_backup ${MUSIC_DIR} ${REMOTE_BACKUP_SERVER}:${MUSIC_REMOTE_BACKUP_DIR}

# Resume Lidarr
docker start lidarr
mail_log check "lidarr start" $?

# Make a backup of music videos on local and remote backup directories
mail_log plain "Music Videos Backup"
rsync -r --delete --update --progress ${MUSICVIDEOS_DIR}/ ${MUSICVIDEOS_LOCAL_BACKUP_DIR}
mail_log check "music videos local backup" $?
rsync -r --delete --update --progress ${MUSICVIDEOS_DIR}/ ${REMOTE_BACKUP_SERVER}:${MUSICVIDEOS_REMOTE_BACKUP_DIR}
mail_log check "music videos remote backup" $?

finish
