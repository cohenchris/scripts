#!/bin/bash
# Backup important server files
# To restore: borg extract /backups/server::<backup_name>
#   note: execute this where you would like the 'server' folder to be placed

if [[ "$(id -u)" -ne 0 ]]; then
    echo "This script must be run as root" 
    exit 1
fi

# Set up environment
WORKING_DIR=$(dirname "$(realpath "$0")")
source ${WORKING_DIR}/.env

require SERVER_DIR
require SCRIPT_USER
require WORKING_DIR
require MAIL_FILE
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

# 1. Create a borg backup on the local drive
echo "Local Backup" >> ${MAIL_FILE}
borg_backup ${SERVER_DIR} ${SERVER_LOCAL_BACKUP_DIR}

# 2. Create a borg backup on the remote backup server
echo "Remote Backup" >> ${MAIL_FILE}
borg_backup ${SERVER_DIR} ${REMOTE_BACKUP_SERVER}:${SERVER_REMOTE_BACKUP_DIR}

# Start services back up
cd ${SERVER_DIR}
rm crontab.txt sudo_crontab.txt
docker-compose up -d
cd ${WORKING_DIR}

finish
