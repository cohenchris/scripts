#!/bin/bash
# Backup files
# To restore: borg extract $BORG_REPO::$BACKUP_NAME
#   note: execute this where you would like the 'files' folder to be placed

# Source env file and prepare env vars
BACKUP_TYPE=$(basename $0 | cut -d "." -f 1)
source $(dirname "$0")/env
BACKUP_DIR="./files/"
STATUS=SUCCESS

# Go to directory that we will backup
cd $FILES_BACKUP_DIR
cd ../

# Backup to local drive
export BORG_REPO="/backups/files"
echo "LOCAL BACKUP" >> $MAIL_FILE
backup_and_prune

# Backup to backup server
export BORG_REPO="pi@192.168.24.4:/backups/files"
echo "REMOTE BACKUP" >> $MAIL_FILE
backup_and_prune

# Backup to Backblaze B2
# b2 sync --delete --replaceNewer $BACKUP_DIR b2://cc-files-backup
b2 sync $BACKUP_DIR b2://cc-files-backup
mail_log $? "b2 backup"

finish
