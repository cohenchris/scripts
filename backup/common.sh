# Start mail file
echo "---------- TASKS ----------" > ${MAIL_FILE}



# mail_log(event, code)
#   event - event to log for
#   code  - error code for the event
#
# Given an event, logs a positive or negative status code to the mail log file
function mail_log() {
  event=$1
  code=$2

  # Sanity check
  if [[ -z "${event}" || -z "${code}" ]]; then
    echo -e "${RED}mail_log - invalid arguments${NC}" >> ${MAIL_FILE}
    STATUS=FAIL
    return
  fi

  if [ ${code} -gt 0 ]; then
    # Failure
    echo "[✘]    ${event}" >> ${MAIL_FILE}
    STATUS=FAIL
  else
    # Success
    echo "[✔]    ${event}" >> ${MAIL_FILE}
  fi
}



# send_email(email, subject, body)
#   email   - destination email address
#   subject - subject of outgoing email address
#   body    - body of outgoing email address
#
# Sends an email by polling until success
function send_email() {
  email=$1
  subject=$2
  body=$3

  # Sanity check
  if [[ -z "${MAX_MAIL_ATTEMPTS}" || -z "${email}" || -z "${subject}" || -z "${body}" ]]; then
    echo -e "${RED}send_email - invalid arguments${NC}" >> ${MAIL_FILE}
    STATUS=FAIL
    return
  fi

  # Poll email send
  while ! mail -s "${subject}" ${email} < ${body}
  do
    echo -e "${RED}email failed, trying again...${NC}"

    # Limit attempts. If it goes infinitely, it could fill up the disk.
    MAX_MAIL_ATTEMPTS=$((MAX_MAIL_ATTEMPTS-1))
    if [ ${MAX_MAIL_ATTEMPTS} -eq 0 ]; then
      echo -e "${RED}send_email failed,${NC}" >> ${MAIL_LOG}
      STATUS=FAIL
      return
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
  dir_to_backup=$1
  backup_dest_borg_repo=$2

  # Sanity check
  if [[ -z "${BACKUP_TYPE}" || -z "${BACKUP_NAME}" || -z "${dir_to_backup}" || -z "${backup_dest_borg_repo}" ]]; then
    echo -e "${RED}borg_backup - invalid arguments${NC}" >> ${MAIL_FILE}
    STATUS=FAIL
    return
  fi

  # Borg requires this to function
  export BORG_REPO=${backup_dest_borg_repo}

  # Create archive
  if [ ${BACKUP_TYPE} == "server" ]; then
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
  #   --keep-within 14d   ->     all created within the past 2 weeks
  #   --keep-weekly 8     ->     one from each of the 8 previous weeks
  #   --keep-monthly 6    ->     one from each of the 6 previous months
  borg prune --keep-within 14d --keep-weekly 8 --keep-monthly 6
  mail_log "borg prune" $?
}



# backblaze_sync(dir_to_sync, backblaze_bucket)
#   dir_to_sync      - backup directory to sync to backblaze
#   backblaze_bucket - backblaze destination bucket
#
# Syncs a given directory to a given bucket on Backblaze
function backblaze_sync() {
  dir_to_sync=$1
  backblaze_bucket=$2

  # Sanity check
  if [[ -z "${dir_to_sync}" || -z "${backblaze_bucket}" ]]; then
    echo -e "${RED}backblaze_sync - invalid arguments${NC}" >> ${MAIL_FILE}
    STATUS=FAIL
    return
  fi

  # Check B2 auth
  bbb2 list-buckets > /dev/null 2>&1
  if [ $? -gt 0 ]; then
    echo -e "${RED}backblaze_sync - not authorized${NC}" >> ${MAIL_FILE}
    STATUS=FAIL
    return
  fi

  cd ${dir_to_sync}
  bbb2 sync --delete --replace-newer . b2://${backblaze_bucket}
  mail_log "backblaze backup" $?
  cd ${WORKING_DIR}
}



# remote_sync(dir_to_sync, backup_dest)
#   dir_to_sync - backup directory to sync to remote
#   backup_dest - destination to sync backup
#
# Syncs a given directory to a given destination on the remote backup server
function remote_sync() {
  dir_to_sync=$1
  backup_dest=$2

  # Sanity check
  if [[ -z "${dir_to_sync}" || -z "${backup_dest}" ]]; then
    echo -e "${RED}remote_sync - invalid arguments${NC}" >> ${MAIL_FILE}
    STATUS=FAIL
    return
  fi

  # Sync to remote backup server
  cd ${dir_to_sync}
  #rsync -r --progress --delete --update . $REMOTE_BACKUP_SERVER:${backup_dest}
  mail_log "remote backup" $?
  cd ${WORKING_DIR}
}



# finish()
#
# Logs, notifies me via HomeAssistant, emails me the backup status, and cleans up
function finish() {
  # Log and notify backup status
  if [ ${STATUS} == "FAIL" ]; then
    python3 ${SCRIPTS_DIR}/ha-notify.py "${BACKUP_TYPE^} Backup" "ERROR - ${BACKUP_NAME} backup failed..."
    echo -e "${RED}Backup failed...${NC}"
  else
    python3 ${SCRIPTS_DIR}/ha-notify.py "${BACKUP_TYPE^} Backup" "SUCCESS - ${BACKUP_NAME} backup succeeded!"
    echo -e "${GREEN}Backup succeeded!...${NC}"
  fi

  # Email backup status
  echo -e "\n\n---------- LOGS ----------\n\n" >> ${MAIL_FILE}
  cat ${LOG_DIR}/${LOG_FILE} >> ${MAIL_FILE}
 
  subject="${STATUS} - ${BACKUP_TYPE} backup ${DATE}"
  send_email ${ADMIN_EMAIL} "${subject}" ${MAIL_FILE}

  # Clean up
  rm ${MAIL_FILE}
  unset BORG_REPO
  unset BORG_PASSPHRASE
  unset LOG_DIR
  unset LOG_FILE
  unset MAIL_FILE
}
