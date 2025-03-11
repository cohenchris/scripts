#!/bin/bash

# Set up environment
WORKING_DIR=$(dirname "$(realpath "$0")")
source ${WORKING_DIR}/.env

require var OPNSENSE_LOCAL_BACKUP_DIR
require var OPNSENSE_REMOTE_BACKUP_DIR
require var REMOTE_BACKUP_SERVER
require var DATE

# Backup OPNSense
BACKUP_NAME="opnsense-backup-${DATE}.tar.gz"
mkdir -p ${OPNSENSE_LOCAL_BACKUP_DIR}/opnsense
tar -czvf ${OPNSENSE_LOCAL_BACKUP_DIR}/opnsense/${BACKUP_NAME} /conf
scp ${OPNSENSE_LOCAL_BACKUP_DIR}/opnsense/${BACKUP_NAME} ${REMOTE_BACKUP_SERVER}:${OPNSENSE_REMOTE_BACKUP_DIR}/opnsense

# Backup AdGuard
BACKUP_NAME="AdGuardHome-${DATE}.yaml"
mkdir -p ${OPNSENSE_LOCAL_BACKUP_DIR}/adguard
cp /usr/local/AdGuardHome/AdGuardHome.yaml ${OPNSENSE_LOCAL_BACKUP_DIR}/adguard/${BACKUP_NAME}
scp ${OPNSENSE_LOCAL_BACKUP_DIR}/adguard/${BACKUP_NAME} ${REMOTE_BACKUP_SERVER}:${OPNSENSE_REMOTE_BACKUP_DIR}/adguard

finish nohanotify
