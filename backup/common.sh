# General settings
WORKING_DIR=$(dirname "$(realpath "$0")")
BACKUP_TYPE=$(basename $0 | cut -d "." -f 1)
SCRIPTS_DIR="${WORKING_DIR}"/..
DATE=$(date +"%Y%m%d-%H%M")
BACKUP_NAME="${BACKUP_TYPE}-backup-${DATE}"
STATUS="SUCCESS"

# Logging and mail
LOG_DIR="/var/log/backups"
LOG_FILE="${LOG_DIR}/${BACKUP_TYPE}-backup-${DATE}.log.txt"
MAIL_BODY_FILE="${LOG_DIR}/${BACKUP_TYPE}-backup-${DATE}-mail.log.txt"
mkdir -p "${LOG_DIR}"
touch "${LOG_FILE}"
touch "${MAIL_BODY_FILE}"
exec 1>"${LOG_FILE}"
exec 2>&1


# mail_log(log_type, message, code)
#   log_type  - whether to log as plaintext or checkmark
#   message   - message to log
#   code      - error code to check if log_type == "check" (optional)
#
# Given an event, logs a positive or negative status code to the mail log file
function mail_log() {
  local log_type="$1"
  local message="$2"
  local code="$3"

  require var "${log_type}" || exit 1
  require var "${message}" || exit 1

  if [[ "${log_type}" == "check" ]]; then
    require var "${code}" || exit 1

    if [[ "${code}" -gt 0 ]]; then
      # Failure
      echo -e "[✘]    ${message}" >> "${MAIL_BODY_FILE}"
      STATUS="FAIL"
    else
      # Success
      echo -e "[✔]    ${message}" >> "${MAIL_BODY_FILE}"
    fi
  elif [[ "${log_type}" == "plain" ]]; then
    echo -e "${message}" >> "${MAIL_BODY_FILE}"
  else
    echo "ERROR: Invalid log_type provided to mail_log() - must be one of [check,plain]"
    exit 1
  fi
}


# backup_finish()
#
# Finishing function specific to my backup logic.
# Logs, notifies me via HomeAssistant, emails me the backup status, and cleans up
function backup_finish() {
  local subject="$1"

  # Log and notify backup status
  if [[ "${STATUS}" == "FAIL" ]]; then
    bash "${SCRIPTS_DIR}/system/server/ha-notify.sh" "${BACKUP_TYPE} backup" "ERROR - ${BACKUP_TYPE} backup failed - ${DATE}..."
    echo -e "Backup failed..."
  else
    bash "${SCRIPTS_DIR}/system/server/ha-notify.sh" "${BACKUP_TYPE} backup" "SUCCESS - ${BACKUP_TYPE} backup succeeded - ${DATE}!"
    echo -e "Backup succeeded!"
  fi
 
  # If subject is not provided, construct one here
  if [[ -z "${subject}" ]]; then
    local subject="${STATUS} - ${BACKUP_TYPE} backup ${DATE}"
  fi

  echo -e "${MAIL_BODY_FILE}" | send_email "${EMAIL}" "${subject}" "${LOG_FILE}"

  # Clean up
  rm "${MAIL_BODY_FILE}"
  unset BORG_REPO
  unset BORG_PASSPHRASE
  unset LOG_FILE
  unset MAIL_BODY_FILE

  # Exit with appropriate error code
  if [[ "${STATUS}" == "FAIL" ]]; then
    exit 1
  else
    exit 0
  fi
}


# borg_backup(dir_to_backup, dst_borg_repo, borg_flags)
#   dir_to_backup     - directory to backup with borg
#   dst_borg_repo     - borg repository to backup into
#   keep_daily        - number of daily archives to keep
#   keep_weekly       - number of weekly archives to keep
#   keep_monthly      - number of monthly archives to keep
#   borg_flags?...    - additional flags to be used with borg create (optional)
#                       this is also a variadic argument, any number of borg_flags may be provided
#
# Creates a borg backup for the specified directory into the specified borg repository
function borg_backup() {
  local dir_to_backup="$1"
  local dst_borg_repo="$2"
  local keep_daily="$3"
  local keep_weekly="$4"
  local keep_monthly="$5"

  # Capture variadic argument borg_flags
  shift 5
  local borg_flags=("$@")

  require var "${dir_to_backup}" || exit 1
  require var "${dst_borg_repo}" || exit 1
  require var "${keep_daily}" || exit 1
  require var "${keep_weekly}" || exit 1
  require var "${keep_monthly}" || exit 1
  require var "${BORG_PASS_FILE}" || exit 1
  require file "${BORG_PASS_FILE}" || exit 1

  # Environment variables that Borg requires to function
  # Location of the borg repository
  export BORG_REPO="${dst_borg_repo}"
  # Password with which we encrypt the borg backup archives
  export BORG_PASSPHRASE=$(cat "${BORG_PASS_FILE}")

  # Create archive
  borg create "${borg_flags[@]}" --log-json --progress --stats "::${BACKUP_NAME}" "${dir_to_backup}"
  mail_log check "Borg backup" $?

  # Prune archives
  borg prune --log-json --keep-daily "${keep_daily}" --keep-weekly "${keep_weekly}" --keep-monthly "${keep_monthly}"

  mail_log check "Borg prune" $?
}
