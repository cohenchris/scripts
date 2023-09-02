#!/bin/bash

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin

cd /home/phrog/server/
docker-compose down

docker-compose up -d --remove-orphans

cd

# Fix nextcloud warnings
docker exec nextcloud apt -y update
docker exec nextcloud apt -y install libmagickcore-6.q16-6-extra ffmpeg

/home/phrog/scripts/dynamic-seedbox.sh
