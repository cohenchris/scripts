#!/bin/bash

# Set up environment variables
BACKUP_TYPE=$(basename $0 | cut -d "." -f 1)
SCRIPT_DIRNAME=$(dirname "$(realpath "$0")")
source $SCRIPT_DIRNAME/.env
STATUS=SUCCESS

current_date=$(date +%s)
two_weeks_ago=$(date -d '14 days ago' +%s)
eight_weeks_ago=$(date -d '8 weeks ago' +%s)
six_months_ago=$(date -d '6 months ago' +%s)

########################################
#      Backup Bitwarden database       #
########################################
BW_BACKUP_FILE=bw-backup-${DATE}.json
BW_PASS_FILE=$SCRIPT_DIRNAME/bwpass

# Login + save credentials
export BW_SESSION=$(bw unlock --raw --passwordfile ${BW_PASS_FILE})

cd $BW_BACKUP_DIR

# Backup to local drive
bw export --raw --session $BW_SESSION --format encrypted_json --password $(cat $BW_PASS_FILE) > ${BW_BACKUP_FILE}

# Prune BW backups, keep last 30 days
 find . -type f -name "*.json" -mtime +30 -delete

# Deinitialize
unset BW_SESSION
bw lock

####################################################
#   Propagate misc backups to backup server + B2   #
####################################################
cd $MISC_BACKUP_DIR

# Backup all misc files to backup server
rsync -r --delete --update . ${BACKUP_SERVER}:${MISC_BACKUP_DIR}

# Backup to Backblaze B2
bbb2 sync --delete --replace-newer . b2://$MISC_BACKUP_BUCKET

# Backup to Nextcloud /etc/backups/misc
rsync -r --delete --update . ${FILES_DIR}/etc/backups/misc
${SCRIPT_DIRNAME}/../scan-nextcloud-files.sh

finish
