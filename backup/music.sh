#!/bin/bash
# Backup music
# To restore: borg extract /backups/music::<backup_name>
#   note: execute this where you would like the 'music' folder to be placed

# Source env file and prepare env vars
BACKUP_TYPE=$(basename $0 | cut -d "." -f 1)
source $(dirname "$0")/.env
DIRNAME=$(basename $MUSIC_BACKUP_DIR)
STATUS=SUCCESS

# Go to directory that we will backup
cd $MUSIC_DIR
cd ../

# Backup to local drive
export BORG_REPO=$MUSIC_BACKUP_DIR
backup_and_prune

# Backup to backup server
export BORG_REPO="$BACKUP_SERVER:$MUSIC_BACKUP_DIR"
backup_and_prune

finish

# Deinitialize
unset BORG_PASSPHRASE
