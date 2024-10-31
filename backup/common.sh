# require(var)
#   var - variable to check
#
# This function will throw an error if the provided variable is not set
function require() {
  local var="$1"

  if [[ -z "${!var}" ]]; then
    # Log variable name and calling function name
    echo -e "${RED}ERROR - ${var} is not set in ${FUNCNAME[1]:-env}${NC}"
    status=FAIL
    finish
  fi
}


# mail_log(event, code)
#   event - event to log for
#   code  - error code for the event
#
# Given an event, logs a positive or negative status code to the mail log file
function mail_log() {
  local event="$1"
  local code="$2"

  require event
  require code

  if [[ ${code} -gt 0 ]]; then
    # Failure
    echo "[✘]    ${event}" >> ${MAIL_FILE}
    STATUS=FAIL
  else
    # Success
    echo "[✔]    ${event}" >> ${MAIL_FILE}
  fi
}



# send_email(email, subject, body, logfile)
#   email   - destination email address
#   subject - subject of outgoing email address
#   body    - body of outgoing email address
#   logfile - path to log file which will be sent as an attachment
#
# Sends an email by polling until success
function send_email() {
  local email="$1"
  local subject="$2"
  local body="$3"
  local logfile="$4"
  local MAX_MAIL_ATTEMPTS=50

  require email
  require subject
  require body
  require logfile

  # Poll email send
  while ! mail -s "${subject}" -a ${logfile} ${email} < ${body}
  do
    echo -e "${RED}email failed, trying again...${NC}"

    # Limit attempts. If it goes infinitely, it could fill up the disk.
    MAX_MAIL_ATTEMPTS=$((MAX_MAIL_ATTEMPTS-1))
    if [[ ${MAX_MAIL_ATTEMPTS} -eq 0 ]]; then
      echo -e "${RED}send_email failed${NC}" >> ${MAIL_FILE}
      fail
    fi

    sleep 5
  done

  echo -e "${GREEN}email sent!${NC}"
}



# borg_backup(dir_to_backup, backup_dest_borg_repo)
#   dir_to_backup         - directory to backup with borg
#   backup_dest_borg_repo - borg repository to place backup into
#
# Creates a borg backup for the specified directory into the specified borg repository
function borg_backup() {
  local dir_to_backup="$1"
  local backup_dest_borg_repo="$2"

  # Environment variables that Borg requires to function
  # Location of the borg repository
  export BORG_REPO=${backup_dest_borg_repo}
  # Password with which we encrypt the borg backup archives
  export BORG_PASSPHRASE=$(cat ${WORKING_DIR}/gpgpass)

  require dir_to_backup
  require backup_dest_borg_repo
  require BORG_REPO
  require BORG_PASSPHRASE

  # Create archive
  if [[ ${BACKUP_TYPE} == "server" ]]; then
    borg create \
        --exclude="*/config/nextcloud/data/appdata*/preview" \
        --exclude="*/config/lidarr/MediaCover" \
        --exclude="*/config/plex/Library/Application Support/Plex Media Server/Metadata" \
        --exclude="*/config/plex/Library/Application Support/Plex Media Server/Cache" \
        --exclude="*/config/plex/Library/Application Support/Plex Media Server/Media" \
        --progress --stats ::${BACKUP_NAME} ${dir_to_backup}
  else
    borg create --progress --stats ::${BACKUP_NAME} ${dir_to_backup}
  fi

  mail_log "borg backup" $?

  # Prune archives
  # Archives to keep:
  #   --keep-daily 7      ->     all created within the past week
  #   --keep-weekly 4     ->     one from each of the 8 previous weeks
  #   --keep-monthly 6    ->     one from each of the 6 previous months
  borg prune --keep-daily 7 --keep-weekly 4 --keep-monthly 6

  mail_log "borg prune" $?
}



# backblaze_sync(dir_to_sync, backblaze_bucket)
#   dir_to_sync      - backup directory to sync to backblaze
#   backblaze_bucket - backblaze destination bucket
#
# Syncs a given directory to a given bucket on Backblaze
function backblaze_sync() {
  local dir_to_sync="$1"
  local backblaze_bucket="$2"
  local exclude_regex="$3"

  require dir_to_sync
  require backblaze_bucket
  require B2_BIN

  # Check B2 auth
  ${B2_BIN} get-bucket ${backblaze_bucket} > /dev/null 2>&1
  if [[ $? -gt 0 ]]; then
    echo -e "${RED}Backblaze not authorized${NC}" >> ${MAIL_FILE}
    fail
  fi

  # If exclude_regex was provided, prepend a pipe character to properly format the variable for b2 sync exclude regex
  [[ -n "${exclude_regex}" ]] && exclude_regex="|${exclude_regex}"

  # Sync directory to Backblaze
  # Handle user-specified excluded files/directories
  # Always prevent hidden files from being included
  cd ${dir_to_sync}
  ${B2_BIN} sync --delete --replaceNewer --excludeRegex "\..*${exclude_regex}" . b2://${backblaze_bucket}

  mail_log "backblaze backup" $?

  cd ${WORKING_DIR}
}



# finish()
#
# Logs, notifies me via HomeAssistant, emails me the backup status, and cleans up
function finish() {
  # Log and notify backup status
  if [[ ${STATUS} == "FAIL" ]]; then
    ${SCRIPTS_DIR}/ha-notify.sh "${BACKUP_TYPE^} Backup" "ERROR - ${BACKUP_NAME} backup failed..."
    echo -e "${RED}Backup failed...${NC}"
  else
    ${SCRIPTS_DIR}/ha-notify.sh "${BACKUP_TYPE^} Backup" "SUCCESS - ${BACKUP_NAME} backup succeeded!"
    echo -e "${GREEN}Backup succeeded!...${NC}"
  fi

 
  local subject="${STATUS} - ${BACKUP_TYPE} backup ${DATE}"
  send_email "${EMAIL}" "${subject}" "${MAIL_FILE}" "${LOG_DIR}/${LOG_FILE}"

  # Clean up
  rm ${MAIL_FILE}
  unset BORG_REPO
  unset BORG_PASSPHRASE
  unset LOG_DIR
  unset LOG_FILE
  unset MAIL_FILE

  # If failed, exit immediately
  [[ ${STATUS} == "FAIL" ]] && exit 1
}
