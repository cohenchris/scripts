#!/usr/bin/env bash
# Backup music
# To restore: borg extract /backups/music::<backup_name>
#   note: execute this where you would like the 'music' folder to be placed

# Set up environment
WORKING_DIR=$(dirname "$(realpath "$0")")
source "${WORKING_DIR}/.env"
source "${WORKING_DIR}/common.sh"

require var "${MUSIC_DIR}" || exit 1
require var "${MUSIC_LOCAL_BACKUP_DIR}" || exit 1
require var "${REMOTE_BACKUP_SERVER}" || exit 1
require var "${MUSIC_REMOTE_BACKUP_DIR}" || exit 1
require var "${MUSIC_BACKUP_KEEP_DAILY}" || exit 1
require var "${MUSIC_BACKUP_KEEP_WEEKLY}" || exit 1
require var "${MUSIC_BACKUP_KEEP_MONTHLY}" || exit 1
require var "${MUSICVIDEOS_DIR}" || exit 1
require var "${MUSICVIDEOS_LOCAL_BACKUP_DIR}" || exit 1
require var "${MUSICVIDEOS_REMOTE_BACKUP_DIR}" || exit 1

# Stop Lidarr to prevent files changing while backing up
mail_log plain "Stopping Lidarr to prevent conflicts with music files..."
docker stop lidarr
mail_log check "Lidarr stop" $?

# Create a borg backup on the local drive
mail_log plain "Backing up music data locally..."
borg_backup "${MUSIC_DIR}" "${MUSIC_LOCAL_BACKUP_DIR}" "${MUSIC_BACKUP_KEEP_DAILY}" "${MUSIC_BACKUP_KEEP_WEEKLY}" "${MUSIC_BACKUP_KEEP_MONTHLY}" "${MUSIC_BORG_FLAGS[@]}"
mail_log check "Music local backup" $?

# Create a borg backup on the remote backup server
mail_log plain "Backing up music data on remote backup server..."
borg_backup "${MUSIC_DIR}" "${REMOTE_BACKUP_SERVER}:${MUSIC_REMOTE_BACKUP_DIR}" "${MUSIC_BACKUP_KEEP_DAILY}" "${MUSIC_BACKUP_KEEP_WEEKLY}" "${MUSIC_BACKUP_KEEP_MONTHLY}" "${MUSIC_BORG_FLAGS[@]}"
mail_log check "Music remote backup" $?

# Resume Lidarr
mail_log plain "Resuming Lidarr..."
docker start lidarr
mail_log check "Lidarr start" $?

# Make a backup of music videos on local and remote backup directories
mail_log plain "Backing up music video data locally..."
rsync -r --delete --update --progress "${MUSICVIDEOS_DIR}/" "${MUSICVIDEOS_LOCAL_BACKUP_DIR}"
mail_log check "Music video local backup" $?

mail_log plain "Backing up music video data on remote backup server..."
rsync -r --delete --update --progress "${MUSICVIDEOS_DIR}/" "${REMOTE_BACKUP_SERVER}:${MUSICVIDEOS_REMOTE_BACKUP_DIR}"
mail_log check "Music video remote backup" $?

backup_finish
