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

# Go to directory that we will backup
cd ${SERVER_DIR_TO_BACKUP}
# Shutdown server
docker-compose down
# Export crontab
crontab -l -u ${CRON_BACKUP_USER} > crontab.txt
crontab -l > sudo_crontab.txt
cd ${WORKING_DIR}

# 1. Create a backup to local drive
borg_backup ${SERVER_DIR_TO_BACKUP} ${SERVER_LOCAL_BACKUP_DIR}

# Start services back up
cd ${SERVER_DIR_TO_BACKUP}
rm crontab.txt sudo_crontab.txt
docker-compose up -d
cd ${WORKING_DIR}

# 2. Rsync a copy of the backup to remote backup server
remote_sync ${SERVER_LOCAL_BACKUP_DIR} ${SERVER_REMOTE_BACKUP_DIR}

# 3. Sync a copy of the backup to Backblaze B2
backblaze_sync ${SERVER_LOCAL_BACKUP_DIR} ${SERVER_BACKUP_BUCKET}

finish
