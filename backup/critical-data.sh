#!/bin/bash

# Set up environment
WORKING_DIR=$(dirname "$(realpath "$0")")
source "${WORKING_DIR}/.env"
source "${WORKING_DIR}/common.sh"

require var "${CRITICAL_DATA_LOCAL_BACKUP_DIR}" || exit 1
require var "${DATE}" || exit 1
require var "${WORKING_DIR}" || exit 1
require var "${REMOTE_BACKUP_SERVER}" || exit 1
require var "${CRITICAL_DATA_REMOTE_BACKUP_DIR}" || exit 1
require var "${FILES_DIR}" || exit 1
require var "${FILES_DIR}" || exit 1
require var "${SCRIPTS_DIR}" || exit 1
require var "${BW_PASS_FILE}" || exit 1
require file "${BW_PASS_FILE}" || exit 1

########################################
#      Backup Bitwarden database       #
########################################
bw_backup_dir="${CRITICAL_DATA_LOCAL_BACKUP_DIR}/bitwarden"
bw_backup_file="bw-backup-${DATE}.json"

# Login + save credentials (used by BW binary)
export BW_SESSION=$(bw unlock --raw --passwordfile "${BW_PASS_FILE}")

[ ! -d "${bw_backup_dir}" ] && mkdir -p "${bw_backup_dir}"
cd "${bw_backup_dir}"

# Backup to local drive
mail_log plain "Exporting Bitwarden contents to encrypted JSON..."
bw sync
bw export --raw --session "${BW_SESSION}" --format encrypted_json --password $(cat "${BW_PASS_FILE}") > "${bw_backup_dir}/${bw_backup_file}"
mail_log check "Bitwarden export" $?

# Prune BW backups, keep last 30 days
mail_log plain "Pruning Bitwarden backups to include last 30 days..."
find "${bw_backup_dir}" -type f -name "*.json" -mtime +30 -delete
mail_log check "Bitwarden prune" $?

# Deinitialize
unset BW_SESSION
bw lock

##############################################
#   Propagate to backup server + Nextcloud   #
##############################################
# Create a backup on the remote backup server
mail_log plain "Backing up all critical data to remote backup server..."
rsync -r --delete --update --progress "${CRITICAL_DATA_LOCAL_BACKUP_DIR}/" "${REMOTE_BACKUP_SERVER}:${CRITICAL_DATA_REMOTE_BACKUP_DIR}"
mail_log check "Sync to backup server" $?

# Backup /etc/backups/critical-data to Nextcloud
mail_log plain "Backing up all critical data to Nextcloud..."
rsync -r --delete --update --progress "${CRITICAL_DATA_LOCAL_BACKUP_DIR}/" "${FILES_DIR}/etc/backups/critical-data"
mail_log check "Nextcloud backup" $?
"${SCRIPTS_DIR}/system/server/nextcloud/nextcloud-scan-files.sh"

backup_finish
