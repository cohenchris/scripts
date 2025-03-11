# require(type, name)
#   type - type of check ("var" or "file")
#   name - name of variable or file to check
#
# This function will throw an error if the provided variable is not set
function require() {
  local type="$1"
  local name="$2"

  if [[ "${type}" == "var" ]]; then
    # Variable type - check if this exists in the env
    if [[ -z "${!name}" ]]; then
      # Log variable name and calling function name
      echo -e "ERROR - variable \"${name}\" is not set - required by ${FUNCNAME[1]:-env}"
      status=FAIL
      finish
    fi

  elif [[ "${type}" == "file" ]]; then
    # File type - check if this file path exists
    if ! [[ -f ${name} ]]; then
      # Log variable name and calling function name
      echo -e "ERROR - file \"${name}\" does not exist - required by ${FUNCNAME[1]:-env}"
      status=FAIL
      finish

    # Check permissions on password files
    elif [[ ${name} == *"pass"* ]]; then

      # Check ownership
      if [[ $(stat -c "%U:%G" "${name}") != "root:root" ]]; then
        echo "WARNING: Unsafe permissions are set on password file \"${name}\"."
        echo "Recommended to run 'chown root:root ${name}'"
      fi

      # Check permission bits
      if [[ $(stat -c "%a" "${name}") -ne 400 ]]; then
        echo "WARNING: Unsafe permissions are set on password file \"${name}\"."
        echo "Recommended to run 'chmod 400 ${name}'"
      fi

    fi

  else
    # Invalid type provided
    echo "Invalid type passed to ${FUNCNAME[1]:-env} - \"${type}\""
  fi

}


# mail_log(log_type, message, code)
#   log_type - whether to log as plaintext or checkmark
#   message - message to log
#   code  - OPTIONAL - error code to check if log_type == "check"
#
# Given an event, logs a positive or negative status code to the mail log file
function mail_log() {
  local log_type="$1"
  local message="$2"
  local code="$3"

  require var log_type
  require var message

  if [[ ${log_type} == "check" ]]; then
    require var code

    if [[ ${code} -gt 0 ]]; then
      # Failure
      echo -e "[✘]    ${message}" >> ${MAIL_FILE}
      STATUS=FAIL
    else
      # Success
      echo -e "[✔]    ${message}" >> ${MAIL_FILE}
    fi
  else
    echo -e "${message}" >> ${MAIL_FILE}
  fi
}



# send_email(email, subject, body, logfile)
#   email   - destination email address
#   subject - subject of outgoing email address
#   body    - body of outgoing email address
#   logfile - path to log file which will be sent as an attachment (optional)
#
# Sends an email by polling until success
function send_email() {
  local email="$1"
  local subject="$2"
  local body="$3"
  local logfile="$4"
  local max_mail_attempts=50

  require var email
  require var subject
  require var body

  # Handle optional logfile argument
  if [ -n "${logfile}" ]; then
    # logfile provided
    MUTT_CMD="mutt -s \"${subject}\" -a ${logfile} -- ${email} < ${body}"
  else
    # logfile not provided
    MUTT_CMD="mutt -s \"${subject}\" -- ${email} < ${body}"
  fi

  # Poll email send
  while ! eval "${MUTT_CMD}"; do
    echo -e "email failed, trying again..."

    # Limit attempts. If it goes infinitely, it could fill up the disk.
    max_mail_attempts=$((max_mail_attempts-1))
    if [[ ${max_mail_attempts} -eq 0 ]]; then
      echo -e "send_email failed"
      status=FAIL
    fi

    sleep 5
  done

  echo -e "email sent!"
}



# borg_backup(dir_to_backup, backup_dest_borg_repo)
#   dir_to_backup         - directory to backup with borg
#   backup_dest_borg_repo - borg repository to place backup into
#
# Creates a borg backup for the specified directory into the specified borg repository
function borg_backup() {
  local dir_to_backup="$1"
  local backup_dest_borg_repo="$2"

  require var dir_to_backup
  require var backup_dest_borg_repo
  require var BORG_PASS_FILE
  require file ${BORG_PASS_FILE}

  # Environment variables that Borg requires to function
  # Location of the borg repository
  export BORG_REPO=${backup_dest_borg_repo}
  # Password with which we encrypt the borg backup archives
  export BORG_PASSPHRASE=$(cat ${BORG_PASS_FILE})

  # Create archive
  if [[ ${BACKUP_TYPE} == "server" ]]; then
    borg create \
        --exclude="*/config/nextcloud/data/appdata*/preview" \
        --exclude="*/config/lidarr/MediaCover" \
        --exclude="*/config/plex/Library/Application Support/Plex Media Server/Metadata" \
        --exclude="*/config/plex/Library/Application Support/Plex Media Server/Cache" \
        --exclude="*/config/plex/Library/Application Support/Plex Media Server/Media" \
        --exclude="*/config/ai/ollama/models" \
        --exclude="*/cache" \
        --exclude="*/logs" \
        --log-json --progress --stats ::${BACKUP_NAME} ${dir_to_backup}
  else
    borg create --log-json --progress --stats ::${BACKUP_NAME} ${dir_to_backup}
  fi

  mail_log check "borg backup" $?

  # Prune archives
  # Archives to keep:
  #   --keep-daily 7      ->     all created within the past week
  #   --keep-weekly 4     ->     one from each of the 8 previous weeks
  #   --keep-monthly 6    ->     one from each of the 6 previous months
  borg prune --log-json --keep-daily 7 --keep-weekly 4 --keep-monthly 6

  mail_log check "borg prune" $?
}



# finish()
#
# Logs, notifies me via HomeAssistant, emails me the backup status, and cleans up
function finish() {
  local hanotify = ${1}

  # Log and notify backup status
  if [[ ${STATUS} == "FAIL" ]]; then
    [[ ${hanotify} != "nohanotify" ]] && ${SCRIPTS_DIR}/system/server/ha-notify.sh "${BACKUP_TYPE^} Backup" "ERROR - ${BACKUP_NAME} backup failed..."
    echo -e "Backup failed..."
  else
    [[ ${hanotify} != "nohanotify" ]] && ${SCRIPTS_DIR}/system/server/ha-notify.sh "${BACKUP_TYPE^} Backup" "SUCCESS - ${BACKUP_NAME} backup succeeded!"
    echo -e "Backup succeeded!..."
  fi
 
  local subject="${STATUS} - ${BACKUP_TYPE} backup ${DATE}"
  send_email "${EMAIL}" "${subject}" "${MAIL_FILE}" "${LOG_FILE}"

  # Clean up
  rm ${MAIL_FILE}
  unset BORG_REPO
  unset BORG_PASSPHRASE
  unset LOG_FILE
  unset MAIL_FILE

  # If failed, exit immediately
  [[ ${STATUS} == "FAIL" ]] && exit 1
}
