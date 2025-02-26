#!/bin/bash

WORKING_DIR=$(dirname "$(realpath "$0")"
source ${WORKING_DIR}/.env

require var BATOCERA_HOST

function batocera_mount()
{
  if [ -d "batocera" ]; then
    echo "ERROR: directory $(pwd)/batocera already exists"
  else
    echo "Mounting ${BATOCERA_HOST}:/userdata at $(pwd)/batocera"
    mkdir batocera
    sshfs ${BATOCERA_HOST}:/userdata batocera
  fi
}

function batocera_unmount()
{
  if [ -d "batocera" ]; then
    echo "Unmounting/removing directory $(pwd)/batocera"
    umount ./batocera
    rm -r ./batocera
  else
    echo "Directory $(pwd)/batocera doesn't exist, skipping umount"
  fi
}

if [ "$1" == "mount" ]; then
  batocera_mount
elif [ "$1" == "unmount" ]; then
  batocera_unmount
else
  echo "Invalid argument - choose one of [mount, unmount]"
fi
