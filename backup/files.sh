#!/usr/bin/env bash
# Backup files
# To restore: borg extract /backups/files::<backup_name>
#   note: execute this where you would like the 'files' folder to be placed

# Set up environment
WORKING_DIR=$(dirname "$(realpath "$0")")
source "${WORKING_DIR}/.env"
source "${WORKING_DIR}/common.sh"

require var "${FILES_DIR}" || exit 1
require var "${FILES_LOCAL_BACKUP_DIR}" || exit 1
require var "${REMOTE_BACKUP_SERVER}" || exit 1
require var "${FILES_REMOTE_BACKUP_DIR}" || exit 1
require var "${FILES_BACKUP_KEEP_DAILY}" || exit 1
require var "${FILES_BACKUP_KEEP_WEEKLY}" || exit 1
require var "${FILES_BACKUP_KEEP_MONTHLY}" || exit 1

# Put Nextcloud in maintenance mode to prevent file changes
mail_log plain "Enabling Nextcloud maintenance mode..."
docker exec -u www-data nextcloud php occ maintenance:mode --on
mail_log check "nextcloud maintenance on" $?

# Create a borg backup on the local drive
mail_log plain "Backing up Nextcloud data locally..."
borg_backup "${FILES_DIR}" "${FILES_LOCAL_BACKUP_DIR}" "${FILES_BACKUP_KEEP_DAILY}" "${FILES_BACKUP_KEEP_WEEKLY}" "${FILES_BACKUP_KEEP_MONTHLY}" "${FILES_BORG_FLAGS[@]}"
mail_log check "Local Nextcloud backup" $?

# Create a borg backup on the remote backup server
mail_log plain "Backing up Nextcloud data on remote backup server..."
borg_backup "${FILES_DIR}" "${REMOTE_BACKUP_SERVER}:${FILES_REMOTE_BACKUP_DIR}" "${FILES_BACKUP_KEEP_DAILY}" "${FILES_BACKUP_KEEP_WEEKLY}" "${FILES_BACKUP_KEEP_MONTHLY}" "${FILES_BORG_FLAGS[@]}"
mail_log check "Remote Nextcloud backup..." $?

# Take Nextcloud out of maintenance mode
mail_log plain "Disabling Nextcloud maintenance mode..."
docker exec -u www-data nextcloud php occ maintenance:mode --off
mail_log check "Nextcloud maintenance off" $?

backup_finish
