#!/bin/bash
# Backup Batocera gaming console


# NOTE: Batocera is a firmware image and cannot be modified (no installing new packages).
# 	Therefore, the backup must be triggered by the backup server, rather than Batocera itself.
# 	This logic is reversed from all other backup scripts.
# 	The "local" backup backs up BATOCERA_DIR to BATOCERA_LOCAL_BACKUP_DIR on the Batocera host.
# 	The "remote" backup backs up BATOCERA_DIR to BATOCERA_REMOTE_BACKUP_DIR on the backup server (locally)>

# Set up environment
WORKING_DIR=$(dirname "$(realpath "$0")")
source "${WORKING_DIR}/.env"

require var BATOCERA_HOST
require var BATOCERA_MAC
require var BATOCERA_LOCAL_BACKUP_DIR
require var BATOCERA_REMOTE_BACKUP_DIR

# Location of batocera directory to backup on batocera host
# No reason for this to be user-configurable - Batocera is an immutable distro, thus all installations
# will have data stored in the same place
BATOCERA_DIR="/userdata"
# By default, any downloaded Steam games will be included in this backup
# Takes up way too much space and is completely unnecessary, so exclude it
EXCLUDE_DOWNLOADED_STEAM_GAMES="saves/flatpak/data/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/"

# Attempt to wake batocera using Wake-On-LAN
wakeonlan "${BATOCERA_MAC}"

# Check that batocera is up (this command will wait long enough for the device to boot)
mail_log plain "Checking if Batocera host is up..."
ssh "${BATOCERA_HOST}" "ls"
mail_log check "Batocera host up check" $?

if [[ "${batocera_host_up}" -eq 0 ]]; then
  # Make a backup of batocera on local and remote backup directories
  mail_log plain "Backup up Batocera locally..."
  rsync -r \
        --delete \
        --update \
        --progress \
        --exclude "${EXCLUDE_DOWNLOADED_STEAM_GAMES}" \
        --delete-excluded \
        "${BATOCERA_HOST}:${BATOCERA_DIR}/" \
        "${BATOCERA_HOST}:${BATOCERA_LOCAL_BACKUP_DIR}"
  mail_log check "Batocera local backup" $?

  mail_log plain "Backing up Batocera to remote backup server..."
  rsync -r \
        --delete \
        --update \
        --progress \
        --exclude "${EXCLUDE_DOWNLOADED_STEAM_GAMES}" \
        --delete-excluded \
        "${BATOCERA_HOST}:${BATOCERA_DIR}/" \
        "${BATOCERA_REMOTE_BACKUP_DIR}"
  mail_log check "Batocera remote backup" $?

  # Power console off
  mail_log plain "Powering off Batocera..."
  ssh "${BATOCERA_HOST}" "poweroff"
  mail_log check "batocera host shutdown" $?
fi

finish
