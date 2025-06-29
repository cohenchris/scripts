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
  require var BACKBLAZE_BIN

  # Check B2 auth
  mail_log plain "Checking Backblaze authorization for bucket ${backblaze_bucket}..."
  "${BACKBLAZE_BIN}" get-bucket "${backblaze_bucket}" > /dev/null 2>&1
  mail_log check "Backblaze authorization" $?

  # Sync directory to Backblaze
  # Handle user-specified excluded files/directories
  # Always prevent hidden files from being included
  cd "${dir_to_sync}"
  mail_log plain "Syncing backup to Backblaze..."
  "${BACKBLAZE_BIN}" sync --delete --replaceNewer "${exclude_regex}" . b2://${backblaze_bucket}
  mail_log check "Backblaze backup" $?

  cd "${WORKING_DIR}"
}


# Set up environment
WORKING_DIR=$(dirname "$(realpath "$0")")
source "${WORKING_DIR}/.env"

require var BACKBLAZE_BACKUPS_DIR
require var BACKBLAZE_BUCKET

# Construct the exclusion regex string
# Should be in the format "\..*|somedir|anotherdir|somefile|anotherfile"
if [[ -n "${BACKBLAZE_EXCLUDE_REGEX}" ]]; then
  exclude_regex="--excludeRegex \..*"

  for entry in "${BACKBLAZE_EXCLUDE_REGEX[@]}"; do
    exclude_regex="${exclude_regex}|${entry}"
  done
fi

# Sync backups directory to Backblaze
backblaze_sync "${BACKBLAZE_BACKUPS_DIR}" "${BACKBLAZE_BUCKET}" "${exclude_regex}"

finish
