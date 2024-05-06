#!/bin/bash
# Backup important server files
# To restore: borg extract /backups/server::<backup_name>
#   note: execute this where you would like the 'server' folder to be placed

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" 
    exit 1
fi

# Set up environment
source $(dirname "$0")/.env

# Shutdown server
cd ${SERVER_DIR_TO_BACKUP}
docker-compose down
# Export crontab
crontab -l -u ${CRON_BACKUP_USER} > crontab.txt
crontab -l > sudo_crontab.txt
cd ${WORKING_DIR}

# 1. Create a borg backup on the local drive
echo "Local Backup" >> ${MAIL_FILE}
borg_backup ${SERVER_DIR_TO_BACKUP} ${SERVER_LOCAL_BACKUP_DIR}

# 2. Create a borg backup on the remote backup server
echo "Remote Backup" >> ${MAIL_FILE}
borg_backup ${SERVER_DIR_TO_BACKUP} ${REMOTE_BACKUP_SERVER}:${SERVER_REMOTE_BACKUP_DIR}

# Start services back up
cd ${SERVER_DIR_TO_BACKUP}
rm crontab.txt sudo_crontab.txt
docker-compose up -d
cd ${WORKING_DIR}

# 3. Sync a copy of the backup to Backblaze B2
backblaze_sync ${SERVER_LOCAL_BACKUP_DIR} ${SERVER_BACKUP_BUCKET}

finish
