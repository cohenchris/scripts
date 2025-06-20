#!/bin/bash
# Backup important server files
# To restore: borg extract /backups/server::<backup_name>
#   note: execute this where you would like the 'server' folder to be placed

# Set up environment
WORKING_DIR=$(dirname "$(realpath "$0")")
source ${WORKING_DIR}/.env

require var SERVER_DIR
require var SERVER_USER
require var WORKING_DIR
require var SERVER_DIR
require var SERVER_LOCAL_BACKUP_DIR
require var REMOTE_BACKUP_SERVER
require var SERVER_REMOTE_BACKUP_DIR
require var PLEX_URL
require var PLEX_TOKEN

# Stop all Plex playback sessions with an informational message
mail_log plain "Stopping Plex to prevent conflicts with server files..."
${SCRIPTS_DIR}/system/server/plex-server-maintenance-broadcast.py ${PLEX_URL} ${PLEX_TOKEN}
mail_log check "Stop Plex" $?
sleep 30

# Shutdown server
mail_log plain "Stopping all Docker containers..."
cd ${SERVER_DIR}
docker-compose down
mail_log check "Docker-compose down" $?
# Export crontab
mail_log plain "Exporting crontab for ${SERVER_USER}..."
crontab -l -u ${SERVER_USER} > crontab.txt
mail_log check "${SERVER_USER} crontab export" $?

mail_log plain "Exporting crontab for root user..."
crontab -l > sudo_crontab.txt
mail_log check "root crontab export" $?
cd ${WORKING_DIR}

# Create a borg backup on the local drive
mail_log plain "Backing up server data locally..."
borg_backup "${SERVER_DIR}" "${SERVER_LOCAL_BACKUP_DIR}" "${SERVER_EXCLUDE_REGEX[@]}"
mail_log check "Server local backup" $?

# Create a borg backup on the remote backup server
mail_log plain "Backing up server data to remote backup server..."
borg_backup "${SERVER_DIR}" "${REMOTE_BACKUP_SERVER}:${SERVER_REMOTE_BACKUP_DIR}" "${SERVER_EXCLUDE_REGEX[@]}"
mail_log check "Server remote backup" $?

# Start services back up
mail_log plain "Restarting all Docker containers..."
cd ${SERVER_DIR}
rm crontab.txt sudo_crontab.txt
docker-compose up -d
mail_log check "Docker-compose up" $?
cd ${WORKING_DIR}

# Due to some Python permission issues, the container will take 15+ mins to
# start back up. The HomeAssistant notification script has a hard dependency
# on this, so we wait.
# https://github.com/linuxserver/docker-homeassistant/issues/116
sleep 15m

finish
