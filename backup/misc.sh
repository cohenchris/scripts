#!/bin/bash

if [[ "$(id -u)" -ne 0 ]]; then
    echo "This script must be run as root" 
    exit 1
fi

# Set up environment
WORKING_DIR=$(dirname "$(realpath "$0")")
source ${WORKING_DIR}/.env

require MISC_LOCAL_BACKUP_DIR
require DATE
require WORKING_DIR
require REMOTE_BACKUP_SERVER
require MISC_REMOTE_BACKUP_DIR
require FILES_DIR
require FILES_DIR
require SCRIPTS_DIR

########################################
#      Backup Bitwarden database       #
########################################
bw_backup_dir="${MISC_LOCAL_BACKUP_DIR}/passwords/bw"
bw_backup_file="bw-backup-${DATE}.json"
bw_pass_file=${WORKING_DIR}/bwpass

# Login + save credentials (used by BW binary)
export BW_SESSION=$(bw unlock --raw --passwordfile ${bw_pass_file})

cd ${bw_backup_dir}

# Backup to local drive
bw sync
bw export --raw --session ${BW_SESSION} --format encrypted_json --password $(cat ${bw_pass_file}) > ${bw_backup_dir}/${bw_backup_file}
mail_log "bitwarden export" $?

# Prune BW backups, keep last 30 days
find ${bw_backup_dir} -type f -name "*.json" -mtime +30 -delete

# Deinitialize
unset BW_SESSION
bw lock

####################################################
#   Propagate misc backups to backup server + B2   #
####################################################
# 1. Create a backup on the remote backup server
rsync -r --delete --update --progress ${MISC_LOCAL_BACKUP_DIR}/ ${REMOTE_BACKUP_SERVER}:${MISC_REMOTE_BACKUP_DIR}

# 3. Backup /etc/backups/misc to Nextcloud
rsync -r --delete --update --progress ${MISC_LOCAL_BACKUP_DIR}/ ${FILES_DIR}/etc/backups/misc
mail_log "nextcloud backup" $?
${SCRIPTS_DIR}/scan-nextcloud-files.sh

finish
