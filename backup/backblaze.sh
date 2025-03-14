#!/bin/bash
# Backup everything to Backblaze

# backblaze_sync(dir_to_sync, backblaze_bucket, exclude_regex)
#   dir_to_sync      - backup directory to sync to backblaze
#   backblaze_bucket - backblaze destination bucket
#   exclude_regex    - regex for files/directories to exclude in the backblaze backup
#
# Syncs a given directory to a given bucket on Backblaze
function backblaze_sync() {
  local dir_to_sync="$1"
  local backblaze_bucket="$2"
  local exclude_regex="$3"

  require var dir_to_sync
  require var backblaze_bucket
  require var B2_BIN

  # Check B2 auth
  ${B2_BIN} get-bucket ${backblaze_bucket} > /dev/null 2>&1
  if [[ $? -gt 0 ]]; then
    mail_log plain "Backblaze not authorized"
    STATUS=FAIL
    finish
  fi

  # If exclude_regex was provided, prepend a pipe character to properly format the variable for b2 sync exclude regex
  [[ -n "${exclude_regex}" ]] && exclude_regex="|${exclude_regex}"

  # Sync directory to Backblaze
  # Handle user-specified excluded files/directories
  # Always prevent hidden files from being included
  cd ${dir_to_sync}
  ${B2_BIN} sync --delete --replaceNewer --excludeRegex "\..*${exclude_regex}" . b2://${backblaze_bucket}
  mail_log check "backblaze backup" $?

  cd ${WORKING_DIR}
}


# Set up environment
WORKING_DIR=$(dirname "$(realpath "$0")")
source ${WORKING_DIR}/.env

require var MAIN_BACKUPS_DIR
require var OFFSITE_BACKBLAZE_BUCKET
require var MAIN_BACKUPS_EXCLUDE_REGEX

# Sync backups directory to Backblaze
backblaze_sync ${MAIN_BACKUPS_DIR} ${OFFSITE_BACKBLAZE_BUCKET} ${MAIN_BACKUPS_EXCLUDE_REGEX}

finish
