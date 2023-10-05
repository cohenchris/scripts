# Start mail file
echo -e "$BACKUP_TYPE backup $DATE\n\n" > $MAIL_FILE

##### FUNCTIONS #####
function mail_log() {
  code=$1
  message=$2

  if [ $code -gt 0 ]; then
    # Failure
    echo "[✘]    $message" >> $MAIL_FILE
    STATUS=FAIL
  else
    # Success
    echo "[✔]    $message" >> $MAIL_FILE
  fi
}

function poll_smtp() {
  email=$1
  subject=$2
  file=$3
  while ! mail -s "$subject" $email < $file
  do
    echo -e "${RED}email failed, trying again...${NC}"
    sleep 5
  done

  echo -e "${GREEN}email sent!${NC}"
}

function backup_and_prune() {
  if [ $BACKUP_TYPE == "server" ]; then
    borg create \
        --exclude="server/config/nextcloud/data/appdata*/preview" \
        --exclude="server/transcode" \
        --exclude="server/config/lidarr/MediaCover" \
        --exclude="server/config/plex/Library/Application Support/Plex Media Server/Metadata" \
        --exclude="server/config/plex/Library/Application Support/Plex Media Server/Cache" \
        --exclude="server/config/plex/Library/Application Support/Plex Media Server/Media" \
        --progress --stats ::$BACKUP_NAME $BACKUP_DIRNAME
    mail_log $? "borg backup"
  else
    borg create --progress --stats ::$BACKUP_NAME $BACKUP_DIRNAME
    mail_log $? "borg backup"
  fi

  # Archives to keep:
  #   --keep-within 14d   ->     all created within the past 2 weeks
  #   --keep-weekly 8     ->     one from each of the 8 previous weeks
  #   --keep-monthly 6    ->     one from each of the 6 previous months
  borg prune --keep-within 14d --keep-weekly 8 --keep-monthly 6 $BORG_REPO
  mail_log $? "borg prune"
}

function finish() {
  # Log status
  if [ $STATUS == "FAIL" ]; then
    python3 /home/phrog/scripts/ha-notify.py "${BACKUP_TYPE^} Backup" "ERROR - $BACKUP_NAME backup failed..."
    echo -e "${RED}Backup failed...${NC}"
  else
    echo -e "${GREEN}Backup succeeded!...${NC}"
  fi

  # Append log file to mail file
  echo -e "\n\n----- LOGS -----\n\n" >> $MAIL_FILE
  cat $LOG_DIR/$LOG_FILE >> $MAIL_FILE
    
  SUBJECT="$STATUS - $BACKUP_TYPE backup $DATE"
  poll_smtp $ADMIN_EMAIL "$SUBJECT" $MAIL_FILE

  # Send notification via home assistant
  if [ $STATUS == "FAIL" ]; then
    python3 /home/phrog/scripts/ha-notify.py "${BACKUP_TYPE^} Backup" "ERROR - $BACKUP_NAME backup failed..."
  else
    python3 /home/phrog/scripts/ha-notify.py "${BACKUP_TYPE^} Backup" "SUCCESS - $BACKUP_NAME backup succeeded!"
  fi

  rm $MAIL_FILE
}
