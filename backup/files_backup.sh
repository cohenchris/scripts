#!/bin/bash


BACKUP_SCRIPTS_DIR=$(dirname "$0")
cd $BACKUP_SCRIPTS_DIR
source ./env

# redirect all output to LOG_FILE
LOG_FILE="files-backup-$DATE.log"
cd $FILES_BACKUP_LOG_DIR
touch $LOG_FILE
exec 1>$LOG_FILE
exec 2>&1

STATUS=SUCCESS


##### Backup files to this computer's HDD #####
function backup_files_locally() {
  echo -e "${GREEN}Backing up files to local HDD...${NC}"
  
  cd $LOCAL_FILES_DIR

  # backup
  rsync -arP --delete . $LOCAL_FILES_BACKUP_DIR

  # Log event to mail.log
  mail_log $? "backup to local HDD"
}


##### Backup files to mediaserver's HDD #####
function backup_files_to_mediaserver() {
  echo -e "${GREEN}Backing up files to mediaserver HDD...${NC}"

  cd $LOCAL_FILES_BACKUP_DIR

  # backup
  rsync -arP --delete . $DST_ROUTE:$REMOTE_FILES_BACKUP_DIR

  # Log event to mail.log
  mail_log $? "backup to mediaserver HDD"
}


##### Backup files to B2 bucket #####
function backup_files_to_b2() {
	# Begin Backup
	echo -e "$(date) : ${GREEN}Start files backup to $BBFILESBUCKET${NC}"
  cd $LOCAL_FILES_DIR

	# Upload
	echo -e "$(date) : ${GREEN}Uploading...${NC}"
  /usr/local/bin/b2 sync --delete . b2://$BBFILESBUCKET

  # Log event to mail log
  mail_log $? "b2 files backup"
	echo -e "$(date) : ${GREEN}Uploaded files to $BBFILESBUCKET${NC}"
}


# Logs to 'mail.log' file
# first argument is the return code to evaluate
# second argument is the event-specific message to print
function mail_log() {
  code=$1
  message=$2

  if [ $code -gt 0 ]; then
    # Failure
    echo "[✘]    $message" >> $FILES_BACKUP_MAIL_FILE
    STATUS=FAIL
  else
    # Success
    echo "[✔]    $message" >> $FILES_BACKUP_MAIL_FILE
  fi
}

# Step 1: Backup to this computer's HDD
backup_files_locally

# Step 2: Backup to mediaserver's HDD
backup_files_to_mediaserver

# Step 3: Backup to B2
backup_files_to_b2

# Send status mail to personal email
echo -e "${GREEN}Sending email to $ADMIN_EMAIL...${NC}"
cat $FILES_BACKUP_MAIL_FILE | mail -s "$STATUS - files $DATE" $ADMIN_EMAIL
rm $FILES_BACKUP_MAIL_FILE
