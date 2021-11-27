#!/bin/bash

source ./env

BUFILE=$1 # full path

if [[ -z $BUFILE ]]; then
  echo "error - full file path required"
  exit
fi

BUPATH=$(dirname "$BUFILE") # directory where the file resides
FILENAME=$(basename "$BUFILE") # filename
cd "$BUPATH"
#SHA=`sha1sum "$FILENAME" | awk '{print $1}'` # sha1 hash of the file


UNFINISHED=$(/usr/local/bin/b2 list-unfinished-large-files $BBBUCKET)
UNFINISHED=$(echo $UNFINISHED | grep $FILENAME)
NUM_UNFINISHED=$(echo $UNFINISHED | wc -l)
if [[ $NUM_UNFINISHED -gt 1 ]]; then
  echo "error - multiple unfinished files of the same name"
  exit
fi

FILE_ID=$(echo $UNFINISHED | cut -d " " -f 1)
LAST_MODIFIED=$(echo $UNFINISHED | cut -d " " -f 4)

PARTS=$(/usr/local/bin/b2 list-parts $FILE_ID)
PART_SIZE=$(echo $PARTS | cut -d " " -f 2)

/usr/local/bin/b2 upload-file --info $LAST_MODIFIED --minPartSize $PART_SIZE $BBBUCKET "$FILENAME" "$FILENAME"
