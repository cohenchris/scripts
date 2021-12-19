#!/bin/bash

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin

cd /home/phrog/server/
docker-compose down

docker-compose up -d --remove-orphans

cd

docker restart sonarr lidarr radarr >/dev/null 2>&1 &

/home/phrog/scripts/fix_nextcloud_warnings.sh >/dev/null 2>&1 &
