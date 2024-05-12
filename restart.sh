#!/bin/bash

WORKING_DIR=$(dirname "$(realpath "$0")")
source $WORKING_DIR/.env

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin

cd ${SERVER_DIR}
docker-compose down

docker-compose up -d --remove-orphans

cd

# Fix nextcloud warnings
${WORKING_DIR}/nextcloud-install-ffmpeg.sh

$WORKING_DIR/dynamic-seedbox.sh
