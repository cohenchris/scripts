#!/bin/bash

# Set up environment
WORKING_DIR=$(dirname "$(realpath "$0")")
source "${WORKING_DIR}/.env"

require var OPENWRT_LOCAL_BACKUP_DIR
require var OPENWRT_REMOTE_BACKUP_DIR
require var BACKUP_NAME
require var REMOTE_BACKUP_SERVER

# Backup
mail_log plain "Backing up OpenWRT data locally..."
sysupgrade -v -b "${OPENWRT_LOCAL_BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
mail_log check "Local OpenWRT backup" $?

# Copy to backup server
mail_log plain "Backing up OpenWRT data to remote backup server..."
scp "${OPENWRT_LOCAL_BACKUP_DIR}/${BACKUP_NAME}.tar.gz" "${REMOTE_BACKUP_SERVER}:${OPENWRT_REMOTE_BACKUP_DIR}"
mail_log check "Remote OpenWRT backup" $?

finish
