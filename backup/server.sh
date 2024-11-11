#!/bin/bash
# Backup important server files
# To restore: borg extract /backups/server::<backup_name>
#   note: execute this where you would like the 'server' folder to be placed

# Set up environment
WORKING_DIR=$(dirname "$(realpath "$0")")
source ${WORKING_DIR}/.env

require SERVER_DIR
require SCRIPT_USER
require WORKING_DIR
require SERVER_DIR
require SERVER_LOCAL_BACKUP_DIR
require REMOTE_BACKUP_SERVER
require SERVER_REMOTE_BACKUP_DIR

# Shutdown server
cd ${SERVER_DIR}
docker-compose down
# Export crontab
crontab -l -u ${SCRIPT_USER} > crontab.txt
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
cd ${WORKING_DIR}

finish
