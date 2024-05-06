#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" 
    exit 1
fi

# Set up environment
source $(dirname "$0")/.env

########################################
#      Backup Bitwarden database       #
########################################
BW_BACKUP_DIR="${MISC_LOCAL_BACKUP_DIR}/passwords/bw"
BW_BACKUP_FILE="bw-backup-${DATE}.json"
BW_PASS_FILE=${WORKING_DIR}/bwpass

# Login + save credentials
export BW_SESSION=$(bw unlock --raw --passwordfile ${BW_PASS_FILE})

cd ${BW_BACKUP_DIR}

# Backup to local drive
bw sync
bw export --raw --session ${BW_SESSION} --format encrypted_json --password $(cat ${BW_PASS_FILE}) > ${BW_BACKUP_DIR}/${BW_BACKUP_FILE}
mail_log "bitwarden export" $?

# Prune BW backups, keep last 30 days
find ${BW_BACKUP_DIR} -type f -name "*.json" -mtime +30 -delete

# Deinitialize
unset BW_SESSION
bw lock

####################################################
#   Propagate misc backups to backup server + B2   #
####################################################
# 1. Backup all misc files to backup server
remote_sync ${MISC_LOCAL_BACKUP_DIR} ${MISC_REMOTE_BACKUP_DIR}

# 3. Sync a copy of the backup to Backblaze B2
backblaze_sync ${MISC_LOCAL_BACKUP_DIR} ${MISC_BACKUP_BUCKET}

# 3. Backup /etc/backups/misc to Nextcloud
rsync -r --progress --delete --update ${MISC_LOCAL_BACKUP_DIR} ${FILES_DIR_TO_BACKUP}/etc/backups/misc
mail_log "nextcloud backup" $?
${SCRIPTS_DIR}/scan-nextcloud-files.sh

finish
