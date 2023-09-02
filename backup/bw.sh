#!/bin/bash
# Backup bitwarden database

# Set up environment variables
BACKUP_TYPE=$(basename $0 | cut -d "." -f 1)
DIRNAME=$(dirname "$0")
source $DIRNAME/.env
BACKUP_FILE=${BACKUP_NAME}.json
BW_PASS_FILE=$DIRNAME/bwpass

cd $MISC_BACKUP_DIR

# Login + save credentials
export BW_SESSION=$(bw unlock --raw --passwordfile $BW_PASS_FILE)

# Backup to local drive
rm $MISC_BACKUP_DIR/bw*
bw export --raw --session $BW_SESSION --format encrypted_json --password $(echo $BW_PASS_FILE) > ${BACKUP_FILE}

# Backup to backup server
ssh $BACKUP_SERVER "rm $MISC_BACKUP_DIR/bw*"
rsync -r ./${BACKUP_FILE} ${BACKUP_SERVER}:${MISC_BACKUP_DIR}

# Backup to Backblaze B2
/usr/local/bin/b2 sync --delete --replaceNewer . b2://$MISC_BACKUP_BUCKET

# Deinitialize
unset BW_SESSION
bw logout
