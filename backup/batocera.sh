#!/bin/bash
# Backup Batocera gaming console


# NOTE: Batocera is a firmware image and cannot be modified (no installing new packages).
# 	Therefore, the backup must be triggered by the backup server, rather than Batocera itself.
# 	This logic is reversed from all other backup scripts.
# 	The "local" backup backs up BATOCERA_DIR to BATOCERA_LOCAL_BACKUP_DIR on the Batocera host.
# 	The "remote" backup backs up BATOCERA_DIR to BATOCERA_REMOTE_BACKUP_DIR on the backup server (locally)>

# Set up environment
WORKING_DIR=$(dirname "$(realpath "$0")")
source ${WORKING_DIR}/.env

require BATOCERA_HOST
require BATOCERA_DIR
require BATOCERA_LOCAL_BACKUP_DIR
require BATOCERA_REMOTE_BACKUP_DIR

# TODO: need to install a drive specifically for backups in this machine

# Make a backup of batocera on local and remote backup directories
mail_log plain "Batocera Backup"
#rsync -r --delete --update --progress ${BATOCERA_HOST}:${BATOCERA_DIR}/ ${BATOCERA_HOST}:${BATOCERA_LOCAL_BACKUP_DIR}
#mail_log check "batocera local backup" $?
rsync -r --delete --update --progress ${BATOCERA_HOST}:${BATOCERA_DIR}/ ${BATOCERA_REMOTE_BACKUP_DIR}
mail_log check "batocera remote backup" $?

finish
