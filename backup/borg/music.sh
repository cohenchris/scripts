#!/bin/bash
# Backup music
# To restore: borg extract $BORG_REPO::$BACKUP_NAME
#   note: execute this where you would like the 'music' folder to be placed

# Source env file
source $(dirname "$0")/env
BACKUP_NAME="music-"$BACKUP_NAME
BACKUP_DIR="./music/"
LOG_FILE="music-"$LOG_FILE

# redirect all output to LOG_FILE
touch $LOG_DIR/$LOG_FILE
exec 1>$LOG_DIR/$LOG_FILE
exec 2>&1

function backup_and_prune() {
  borg create --progress --stats ::$BACKUP_NAME $BACKUP_DIR
  borg prune --keep-daily 14 --keep-weekly 8 --keep-monthly 6 $BORG_REPO
}

# Go to directory that we will backup
cd $MUSIC_BACKUP_DIR
cd ../

# Backup to local drive
export BORG_REPO="/backups/music"
echo "LOCAL BACKUP" >> $MAIL_FILE
backup_and_prune

# Backup to backup server
export BORG_REPO="pi@192.168.24.4:/backups/music"
echo "REMOTE BACKUP" >> $MAIL_FILE
backup_and_prune

finish
