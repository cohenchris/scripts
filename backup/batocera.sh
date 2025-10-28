#!/usr/bin/env bash
# Backup Batocera gaming console

# NOTE: Batocera is an immutable firmware image and cannot be modified (no installing new packages).
#       Therefore, the backup must be triggered by the backup server, rather than Batocera itself.
#       This logic is reversed from all other backup scripts.
#       The "local" backup backs up BATOCERA_DIR to BATOCERA_LOCAL_BACKUP_DIR on the Batocera host.
#       The "remote" backup backs up BATOCERA_DIR to BATOCERA_REMOTE_BACKUP_DIR on the backup server (locally)

# Set up environment
WORKING_DIR=$(dirname "$(realpath "$0")")
source "${WORKING_DIR}/.env"
source "${WORKING_DIR}/common.sh"

require var "${BATOCERA_HOST}" || exit 1
require var "${BATOCERA_MAC}" || exit 1
require var "${BATOCERA_LOCAL_BACKUP_DIR}" || exit 1
require var "${BATOCERA_REMOTE_BACKUP_DIR}" || exit 1


# Location of batocera directory to backup on batocera host
# No reason for this to be user-configurable - Batocera is an immutable distro, thus all installations
# will have data stored in the same place
BATOCERA_DIR="/userdata"
# By default, any downloaded Steam games will be included in this backup
# Takes up way too much space and is completely unnecessary, so exclude it
EXCLUDE_DOWNLOADED_STEAM_GAMES="saves/flatpak/data/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/"


# is_device_on(host)
#   host - check whether or not this host is on
#
# This function will check whether or not the host is on
# It will return '0' if the device is on, and '1' if the device is off
function is_device_on()
{
  local host="$1"
  require var "${host}" || exit 1

  ssh "${host}" "ls" &> /dev/null && echo 0 || echo 1
}


# Check if already powered on
mail_log plain "Checking power state of Batocera..."
POWER_STATE=$(is_device_on "${BATOCERA_HOST}")
INITIAL_POWER_STATE="${POWER_STATE}"

# If powered off, turn it on using Wake-On-LAN
if [[ "${POWER_STATE}" -ne 0 ]]; then
  mail_log plain "Device is powered off"

  # Attempt to wake batocera using Wake-On-LAN if not already powered on
  mail_log plain "Sending magic Wake-On-LAN packet..."
  wakeonlan "${BATOCERA_MAC}"
  mail_log check "WOL sent" $?

  # Check that batocera is up (this command will wait long enough for the device to boot)
  mail_log plain "Checking if host is up..."
  POWER_STATE=$(is_device_on "${BATOCERA_HOST}")
  mail_log check "Host is up?" "${POWER_STATE}"
else
  mail_log plain "Device is already on!"
fi


# If powered on, perform backups
if [[ "${POWER_STATE}" -eq 0 ]]; then
  # Make a backup of batocera on the local machine
  mail_log plain "Backup locally..."
  ssh -A "${BATOCERA_HOST}" \
  rsync -r \
        --delete \
        --update \
        --progress \
        --exclude "${EXCLUDE_DOWNLOADED_STEAM_GAMES}" \
        --delete-excluded \
        "${BATOCERA_DIR}/" \
        "${BATOCERA_LOCAL_BACKUP_DIR}"
  mail_log check "Local backup" $?

  # Make a backup of batocera on the remote backup server
  mail_log plain "Backing up to remote backup server..."
  rsync -r \
        --delete \
        --update \
        --progress \
        --exclude "${EXCLUDE_DOWNLOADED_STEAM_GAMES}" \
        --delete-excluded \
        "${BATOCERA_HOST}:${BATOCERA_DIR}/" \
        "${BATOCERA_REMOTE_BACKUP_DIR}"
  mail_log check "Remote backup" $?

  # Power console off if we found it that way
  if [[ "${INITIAL_POWER_STATE}" -ne 0 ]]; then
    mail_log plain "Powering off..."
    ssh "${BATOCERA_HOST}" "poweroff"
    mail_log check "Shut down" $?
  fi
else
  mail_log plain "ERROR: Magic Wake-On-LAN packet was unable to wake up batocera"
fi

backup_finish
