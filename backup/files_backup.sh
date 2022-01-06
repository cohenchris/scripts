#!/bin/bash

# Source the environment file
BASE_DIR=$(dirname $0)
cd $BASE_DIR
source ./env

# Will cause command to fail if ANYTHING in the pipe fails (useful for mail logging)
set -o pipefail

# redirect all output to LOG_FILE
LOG_FILE="files-backup-$DATE.log"
cd $LOG_DIR
touch $LOG_FILE
exec 1>$LOG_FILE
exec 2>&1

# Status is initially success
STATUS=SUCCESS

# Start log file to be emailed
echo -e "files backup $DATE\n---------------------------\n\n" > $MAIL_FILE

##### Backup files to this computer's HDD #####
function backup_files_local() {
  echo -e "${GREEN}Backing up files to local HDD...${NC}"
  
  cd $LOCAL_FILES_DIR

  # backup
  rsync -arzP --delete . $FILES_BACKUP_DIR

  # Log event to mail.log
  mail_log $? "backup to local HDD"
}


##### Backup files to backup server's HDD #####
function backup_files_remote() {
  echo -e "${GREEN}Backing up files to backup server...${NC}"

  cd $LOCAL_FILES_DIR

  # backup
  rsync -arzP --delete -e ssh . $DST_ROUTE:$FILES_BACKUP_DIR

  # Log event to mail.log
  mail_log $? "backup to backup server"
}


##### Backup files to B2 bucket #####
function backup_files_to_b2() {
	# Begin Backup
	echo -e "$(date) : ${GREEN}Start files backup to $B2_FILES_BUCKET${NC}"
  cd $LOCAL_FILES_DIR

	# Upload
	echo -e "$(date) : ${GREEN}Uploading...${NC}"
  /usr/local/bin/b2 sync --delete . b2://$B2_FILES_BUCKET

  # Log event to mail log
  mail_log $? "b2 files backup"
	echo -e "$(date) : ${GREEN}Uploaded files to $B2_FILES_BUCKET${NC}"
}


# Logs to 'mail.log' file
# first argument is the return code to evaluate
# second argument is the event-specific message to print
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

poll_smtp()
{
  email=$1
  subject=$2
  file=$3
  while ! mail -s "$subject" $email < $file
  do
    echo -e "${RED}email failed, trying again...${NC}"
    sleep 5
  done
}


# Step 1: Backup to this computer's HDD
backup_files_local

# Step 2: Backup to backup server's HDD
backup_files_remote

# Step 3: Backup to B2
backup_files_to_b2


SUBJECT="$STATUS - files backup $DATE"
# Send status mail to personal email
if [ $STATUS == "FAIL" ]; then
  echo -e "${RED}Files backup failed...${NC}"
  poll_smtp $ADMIN_EMAIL "$SUBJECT" $MAIL_FILE
else
  echo -e "${GREEN}Files backup succeeded!...${NC}"
  poll_smtp $ADMIN_EMAIL "$SUBJECT" $MAIL_FILE # remove me later
fi
  
rm $MAIL_FILE
