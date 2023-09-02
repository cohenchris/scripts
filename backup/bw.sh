#!/bin/bash
# Backup bitwarden database

# Set up environment variables
BACKUP_TYPE=$(basename $0 | cut -d "." -f 1)
SCRIPT_DIRNAME=$(dirname $0)
source $SCRIPT_DIRNAME/.env
BACKUP_FILE=${BACKUP_NAME}.json
BW_PASS_FILE=$SCRIPT_DIRNAME/bwpass

# Login + save credentials
export BW_SESSION=$(bw unlock --raw --passwordfile ${BW_PASS_FILE})

cd $MISC_BACKUP_DIR

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
bw lock
