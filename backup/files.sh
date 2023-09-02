#!/bin/bash
# Backup files
# To restore: borg extract /backups/files::<backup_name>
#   note: execute this where you would like the 'files' folder to be placed

# Set up environment variables
BACKUP_TYPE=$(basename $0 | cut -d "." -f 1)
source $(dirname "$0")/.env
BACKUP_DIRNAME=$(basename $FILES_DIR)
SCRIPT_DIRNAME=$(dirname $0)
STATUS=SUCCESS

# Go to directory that we will backup
cd $FILES_DIR
cd ../

# Backup to local drive
export BORG_REPO=$FILES_BACKUP_DIR
echo "LOCAL BACKUP" >> $MAIL_FILE
backup_and_prune

# Backup to backup server
export BORG_REPO="$BACKUP_SERVER:$FILES_BACKUP_DIR"
echo "REMOTE BACKUP" >> $MAIL_FILE
backup_and_prune

# Backup to Backblaze B2
cd $FILES_BACKUP_DIR
/usr/local/bin/b2 sync --delete --replaceNewer . b2://$FILES_BACKUP_BUCKET
mail_log $? "b2 backup"

finish

# Deinitialize
unset BORG_PASSPHRASE
