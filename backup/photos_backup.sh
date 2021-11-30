#!/bin/bash

BACKUP_SCRIPTS_DIR=$(dirname "$0")
cd $BACKUP_SCRIPTS_DIR
source ./env

# redirect all output to LOG_FILE
LOG_FILE="photos-backup-$DATE.log"
cd $PHOTOS_BACKUP_LOG_DIR
touch $LOG_FILE
exec 1>$LOG_FILE
exec 2>&1

STATUS=SUCCESS


##### Backup to this computer's HDD #####
function backup_local() {
  echo -e "${GREEN}Backing up photos to local HDD...${NC}"
  
  cd $PHOTOS_DIR

  # backup
  rsync -arP --delete . $PHOTOS_BACKUP_DIR

  # Log event to mail.log
  mail_log $? "backup to local HDD"
}


##### Backup to mediaserver's HDD #####
function backup_to_mediaserver() {
  echo -e "${GREEN}Backing up photos to mediaserver HDD...${NC}"

  cd $PHOTOS_BACKUP_DIR

  # backup
  rsync -arP --delete . phrog@192.168.24.3:/backups/photos

  # Log event to mail.log
  mail_log $? "backup to mediaserver HDD"
}


##### Backup photos to B2 bucket #####
function backup_photos_to_b2() {
	# Begin Backup
	echo -e "$(date) : ${GREEN}Start photos backup to $BBPHOTOSBUCKET${NC}"
  cd $PHOTOS_DIR

	# Upload
	echo -e "$(date) : ${GREEN}Uploading...${NC}"
  /usr/local/bin/b2 sync --keepDays 30 . b2://$BBPHOTOSBUCKET

  # Log event to mail log
  mail_log $? "b2 photos backup"
	echo -e "$(date) : ${GREEN}Uploaded photos to $BBPHOTOSBUCKET${NC}"
}


# Logs to 'mail.log' file
# first argument is the return code to evaluate
# second argument is the event-specific message to print
function mail_log() {
  code=$1
  message=$2

  if [ $code -gt 0 ]; then
    # Failure
    echo "[✘]    $message" >> $PHOTOS_MAIL_FILE
    STATUS=FAIL
  else
    # Success
    echo "[✔]    $message" >> $PHOTOS_MAIL_FILE
  fi
}

# Step 1: Backup to this computer's HDD
backup_local

# Step 2: Backup to mediaserver's HDD
backup_to_mediaserver

# Step 3: Backup to B2
backup_photos_to_b2

# Send status mail to personal email
echo -e "${GREEN}Sending email to $ADMIN_EMAIL...${NC}"
cat $PHOTOS_MAIL_FILE | mail -s "$STATUS - photos $DATE" $ADMIN_EMAIL
rm $PHOTOS_MAIL_FILE
