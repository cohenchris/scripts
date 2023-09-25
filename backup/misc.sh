#!/bin/bash

# Set up environment variables
BACKUP_TYPE=$(basename $0 | cut -d "." -f 1)
SCRIPT_DIRNAME=$(dirname $0)
source $SCRIPT_DIRNAME/.env
STATUS=SUCCESS

########################################
#      Backup Bitwarden database       #
########################################
BW_BACKUP_FILE=bw-backup-${DATE}.json
BW_PASS_FILE=$SCRIPT_DIRNAME/bwpass

# Login + save credentials
export BW_SESSION=$(bw unlock --raw --passwordfile ${BW_PASS_FILE})

cd $PASSWORDS_BACKUP_DIR

# Backup to local drive
rm $PASSWORDS_BACKUP_DIR/bw*
bw export --raw --session $BW_SESSION --format encrypted_json --password $(echo $BW_PASS_FILE) > ${BW_BACKUP_FILE}

# Deinitialize
unset BW_SESSION
bw lock

####################################################
#   Propagate misc backups to backup server + B2   #
####################################################
cd $MISC_BACKUP_DIR

# Backup all misc files to backup server
rsync -r --delete . ${BACKUP_SERVER}:${MISC_BACKUP_DIR}

# Backup to Backblaze B2
/usr/local/bin/b2 sync --delete --replaceNewer . b2://$MISC_BACKUP_BUCKET

finish
