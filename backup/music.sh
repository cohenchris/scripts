#!/bin/bash
# Backup music
# To restore: borg extract /backups/music::<backup_name>
#   note: execute this where you would like the 'music' folder to be placed

# Set up environment
WORKING_DIR=$(dirname "$(realpath "$0")")
source ${WORKING_DIR}/.env

require var MUSIC_DIR
require var MUSIC_LOCAL_BACKUP_DIR
require var REMOTE_BACKUP_SERVER
require var MUSIC_REMOTE_BACKUP_DIR
require var MUSICVIDEOS_DIR
require var MUSICVIDEOS_LOCAL_BACKUP_DIR
require var MUSICVIDEOS_REMOTE_BACKUP_DIR

# Stop Lidarr to prevent files changing while backing up
mail_log plain "Stopping Lidarr to prevent conflicts with music files..."
docker stop lidarr
mail_log check "Lidarr stop" $?

# Create a borg backup on the local drive
mail_log plain "Backing up music data locally..."
borg_backup ${MUSIC_DIR} ${MUSIC_LOCAL_BACKUP_DIR} ${MUSIC_EXCLUDE_REGEX[*]}
mail_log check "Music local backup" $?

# Create a borg backup on the remote backup server
mail_log plain "Backing up music data on remote backup server..."
borg_backup ${MUSIC_DIR} ${REMOTE_BACKUP_SERVER}:${MUSIC_REMOTE_BACKUP_DIR} ${MUSIC_EXCLUDE_REGEX[*]}
mail_log check "Music remote backup" $?

# Resume Lidarr
mail_log plain "Resuming Lidarr..."
docker start lidarr
mail_log check "Lidarr start" $?

# Make a backup of music videos on local and remote backup directories
mail_log plain "Backing up music video data locally..."
rsync -r --delete --update --progress ${MUSICVIDEOS_DIR}/ ${MUSICVIDEOS_LOCAL_BACKUP_DIR}
mail_log check "Music video local backup" $?

mail_log plain "Backing up music video data on remote backup server..."
rsync -r --delete --update --progress ${MUSICVIDEOS_DIR}/ ${REMOTE_BACKUP_SERVER}:${MUSICVIDEOS_REMOTE_BACKUP_DIR}
mail_log check "Music video remote backup" $?

finish
