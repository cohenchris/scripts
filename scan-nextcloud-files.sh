#!/bin/bash

source $(dirname "$0")/.env

echo "Scanning ${NEXTCLOUD_FILES_DIR}..."

sudo chown -R http:http ${NEXTCLOUD_FILES_DIR}
sudo chmod -R 0755 ${NEXTCLOUD_FILES_DIR}

docker exec --user www-data nextcloud php occ files:scan --all
