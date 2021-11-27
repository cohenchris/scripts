#!/bin/bash

# This script looks at my nextcloud's .PhoneBackups/Signal directory and cleans out all but the most recent 2 backups

GREEN="\e[32m"
RED="\e[31m"
NC="\e[0m"

NUM_DELETE=$(($(rclone ls nextcloud:.PhoneBackups | grep signal | wc -l)-2))

# If there are 2 or fewer backups, no need to delete
if [[ $NUM_DELETE -le 0 ]]; then
  exit
fi

# List files to delete - files that aren't the most recent 2
DELETE=$(rclone lsf nextcloud:.PhoneBackups | grep signal | head -n $NUM_DELETE)

# Delete the files
for i in ${DELETE[@]}; do
  echo -e "${RED}Deleting $i...${NC}"
  rclone delete nextcloud:.PhoneBackups/$i
done
