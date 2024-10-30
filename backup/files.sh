#!/bin/bash
# Backup files
# To restore: borg extract /backups/files::<backup_name>
#   note: execute this where you would like the 'files' folder to be placed

if [[ "$(id -u)" -ne 0 ]]; then
    echo "This script must be run as root" 
    exit 1
fi

# Set up environment
WORKING_DIR=$(dirname "$(realpath "$0")")
source ${WORKING_DIR}/.env

require MAIL_FILE
require FILES_DIR
require FILES_LOCAL_BACKUP_DIR
require REMOTE_BACKUP_SERVER
require FILES_REMOTE_BACKUP_DIR

# Put Nextcloud in maintenance mode to prevent file changes
docker exec -it -u www-data nextcloud php occ maintenance:mode --on

# 1. Create a borg backup on the local drive
echo "Local Backup" >> ${MAIL_FILE}
borg_backup ${FILES_DIR} ${FILES_LOCAL_BACKUP_DIR}

# 2. Create a borg backup on the remote backup server
echo "Remote Backup" >> ${MAIL_FILE}
borg_backup ${FILES_DIR} ${REMOTE_BACKUP_SERVER}:${FILES_REMOTE_BACKUP_DIR}

# Take Nextcloud out of maintenance mode
docker exec -it -u www-data nextcloud php occ maintenance:mode --off

finish
