# require(type, thing)
#   type  - type of check (variable, file, or directory)
#   thing - thing which we will check the existence of
#
# if type == "var"    - interpret *thing* as a variable name, check that the variable is set in the environment
# if type == "file"   - interpret *thing* as a file path, check that the file exists
# if type == "dir"    - interpret *thing* as a directory path, check that the directory exists
function require() {
  local type="$1"
  local thing="$2"

  # Check that both arguments are provided
  if [[ -z "${type}" ]]; then
    echo -e "ERROR - 'type' argument not provided to function 'require()'."
    exit 1
  fi
  if [[ -z "${thing}" ]]; then
    echo -e "ERROR - 'thing' argument not provided to function 'require()'."
    exit 1
  fi

  if [[ "${type}" == "var" ]]; then
    # Check for the existence of a variable in the environment
    if [[ -z "${!thing}" ]]; then
      # Log variable thing and calling function name
      echo -e "ERROR - variable \"${thing}\" is not set - required by ${FUNCNAME[1]:-env}"
      status="FAIL"
      exit 1
    fi

  elif [[ "${type}" == "dir" ]]; then
    # Check for the existence of a directory
    if ! [[ -d "${thing}" ]]; then
      # Log variable thing and calling function name
      echo -e "ERROR - directory \"${thing}\" does not exist - required by ${FUNCNAME[1]:-env}"
      status="FAIL"
      exit 1
    fi

  elif [[ "${type}" == "file" ]]; then
    # Check for the existence of a file
    if ! [[ -f "${thing}" ]]; then
      # Log variable thing and calling function name
      echo -e "ERROR - file \"${thing}\" does not exist - required by ${FUNCNAME[1]:-env}"
      status="FAIL"
      exit 1

    # Check permissions on password files
    elif [[ "${thing}" == *"pass"* ]]; then

      # Check ownership
      if [[ $(stat -c "%U:%G" "${thing}") != "root:root" ]]; then
        echo "WARNING: Unsafe permissions are set on password file \"${thing}\"."
        echo "Recommended to run 'chown root:root ${thing}'"
      fi

      # Check permission bits
      if [[ $(stat -c "%a" "${thing}") -ne 400 ]]; then
        echo "WARNING: Unsafe permissions are set on password file \"${thing}\"."
        echo "Recommended to run 'chmod 400 ${thing}'"
      fi

    fi

  else
    # Invalid type provided
    echo "Invalid type passed to ${FUNCNAME[1]:-env} - \"${type}\""
  fi
}



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

  require var log_type
  require var message

  if [[ "${log_type}" == "check" ]]; then
    require var code

    if [[ "${code}" -gt 0 ]]; then
      # Failure
      echo -e "[✘]    ${message}" >> "${MAIL_FILE}"
      STATUS="FAIL"
      #exit 1
    else
      # Success
      echo -e "[✔]    ${message}" >> "${MAIL_FILE}"
    fi
  elif [[ "${log_type}" == "plain" ]]; then
    echo -e "${message}" >> "${MAIL_FILE}"
  else
    echo "ERROR: Invalid log_type provided to mail_log() - must be one of [check,plain]"
    status="FAIL"
    exit 1
  fi
}



# send_email(email, subject, body, attachment?)
#   email       - destination email address
#   subject     - subject of outgoing email address
#   body        - body of outgoing email address
#   attachment? - path to log file which will be sent as an attachment (optional)
#
# Sends an email by polling until success
function send_email() {
  local email="$1"
  local subject="$2"
  local body="$3"
  local attachment="$4"
  local max_mail_attempts=50

  require var email
  require var subject
  require var body

  # Handle optional attachment argument
  if [ -n "${attachment}" ]; then
    # attachment provided
    local MUTT_CMD="mutt -s \"${subject}\" -a ${attachment} -- ${email} < ${body}"
  else
    # attachment not provided
    local MUTT_CMD="mutt -s \"${subject}\" -- ${email} < ${body}"
  fi

  # Poll email send
  while ! eval "${MUTT_CMD}"; do
    echo -e "email failed, trying again..."

    # Limit attempts. If it goes infinitely, it could fill up the disk.
    max_mail_attempts=$((max_mail_attempts-1))
    if [[ "${max_mail_attempts}" -eq 0 ]]; then
      echo -e "send_email failed"
      status="FAIL"
      exit 1
    fi

    sleep 5
  done

  echo -e "email sent!"
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

  require var dir_to_backup
  require var dst_borg_repo
  require var keep_daily
  require var keep_weekly
  require var keep_monthly
  require var BORG_PASS_FILE
  require file "${BORG_PASS_FILE}"

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



# finish(subject?)
#   subject?  - optional subject override field
#
# Logs, notifies me via HomeAssistant, emails me the backup status, and cleans up
function finish() {
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

  send_email "${EMAIL}" "${subject}" "${MAIL_FILE}" "${LOG_FILE}"

  # Clean up
  rm "${MAIL_FILE}"
  unset BORG_REPO
  unset BORG_PASSPHRASE
  unset LOG_FILE
  unset MAIL_FILE

  # Exit with appropriate error code
  if [[ "${STATUS}" == "FAIL" ]]; then
    exit 1
  else
    exit 0
  fi
}
