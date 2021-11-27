#!/bin/bash

GREEN="\e[32m"
RED="\e[31m"
NC="\e[0m"

cd $CLEAN_DST_DIR

SCRIPT_DIR=$(dirname "$0")
cd $SCRIPT_DIR
source ./env

# redirect all output to LOG_FILE
LOG_FILE="$DST-clean-$DATE.log"
cd $CLEAN_LOG_DIR
touch $LOG_FILE
exec 1>$LOG_FILE
exec 2>&1

if ! [ -f "$CLEAN_DST_DIR/.maxage" ]; then
  echo -e "${RED}.maxage file does not exist in $CLEAN_DST_DIR. Cannot clean...${NC}"
  exit
fi

MAX_AGE=$(cat $CLEAN_DST_DIR/.maxage)

##### Clean local backup files #####
function clean_local () {
  # Now, in seconds since Epoch
  NOW=$(date +%s)

  for filename in $CLEAN_DST_DIR/*; do
    CURR=$(stat -c %Z "$filename")
    AGE=$(($NOW-$CURR))
    DAYS=$(($AGE/86400))

    echo -e "${GREEN}$filename is $DAYS days old${NC}"

    if [[ $DAYS -ge $MAX_AGE ]]; then
      echo -e "${RED}$filename is $DAYS days old - deleting...${NC}"
      rm -f $filename
    else
      echo -e "${GREEN}$filename is $DAYS days old${NC}"
    fi
  done
}

clean_local
