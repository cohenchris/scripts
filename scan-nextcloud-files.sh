#!/bin/bash

WORKING_DIR=$(dirname "$(realpath "$0")")
source $WORKING_DIR/.env

echo "Scanning ${NEXTCLOUD_FILES_DIR}..."

sudo chown -R http:http ${NEXTCLOUD_FILES_DIR}
sudo chmod -R 0755 ${NEXTCLOUD_FILES_DIR}

docker exec --user www-data nextcloud php occ files:scan --all
