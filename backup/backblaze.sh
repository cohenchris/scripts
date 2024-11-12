#!/bin/bash
# Backup everything to Backblaze

# Set up environment
WORKING_DIR=$(dirname "$(realpath "$0")")
source ${WORKING_DIR}/.env

require MAIN_BACKUPS_DIR
require OFFSITE_BACKBLAZE_BUCKET
require MAIN_BACKUP_EXCLUDE_REGEX

# Sync backups directory to Backblaze
backblaze_sync ${MAIN_BACKUPS_DIR} ${OFFSITE_BACKBLAZE_BUCKET} ${MAIN_BACKUP_EXCLUDE_REGEX}

finish
