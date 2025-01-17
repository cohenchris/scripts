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
require BATOCERA_OPNSENSE_VLAN_INTERFACE
require BATOCERA_MAC
require OPNSENSE_URL
require OPNSENSE_WOL_API_USER
require OPNSENSE_WOL_API_KEY
require BATOCERA_DIR
require BATOCERA_LOCAL_BACKUP_DIR
require BATOCERA_REMOTE_BACKUP_DIR

# Attempt to wake batocera using OPNSense's WOL API
curl -s -k -H "Content-Type: application/json" \
     -d '{"wake":{"interface": "'${BATOCERA_OPNSENSE_VLAN_INTERFACE}'","mac": "'${BATOCERA_MAC}'"}}' \
     -u ${OPNSENSE_WOL_API_USER}:${OPNSENSE_WOL_API_KEY} \
     https://${OPNSENSE_URL}/api/wol/wol/set

# Wait for batocera to come up
sleep 30

# Check that batocera is up
ssh ${BATOCERA_HOST} "ls"
batocera_host_up=$?
mail_log check "batocera host up check" ${batocera_host_up}

# TODO: need to install a drive specifically for backups in this machine

if [[ "${batocera_host_up}" -eq 0 ]]; then
  # Make a backup of batocera on local and remote backup directories
 
  #mail_log plain "Batocera Local Backup"
  #rsync -r --delete --update --progress ${BATOCERA_HOST}:${BATOCERA_DIR}/ ${BATOCERA_HOST}:${BATOCERA_LOCAL_BACKUP_DIR}
  #
  #mail_log check "batocera local backup" $?

  mail_log plain "Batocera Remote Backup"
  rsync -r --delete --update --progress ${BATOCERA_HOST}:${BATOCERA_DIR}/ ${BATOCERA_REMOTE_BACKUP_DIR}
  mail_log check "batocera remote backup" $?
fi

# Power console off
ssh ${BATOCERA_HOST} "poweroff"
mail_log check "batocera host shutdown" $?

finish
