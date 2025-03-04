#!/bin/bash

# Set up environment
WORKING_DIR=$(dirname "$(realpath "$0")")
source ${WORKING_DIR}/.env

require var OPENWRT_LOCAL_BACKUP_DIR
require var OPENWRT_REMOTE_BACKUP_DIR
require var BACKUP_NAME
require var REMOTE_BACKUP_SERVER

# Backup
sysupgrade -v -b ${OPENWRT_LOCAL_BACKUP_DIR}/${BACKUP_NAME}.tar.gz

# Copy to backup server
scp ${OPENWRT_LOCAL_BACKUP_DIR}/${BACKUP_NAME}.tar.gz ${REMOTE_BACKUP_SERVER}:${OPENWRT_REMOTE_BACKUP_DIR}

finish
