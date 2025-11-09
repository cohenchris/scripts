#!/usr/bin/env bash
# Backup important server files
# To restore: borg extract /backups/server::<backup_name>
#   note: execute this where you would like the 'server' folder to be placed

# Set up environment
WORKING_DIR=$(dirname "$(realpath "$0")")
source "${WORKING_DIR}/.env"
source "${WORKING_DIR}/common.sh"

require var "${SERVER_DIR}" || exit 1
require var "${SERVER_USER}" || exit 1
require var "${WORKING_DIR}" || exit 1
require var "${SERVER_LOCAL_BACKUP_DIR}" || exit 1
require var "${REMOTE_BACKUP_SERVER}" || exit 1
require var "${SERVER_REMOTE_BACKUP_DIR}" || exit 1
require var "${SERVER_BACKUP_KEEP_DAILY}" || exit 1
require var "${SERVER_BACKUP_KEEP_WEEKLY}" || exit 1
require var "${SERVER_BACKUP_KEEP_MONTHLY}" || exit 1

# Stop all Plex playback sessions with an informational message
mail_log plain "Stopping Plex to prevent conflicts with server files..."
"${SERVER_DIR}/media/scripts/plex-server-maintenance-broadcast.py"
mail_log check "Stop Plex" $?
sleep 15

# Shutdown server
mail_log plain "Stopping all Docker containers..."
cd "${SERVER_DIR}"
./stacks.sh stop all
mail_log check "Stop all Docker stacks" $?
# Export crontab
mail_log plain "Exporting crontab for ${SERVER_USER}..."
crontab -l -u "${SERVER_USER}" > crontab.txt
mail_log check "${SERVER_USER} crontab export" $?

mail_log plain "Exporting crontab for root user..."
crontab -l > sudo_crontab.txt
mail_log check "root crontab export" $?
cd "${WORKING_DIR}"

# Create a borg backup on the local drive
mail_log plain "Backing up server data locally..."
borg_backup "${SERVER_DIR}" "${SERVER_LOCAL_BACKUP_DIR}" "${SERVER_BACKUP_KEEP_DAILY}" "${SERVER_BACKUP_KEEP_WEEKLY}" "${SERVER_BACKUP_KEEP_MONTHLY}" "${SERVER_BORG_FLAGS[@]}"
mail_log check "Server local backup" $?

# Create a borg backup on the remote backup server
mail_log plain "Backing up server data to remote backup server..."
borg_backup "${SERVER_DIR}" "${REMOTE_BACKUP_SERVER}:${SERVER_REMOTE_BACKUP_DIR}" "${SERVER_BACKUP_KEEP_DAILY}" "${SERVER_BACKUP_KEEP_WEEKLY}" "${SERVER_BACKUP_KEEP_MONTHLY}" "${SERVER_BORG_FLAGS[@]}"
mail_log check "Server remote backup" $?

# Start services back up
mail_log plain "Starting all Docker containers..."
cd "${SERVER_DIR}"
rm crontab.txt sudo_crontab.txt
./stacks.sh start all
mail_log check "Start all Docker stacks" $?
cd "${WORKING_DIR}"

backup_finish
