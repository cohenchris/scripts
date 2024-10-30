#!/bin/bash
# Backup everything to Backblaze

if [[ "$(id -u)" -ne 0 ]]; then
    echo "This script must be run as root" 
    exit 1
fi

# Set up environment
WORKING_DIR=$(dirname "$(realpath "$0")")
source ${WORKING_DIR}/.env

require MAIN_BACKUPS_DIR
require OFFSITE_BACKBLAZE_BUCKET
require MAIN_BACKUP_EXCLUDE_REGEX

backblaze_sync ${MAIN_BACKUPS_DIR} ${OFFSITE_BACKBLAZE_BUCKET} ${MAIN_BACKUP_EXCLUDE_REGEX}

finish
