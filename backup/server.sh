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
${SCRIPTS_DIR}/system/server/plex-server-maintenance-broadcast.py ${PLEX_URL} ${PLEX_TOKEN}
sleep 30

# Shutdown server
cd ${SERVER_DIR}
docker-compose down
mail_log check "docker-compose down" $?
# Export crontab
crontab -l -u ${SERVER_USER} > crontab.txt
crontab -l > sudo_crontab.txt
cd ${WORKING_DIR}

# Create a borg backup on the local drive
mail_log plain "Local Backup"
borg_backup ${SERVER_DIR} ${SERVER_LOCAL_BACKUP_DIR}

# Create a borg backup on the remote backup server
mail_log plain "Remote Backup"
borg_backup ${SERVER_DIR} ${REMOTE_BACKUP_SERVER}:${SERVER_REMOTE_BACKUP_DIR}

# Start services back up
cd ${SERVER_DIR}
rm crontab.txt sudo_crontab.txt
docker-compose up -d
mail_log check "docker-compose up" $?
cd ${WORKING_DIR}

finish
