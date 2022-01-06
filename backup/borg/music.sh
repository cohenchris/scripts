#!/bin/bash
# Backup music
# To restore: borg extract $BORG_REPO::$BACKUP_NAME
#   note: execute this where you would like the 'music' folder to be placed

# Source env file and prepare env vars
BACKUP_TYPE=$(basename $0 | cut -d "." -f 1)
source $(dirname "$0")/env
DIRNAME=$(basename $MUSIC_BACKUP_DIR)

# Go to directory that we will backup
cd $MUSIC_DIR
cd ../

# Backup to local drive
export BORG_REPO=$MUSIC_BACKUP_DIR
echo "LOCAL BACKUP" >> $MAIL_FILE
backup_and_prune

# Backup to backup server
export BORG_REPO="$BACKUP_SERVER:$MUSIC_BACKUP_DIR"
export BORG_REPO="pi@192.168.24.4:/backups/music"
echo "REMOTE BACKUP" >> $MAIL_FILE
backup_and_prune

finish
