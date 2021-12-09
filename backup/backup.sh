#!/bin/bash

GREEN="\e[32m"
RED="\e[31m"
NC="\e[0m"

BACKUP_SCRIPTS_DIR=$(dirname "$0")
cd $BACKUP_SCRIPTS_DIR
source ./env

# Status initially is a success
STATUS=SUCCESS

# Will cause command to fail if ANYTHING in the pipe fails (useful for mail logging)
set -o pipefail

# redirect all output to LOG_FILE
LOG_FILE="$SRC-backup-$DATE.log"
cd $BACKUP_LOG_DIR
touch $LOG_FILE
exec 1>$LOG_FILE
exec 2>&1

# Start log file to be emailed
echo -e "$SRC backup $DATE\n---------------------------\n\n" > $MAIL_FILE

##### Tarball #####
function tarball_dir () {
  echo -e "${GREEN}Tarballing and encrypting $SRC files...${NC}"
  
  # First, export crontab files
  cd $DIR_TO_BACKUP
  crontab -l > crontab.txt
  sudo crontab -l > sudo_crontab.txt
  
  cd $BACKUP_SCRIPTS_DIR

  if [ "$SRC" == "nextcloud" ]; then
    tar --exclude=".git" \
        --exclude="scripts" \
        --exclude="files" \
        --exclude="cloud/nextcloud/data/appdata*/preview" \
        -cz $DIR_TO_BACKUP | gpg --symmetric -o "$LOCAL_DST_DIR/$BACKUP_NAME" --passphrase-file gpgpass --pinentry-mode loopback
  else
    tar --exclude=".git" \
        --exclude="scripts" \
        --exclude="files" \
        --exclude="mediaserver/transcode" \
        --exclude="mediaserver/config/lidarr/MediaCover" \
        --exclude="mediaserver/config/plex/Library/Application Support/Plex Media Server/Metadata" \
        --exclude="mediaserver/config/plex/Library/Application Support/Plex Media Server/Cache" \
        --exclude="mediaserver/config/plex/Library/Application Support/Plex Media Server/Media" \
        --exclude="mediaserver/config/jellyfin/cache" \
        --exclude="mediaserver/config/jellyfin/data/transcodes" \
        --exclude="mediaserver/config/jellyfin/data/metadata" \
        -cz $DIR_TO_BACKUP | gpg --symmetric -o "$LOCAL_DST_DIR/$BACKUP_NAME" --passphrase-file gpgpass --pinentry-mode loopback
  fi

  # Clear crontab files
  cd $DIR_TO_BACKUP
  rm crontab.txt sudo_crontab.txt
  cd $BACKUP_SCRIPTS_DIR

  tar_status=$?

  # Log event to mail.log
  mail_log $tar_status "compression and encryption"

  # If tar fails, remove the file. If this is not done, subsequent steps will "succeed", even though they are working with a basically empty tgz.gpg file.
  if [ $tar_status -gt 0 ]; then
    echo -e "${RED}Tarball/encryption failed. Removing $LOCAL_DST_DIR/$BACKUP_NAME...${NC}"
    rm $LOCAL_DST_DIR/$BACKUP_NAME
  fi

}


####################
#   PAUSE/RESUME   #
####################

##### Pause running containers #####
function pause_containers() {
  if [ "$SRC" == "nextcloud" ]; then
    # turn on nextcloud maintenance mode
    echo -e "${GREEN}Turning on nextcloud maintenance mode...${NC}"
    cd /home/chris/cloud
    /usr/local/bin/docker-compose exec -T --user www-data nextcloud php occ maintenance:mode --on
  else
    echo -e "${GREEN}Stopping all mediaserver containers...${NC}"
    # stop mediaserver containers
    cd /home/phrog/mediaserver
    /usr/local/bin/docker-compose down
  fi

  # Log event to mail.log
  mail_log $? "container pause"
}

##### Resume previously running containers #####
function resume_containers() {
  if [ "$SRC" == "nextcloud" ]; then
    # turn off nextcloud maintenance mode
    echo -e "${GREEN}Turning off nextcloud maintenance mode...${NC}"
    cd /home/chris/cloud
    /usr/local/bin/docker-compose exec -T --user www-data nextcloud php occ maintenance:mode --off
  else
    # restart mediaserver containers
    echo -e "${GREEN}Restarting all mediaserver containers...${NC}"
    cd /home/phrog/mediaserver
    /usr/local/bin/docker-compose up -d
  fi

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

  for filename in $LOCAL_DST_DIR/*; do
    CURR=$(stat -c %Z "$filename")
    AGE=$(($NOW-$CURR))
    DAYS=$(($AGE/86400))

    echo -e "${GREEN}$filename is $DAYS days old${NC}"

    if [[ $DAYS -ge $LOCAL_DELETE_OLDER_THAN ]]; then
      # log deletion to mail.log
      echo "Deleting $filename -- $DAYS old  (max $LOCAL_DELETE_OLDER_THAN)" >> $MAIL_FILE

      echo -e "${RED}Deleting $filename!!${NC}"
      rm -f $filename
    fi
  done

  # Log event to mail.log
  mail_log $? "local clean"
}

##### Backup local backups to other computer #####
function backup_local () {
  echo -e "${GREEN}Backing up $SRC to $DST${NC}"
  cd $LOCAL_DST_DIR
  rsync -av --progress --delete "$BACKUP_NAME" $DST_ROUTE:/backups/$SRC

  # Log event to mail.log
  mail_log $? "local rsync backup (main backup)"

  # Save max age locally for the other server. Cleaning script cleans out that folder based on this file
  echo $LOCAL_DELETE_OLDER_THAN > .maxage
  rsync -av --progress ".maxage" $DST_ROUTE:/backups/$SRC
}

##### Backup music files to mediaserver and nextcloud #####
function backup_music() {
  cd $MUSIC_DIR

	echo -e "$(date) : ${GREEN}Start music backup to local HDD${NC}"
  rsync -arP --delete . $MUSIC_BACKUPS_DIR
  mail_log $? "music backup to local HDD"
	echo -e "$(date) : ${GREEN}Music backed up to local HDD${NC}"

	echo -e "$(date) : ${GREEN}Start music backup to $DST${NC}"
  rsync -arP --delete . $DST_ROUTE:$MUSIC_BACKUPS_DIR
  mail_log $? "music backup to $DST"
	echo -e "$(date) : ${GREEN}Music backed up to $DST${NC}"
}

####################
#    B2 BACKUPS    #
####################

##### Backup to B2 bucket #####
function backup_to_b2 () {
  cd $LOCAL_DST_DIR

	BUFILE=$(readlink -f "$BACKUP_NAME") # Backup FILE

	# Begin Backup
	echo -e "$(date) : ${GREEN}Start backup of $BUFILE to $BBBUCKET${NC}"
	BUPATH=$(dirname "$BUFILE")
	cd "$BUPATH"
	FILENAME=$(basename "$BUFILE")

	# Upload
	SHA=`sha1sum "$BACKUP_NAME" | awk '{print $1}'`
	echo -e "$(date) : ${GREEN}$BACKUP_NAME checksum:${NC}"
	echo -e "$(date) : 	${GREEN}$SHA${NC}"
	echo -e "$(date) : ${GREEN}Uploading...${NC}"
	/usr/local/bin/b2 upload_file --sha1 $SHA $BBBUCKET "$BACKUP_NAME" "$BACKUP_NAME"
  # Log event to mail.log
  mail_log $? "b2 backup"
	echo -e "$(date) : ${GREEN}Uploaded to $BBBUCKET:$BACKUP_NAME${NC}"
}

##### Clean the B2 bucket #####
function clean_b2 () {
  FILES=$(/usr/local/bin/b2 ls --long --json $BBBUCKET)
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

    if [[ $DAYS -ge $REMOTE_DELETE_OLDER_THAN ]]; then
      echo -e "${RED}Deleting $fileName!${NC}"
      # log deletion
      /usr/local/bin/b2 delete-file-version $fileName $fileId
      # log deletion to mail.log
      echo "Deleting $fileName -- $DAYS days old  (max $REMOTE_DELETE_OLDER_THAN days)" >> $MAIL_FILE
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


############################################################################
# Do da backup

START="$(date +%s)"

pause_containers


if [ "$SRC" == "mediaserver" ]; then
  backup_music
fi

TAR_START="$(date +%s)"
tarball_dir
TAR_END="$(date +%s)"

resume_containers

clean_local

BACKUP_LOCAL_START="$(date +%s)"
backup_local
BACKUP_LOCAL_END="$(date +%s)"

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

# Send status mail to personal email
if [ $STATUS == "FAIL" ]; then
  echo -e "${GREEN}Failure, sending email to $ADMIN_EMAIL...${NC}"
  MAIL_BODY=$(cat $MAIL_FILE)
  echo "To: $ADMIN_EMAIL" > $MAIL_FILE
  echo "From: $SRC <$SRC@$MAIL_DOMAIN>" >> $MAIL_FILE
  echo "Subject: $STATUS - files $DATE" >> $MAIL_FILE
  echo "$MAIL_BODY" >> $MAIL_FILE
  ssmtp $ADMIN_EMAIL < $MAIL_FILE
else
  echo -e "${GREEN}Success, not sending email to $ADMIN_EMAIL...${NC}"
fi
rm $MAIL_FILE
