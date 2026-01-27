#!/usr/bin/env bash
# Backup everything to Backblaze


# validate_remote(rclone_remote)
#   rclone_remote - rclone remote config
#
# Validate that there exists an rclone remote config ${rclone_remote}
function validate_remote()
{
  local rclone_remote="$1"

  for remote in $(rclone listremotes); do
    # Check if the string is in the current remote name
    if [[ "${remote}" == "${rclone_remote}" ]]; then
      return 0
    fi
  done

  return 1
}


# backblaze_sync(rclone_remote, dir_to_sync, backblaze_bucket)
#   rclone_remote     - rclone remote config to backblaze
#   dir_to_sync       - backup directory to sync to backblaze
#   backblaze_bucket  - backblaze destination bucket
#
# Syncs a given directory to a given bucket on Backblaze
function backblaze_sync() {
  local backblaze_rclone_remote="$1"
  local dir_to_sync="$2"
  local backblaze_bucket="$3"

  require var "${backblaze_rclone_remote}" || exit 1
  require dir "${dir_to_sync}" || exit 1
  require var "${backblaze_bucket}" || exit 1

  # Validate that there exists an rclone remote config ${backblaze_rclone_remote}
  mail_log plain "Validating rclone remote config..."
  validate_remote "${backblaze_rclone_remote}"
  mail_log check "Validate rclone remote" $?

  # Validate that there exists a Backblaze B2 bucket (directory) ${remote_bucket} on rclone remote config ${backblaze_rclone_remote}
  mail_log plain "Validating Backblaze bucket..."
  rclone lsd ${backblaze_rclone_remote}${backblaze_bucket} > /dev/null 2>&1
  mail_log check "Validate Backblaze bucket" $?

  # Sync directory to Backblaze
  # Handle user-specified excluded directories
  # Always prevent hidden files from being included
  cd "${dir_to_sync}"
  mail_log plain "Syncing backup to Backblaze using rclone..."

  rclone_command=(
    rclone sync
    .
    ${backblaze_rclone_remote}${backblaze_bucket}
    --delete-excluded
    --progress
    --b2-hard-delete
    --exclude "/.*"
    --exclude "/.*/**"
  )

  # Add user-defined exclude regex
  for entry in "${BACKBLAZE_EXCLUDE_DIR_REGEX[@]}"; do
    rclone_command+=(--exclude "${entry}")
  done

  # Run the rclone command
  "${rclone_command[@]}"

  mail_log check "Backblaze backup via rclone" $?

  cd "${WORKING_DIR}"
}


# Set up environment
WORKING_DIR=$(dirname "$(realpath "$0")")
source "${WORKING_DIR}/.env"
source "${WORKING_DIR}/common.sh"

require var "${BACKBLAZE_RCLONE_REMOTE}" || exit 1
require var "${BACKBLAZE_BACKUPS_DIR}" || exit 1
require var "${BACKBLAZE_BUCKET}" || exit 1

# Sync backups directory to Backblaze
backblaze_sync "${BACKBLAZE_RCLONE_REMOTE}" "${BACKBLAZE_BACKUPS_DIR}" "${BACKBLAZE_BUCKET}"

backup_finish
