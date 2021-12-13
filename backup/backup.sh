#!/bin/bash

GREEN="\e[32m"
RED="\e[31m"
NC="\e[0m"

# Source the environment file
BASE_DIR=$(dirname "$0")
cd $BASE_DIR
source ./env

DATE=$(date +"%Y%m%d")

# Will cause command to fail if ANYTHING in the pipe fails (useful for mail logging)
set -o pipefail

# redirect all output to LOG_FILE
LOG_FILE="backup-$DATE.log"
cd $LOG_DIR
touch $LOG_FILE
exec 1>$LOG_FILE
exec 2>&1

# Status is initially success
STATUS=SUCCESS


# Start log file to be emailed
echo -e "backup $DATE\n---------------------------\n\n" > $MAIL_FILE

##### Tarball #####
function tarball_dir () {
  echo -e "${GREEN}Tarballing and encrypting server files...${NC}"
  
  # First, export crontab files
  cd $DIR_TO_BACKUP
  crontab -l -u $BACKUP_USER > crontab.txt
  crontab -l > sudo_crontab.txt
    
  cd $BASE_DIR

  tar --exclude=".git" \
      --exclude="scripts" \
      --exclude="files" \
      --exclude="server/config/nextcloud/data/appdata*/preview" \
      --exclude="server/transcode" \
      --exclude="server/config/lidarr/MediaCover" \
      --exclude="server/config/plex/Library/Application Support/Plex Media Server/Metadata" \
      --exclude="server/config/plex/Library/Application Support/Plex Media Server/Cache" \
      --exclude="server/config/plex/Library/Application Support/Plex Media Server/Media" \
      --exclude="server/config/jellyfin/cache" \
      --exclude="server/config/jellyfin/data/transcodes" \
      --exclude="server/config/jellyfin/data/metadata" \
      -cz $DIR_TO_BACKUP | gpg --symmetric -o "$BACKUP_DIR/$BACKUP_NAME" --passphrase-file gpgpass --pinentry-mode loopback
  tar_status=$?

  # Clear crontab files
  cd $DIR_TO_BACKUP
  rm crontab.txt sudo_crontab.txt
  cd $BASE_DIR

  # Log event to mail.log
  mail_log $tar_status "compression and encryption"

  # If tar fails, remove the file. If this is not done, subsequent steps will "succeed", even though they are working with a basically empty tgz.gpg file.
  if [ $tar_status -gt 0 ]; then
    echo -e "${RED}Tarball/encryption failed. Removing $BACKUP_DIR/$BACKUP_NAME...${NC}"
    rm $BACKUP_DIR/$BACKUP_NAME
  fi

}


####################
#   PAUSE/RESUME   #
####################

##### Pause running containers #####
function pause_containers() {
  echo -e "${GREEN}Stopping all server containers...${NC}"
  cd /home/$BACKUP_USER/server
  /usr/local/bin/docker-compose down

  # Log event to mail.log
  mail_log $? "container pause"
}

##### Resume previously running containers #####
function resume_containers() {
  echo -e "${GREEN}Restarting all server containers...${NC}"
  cd /home/$BACKUP_USER/server
  /usr/local/bin/docker-compose up -d

  # Log event to mail.log
  mail_log $? "container resume"
}
####################
#  LOCAL BACKUPS   #
####################

##### Clean local backup files #####
function clean_local () {
  # Now, in seconds since Epoch
  NOW=$(date +%s)

  for filename in $BACKUP_DIR/*; do
    CURR=$(stat -c %Z "$filename")
    AGE=$(($NOW-$CURR))
    DAYS=$(($AGE/86400))

    echo -e "${GREEN}$filename is $DAYS days old${NC}"

    if [[ $DAYS -ge $BACKUP_MAX_AGE ]]; then
      # log deletion to mail.log
      echo "Deleting $filename -- $DAYS days old  (max $BACKUP_MAX_AGE)" >> $MAIL_FILE

      echo -e "${RED}Deleting $filename!!${NC}"
      rm -f $filename
    fi
  done

  # Log event to mail.log
  mail_log $? "local backup clean"
}


##### Backup local backups to other computer #####
function backup_local () {
  echo -e "${GREEN}Backing up to backup server${NC}"
  cd $BACKUP_DIR
  rsync -av --progress --delete "$BACKUP_NAME" $DST_ROUTE:$BACKUP_DIR

  # Log event to mail.log
  mail_log $? "local rsync backup (main backup)"

  # Save max age locally for the other server. Cleaning script cleans out that folder based on this file
  echo $BACKUP_MAX_AGE > .maxage
  rsync -av --progress ".maxage" $DST_ROUTE:$BACKUP_DIR
}

##### Backup music files to server and nextcloud #####
function backup_music() {
  cd $MUSIC

	echo -e "$(date) : ${GREEN}Start music backup to local HDD${NC}"
  rsync -arP --delete . $MUSIC_BACKUPS
  mail_log $? "music backup to local HDD"
	echo -e "$(date) : ${GREEN}Music backed up to local HDD${NC}"

	echo -e "$(date) : ${GREEN}Start music backup to backup server${NC}"
  rsync -arP --delete . $DST_ROUTE:$MUSIC_BACKUPS
  mail_log $? "music backup to backup server"
	echo -e "$(date) : ${GREEN}Music backed up to backup server${NC}"
}

##### Clean remote backup files #####
function clean_remote () {
  # Now, in seconds since epoch
  NOW=$(date +%s)

ssh $DST_ROUTE << EOF
  for filename in $BACKUP_DIR/*; do
    CURR=$(stat -c %Z "$filename")
    AGE=$((NOW - CURR))
    DAYS=$((AGE / 86400))

    echo -e "${GREEN}$filename is $DAYS days old${NC}"

    if [[ $DAYS -ge $BACKUP_MAX_AGE ]]; then
      # log deletion to mail.log
      echo "Deleting $filename -- $DAYS old (max $BACKUP_MAX_AGE)" >> $MAIL_FILE

      echo -e "${RED}Deleting $filename!!${NC}"
      rm -f $filename
    fi
  done
  exit
EOF

  mail_log $? "remote backup clean"

  echo -e "${GREEN}Finished cleaning up remote backup server${NC}"
}


####################
#    B2 BACKUPS    #
####################

##### Backup to B2 bucket #####
function backup_to_b2 () {
  cd $BACKUP_DIR

	# Begin Backup
	echo -e "$(date) : ${GREEN}Start backup of $BACKUP_NAME to $B2_BACKUP_BUCKET${NC}"

	# Upload
	SHA=`sha1sum "$BACKUP_NAME" | awk '{print $1}'`
	echo -e "$(date) : ${GREEN}$BACKUP_NAME checksum:${NC}"
	echo -e "$(date) : 	${GREEN}$SHA${NC}"
	echo -e "$(date) : ${GREEN}Uploading...${NC}"
	/usr/local/bin/b2 upload_file --sha1 $SHA $B2_BACKUP_BUCKET "$BACKUP_NAME" "$BACKUP_NAME"
  # Log event to mail.log
  mail_log $? "b2 backup"
	echo -e "$(date) : ${GREEN}Uploaded to $B2_BACKUP_BUCKET:$BACKUP_NAME${NC}"
}

##### Clean the B2 bucket #####
function clean_b2 () {
  FILES=$(/usr/local/bin/b2 ls --long --json $B2_BACKUP_BUCKET)
  NOW=$(date +%s)

  # Loop through each file in the bucket
  jq -c '.[]' <<< "$FILES" | while read i; do
    # Parse required info
    fileName=$(echo $i | jq -r '.fileName')
    fileId=$(echo $i | jq -r '.fileId')
    uploadTimestamp=$(expr $(echo $i | jq '.uploadTimestamp') / 1000)

    # Check how old the file is
    AGE=$(($NOW - $uploadTimestamp))
    DAYS=$(($AGE/86400))
    echo -e "${GREEN}$fileName is $DAYS days old${NC}"

    if [[ $DAYS -ge $B2_MAX_AGE ]]; then
      echo -e "${RED}Deleting $fileName!${NC}"
      # log deletion
      /usr/local/bin/b2 delete-file-version $fileName $fileId
      # log deletion to mail.log
      echo "Deleting $fileName -- $DAYS days old  (max $B2_MAX_AGE days)" >> $MAIL_FILE
    fi
  done

  # Log event to mail.log
  mail_log $? "b2 clean"
}

# Converts seconds to the following format:
# 0d 0h 0m 0s
# https://stackoverflow.com/questions/12199631/convert-seconds-to-hours-minutes-seconds
function show_time () {
    num=$1
    min=0
    hour=0
    day=0
    if((num>59));then
        ((sec=num%60))
        ((num=num/60))
        if((num>59));then
            ((min=num%60))
            ((num=num/60))
            if((num>23));then
                ((hour=num%24))
                ((day=num/24))
            else
                ((hour=num))
            fi
        else
            ((min=num))
        fi
    else
        ((sec=num))
    fi
    echo "$day"d "$hour"h "$min"m "$sec"s
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
  file=$2
  while ! ssmtp $email < $file
  do
    echo -e "${RED}email failed, trying again...${NC}"
    sleep 5
  done
}


############################################################################
# Do da backup

START="$(date +%s)"

pause_containers

backup_music

TAR_START="$(date +%s)"
tarball_dir
TAR_END="$(date +%s)"

resume_containers

clean_local

BACKUP_LOCAL_START="$(date +%s)"
backup_local
BACKUP_LOCAL_END="$(date +%s)"

clean_remote

clean_b2

B2_BACKUP_START="$(date +%s)"
backup_to_b2
B2_BACKUP_END="$(date +%s)"

TAR=$[ ${TAR_END} - ${TAR_START} ]
LOCAL=$[ ${BACKUP_LOCAL_END} - ${BACKUP_LOCAL_START} ]
B2=$[ ${B2_BACKUP_END} - ${B2_BACKUP_START} ]
TOTAL=$[ $(date +%s) - ${START} ]

echo
echo
echo -e "${GREEN}TAR TIME: $(show_time $TAR)${NC}"
echo -e "${GREEN}LOCAL RSYNC TIME: $(show_time $LOCAL)${NC}"
echo -e "${GREEN}B2 BACKUP TIME: $(show_time $B2)${NC}"
echo -e "${GREEN}TOTAL ELAPSED TIME: $(show_time $TOTAL)${NC}"
echo

# Log status
if [ $STATUS == "FAIL" ]; then
  echo -e "${RED}Failure, sending email to $ADMIN_EMAIL...${NC}"
else
  echo -e "${GREEN}Success, sending email to $ADMIN_EMAIL...${NC}"
fi

# Send status email
MAIL_BODY=$(cat $MAIL_FILE)
echo "To: $ADMIN_EMAIL" > $MAIL_FILE
echo "From: root <root@$MAIL_DOMAIN>" >> $MAIL_FILE
echo "Subject: $STATUS - files $DATE" >> $MAIL_FILE
echo
echo "$MAIL_BODY" >> $MAIL_FILE
poll_smtp $ADMIN_EMAIL $MAIL_FILE
rm $MAIL_FILE
