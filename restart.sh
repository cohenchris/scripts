#!/bin/bash

source $(dirname "$0")/.env
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin

cd ${SERVER_DIR}
docker-compose down

docker-compose up -d --remove-orphans

cd

# Fix nextcloud warnings
docker exec nextcloud apt -y update
docker exec nextcloud apt -y install libmagickcore-6.q16-6-extra ffmpeg

$(dirname "$0")/dynamic-seedbox.sh
