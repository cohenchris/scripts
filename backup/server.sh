#!/bin/bash
# Backup important server files
# To restore: borg extract /backups/server::<backup_name>
#   note: execute this where you would like the 'server' folder to be placed

# Set up environment variables
BACKUP_TYPE=$(basename $0 | cut -d "." -f 1)
source $(dirname "$0")/.env
BACKUP_DIRNAME=$(basename $SERVER_DIR)
SCRIPT_DIRNAME=$(dirname $0)
STATUS=SUCCESS

# Go to directory that we will backup
cd $SERVER_DIR
# Shutdown server
docker-compose down
# Export crontab
crontab -l -u $LOCAL_USER > crontab.txt
crontab -l > sudo_crontab.txt
cd ../

# Backup to local drive
export BORG_REPO=$SERVER_BACKUP_DIR
echo "LOCAL BACKUP" >> $MAIL_FILE
backup_and_prune

# Backup to backup server
export BORG_REPO="$BACKUP_SERVER:$SERVER_BACKUP_DIR"
echo "REMOTE BACKUP" >> $MAIL_FILE
backup_and_prune

# Upload to b2
cd $SERVER_BACKUP_DIR
/usr/local/bin/b2 sync --delete --replaceNewer . b2://$SERVER_BACKUP_BUCKET
mail_log $? "b2 backup"

# Remove crontab backup
cd $SERVER_DIR
rm crontab.txt sudo_crontab.txt

# Start server
docker-compose up -d

finish

# Deinitialize
unset BORG_PASSPHRASE
