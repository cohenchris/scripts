#!/usr/bin/env bash

# Set up environment
WORKING_DIR=$(dirname "$(realpath "$0")")
source "${WORKING_DIR}/.env"
source "${WORKING_DIR}/common.sh"

# Add my custom PATH to the user's environment
# This would usually be set in the environment itself (either cron or the user's profile).
# OPNSense takes control of crontab and we cannot set the correct PATH for cron.
# Therefore, we set it manually here.
export PATH="${PATH}:${WORKING_DIR}/../bin"

# FreeBSD installs bash at /usr/local/bin/bash by default
# My personal scripts use the interpreter /bin/bash
# To prevent bad interpreter errors, link /bin/bash to /usr/local/bin/bash
ln -s /usr/local/bin/bash /bin/bash

require var "${OPNSENSE_LOCAL_BACKUP_DIR}" || exit 1
require var "${OPNSENSE_REMOTE_BACKUP_DIR}" || exit 1
require var "${REMOTE_BACKUP_SERVER}" || exit 1
require var "${DATE}" || exit 1

# Backup OPNSense
mail_log plain "Backing up OPNSense data locally..."
BACKUP_NAME="opnsense-backup-${DATE}.tar.gz"
mkdir -p "${OPNSENSE_LOCAL_BACKUP_DIR}/opnsense"
tar -czvf "${OPNSENSE_LOCAL_BACKUP_DIR}/opnsense/${BACKUP_NAME}" /conf
mail_log check "Local OPNSense backup" $?

mail_log plain "Backing up OPNSense data to remote backup server..."
scp "${OPNSENSE_LOCAL_BACKUP_DIR}/opnsense/${BACKUP_NAME}" "${REMOTE_BACKUP_SERVER}:${OPNSENSE_REMOTE_BACKUP_DIR}/opnsense"
mail_log check "Remote OPNSense backup" $?

# Backup AdGuard
mail_log plain "Backing up AdGuard Home data locally..."
BACKUP_NAME="AdGuardHome-${DATE}.yaml"
mkdir -p "${OPNSENSE_LOCAL_BACKUP_DIR}/adguard"
cp /usr/local/AdGuardHome/AdGuardHome.yaml "${OPNSENSE_LOCAL_BACKUP_DIR}/adguard/${BACKUP_NAME}"
mail_log check "Local AdGuard Home backup" $?

mail_log plain "Backing up AdGuard Home data to remote backup server..."
scp "${OPNSENSE_LOCAL_BACKUP_DIR}/adguard/${BACKUP_NAME}" "${REMOTE_BACKUP_SERVER}:${OPNSENSE_REMOTE_BACKUP_DIR}/adguard"
mail_log check "Remote AdGuard Home backup" $?

backup_finish
