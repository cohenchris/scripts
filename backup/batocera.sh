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

require var BATOCERA_HOST
require var BATOCERA_MAC
require var BATOCERA_DIR
require var BATOCERA_LOCAL_BACKUP_DIR
require var BATOCERA_REMOTE_BACKUP_DIR

# Attempt to wake batocera using Wake-On-LAN
wakeonlan ${BATOCERA_MAC}

# Check that batocera is up (this command will wait long enough for the device to boot)
ssh ${BATOCERA_HOST} "ls"
batocera_host_up=$?
mail_log check "batocera host up check" ${batocera_host_up}

if [[ "${batocera_host_up}" -eq 0 ]]; then
  # TODO: need to install a drive specifically for backups in this machine
  # Make a backup of batocera on local and remote backup directories
 
  #mail_log plain "Batocera Local Backup"
  #rsync -r --delete --update --progress ${BATOCERA_HOST}:${BATOCERA_DIR}/ ${BATOCERA_HOST}:${BATOCERA_LOCAL_BACKUP_DIR}
  #
  #mail_log check "batocera local backup" $?

  mail_log plain "Batocera Remote Backup"
  rsync -r --delete --update --progress ${BATOCERA_HOST}:${BATOCERA_DIR}/ ${BATOCERA_REMOTE_BACKUP_DIR}
  mail_log check "batocera remote backup" $?

  # Power console off
  ssh ${BATOCERA_HOST} "poweroff"
  mail_log check "batocera host shutdown" $?
fi

finish
