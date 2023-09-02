# Set up logging
LOG_DIR="/var/log/backups"
LOG_FILE="$BACKUP_TYPE-backup-$DATE.log"
MAIL_FILE="$LOG_DIR/$BACKUP_TYPE-backup-mail.log"
mkdir -p $LOG_DIR
touch $LOG_DIR/$LOG_FILE
exec 1>$LOG_DIR/$LOG_FILE
exec 2>&1

# Colors
GREEN="\e[32m"
RED="\e[31m"
NC="\e[0m"

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
        --progress --stats ::$BACKUP_NAME $DIRNAME
    mail_log $? "borg backup"
  else
    borg create --progress --stats ::$BACKUP_NAME $DIRNAME
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
    echo -e "${RED}Files backup failed...${NC}"
  else
    echo -e "${GREEN}Files backup succeeded!...${NC}"
  fi

  if ! [ $BACKUP_TYPE == "music" ]; then
    # Append log file to mail file
    echo -e "\n\n----- LOGS -----\n\n" >> $MAIL_FILE
    cat $LOG_DIR/$LOG_FILE >> $MAIL_FILE
    
    SUBJECT="$STATUS - $BACKUP_TYPE backup $DATE"
    poll_smtp $ADMIN_EMAIL "$SUBJECT" $MAIL_FILE
  fi 

  rm $MAIL_FILE
}
