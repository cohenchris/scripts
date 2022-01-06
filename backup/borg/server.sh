#!/bin/bash
# Backup important server files
# To restore: borg extract $BORG_REPO::$BACKUP_NAME
#   note: execute this where you would like the 'phrog' folder to be placed (under /home/)

# Source env file
BACKUP_TYPE=$(basename $0 | cut -d "." -f 1)
source $(dirname "$0")/env
BACKUP_DIR="./$BACKUP_USER"
STATUS=SUCCESS

# Shutdown server
cd $SERVER_BACKUP_DIR/server
docker-compose down

# Go to directory that we will backup
cd $SERVER_BACKUP_DIR
# Export crontab
crontab -l -u $BACKUP_USER > crontab.txt
crontab -l > sudo_crontab.txt
cd ../

# Backup to local drive
export BORG_REPO="/backups/server"
backup_and_prune

# Backup to backup server
export BORG_REPO="pi@192.168.24.4:/backups/server"
backup_and_prune

# Upload to b2
#b2 sync --delete --replaceNewer $BACKUP_DIR b2://cc-server-backup
b2 sync $BACKUP_DIR b2://cc-server-backup

# Remove crontab backup
cd $BACKUP_DIR
echo "LOCAL BACKUP" >> $MAIL_FILE
rm crontab.txt sudo_crontab.txt

# Start server
cd /home/$BACKUP_USER/server
echo "REMOTE BACKUP" >> $MAIL_FILE
docker-compose up -d

finish
