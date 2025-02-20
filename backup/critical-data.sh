#!/bin/bash

# Set up environment
WORKING_DIR=$(dirname "$(realpath "$0")")
source ${WORKING_DIR}/.env

require CRITICAL_DATA_LOCAL_BACKUP_DIR
require DATE
require WORKING_DIR
require REMOTE_BACKUP_SERVER
require CRITICAL_DATA_REMOTE_BACKUP_DIR
require FILES_DIR
require FILES_DIR
require SCRIPTS_DIR

########################################
#      Backup Bitwarden database       #
########################################
bw_backup_dir="${CRITICAL_DATA_LOCAL_BACKUP_DIR}/passwords/bw"
bw_backup_file="bw-backup-${DATE}.json"
bw_pass_file="${WORKING_DIR}/bwpass"

# Login + save credentials (used by BW binary)
export BW_SESSION=$(bw unlock --raw --passwordfile ${bw_pass_file})

cd ${bw_backup_dir}

# Backup to local drive
bw sync
bw export --raw --session ${BW_SESSION} --format encrypted_json --password $(cat ${bw_pass_file}) > ${bw_backup_dir}/${bw_backup_file}
mail_log check "bitwarden export" $?

# Prune BW backups, keep last 30 days
find ${bw_backup_dir} -type f -name "*.json" -mtime +30 -delete
mail_log check "bitwarden prune" $?

# Deinitialize
unset BW_SESSION
bw lock

##############################################
#   Propagate to backup server + Nextcloud   #
##############################################
# Create a backup on the remote backup server
rsync -r --delete --update --progress ${CRITICAL_DATA_LOCAL_BACKUP_DIR}/ ${REMOTE_BACKUP_SERVER}:${CRITICAL_DATA_REMOTE_BACKUP_DIR}
mail_log check "sync to backup server" $?

# Backup /etc/backups/critical-data to Nextcloud
rsync -r --delete --update --progress ${CRITICAL_DATA_LOCAL_BACKUP_DIR}/ ${FILES_DIR}/etc/backups/critical-data
mail_log check "nextcloud backup" $?
${SCRIPTS_DIR}/server/nextcloud/scan-nextcloud-files.sh

finish
