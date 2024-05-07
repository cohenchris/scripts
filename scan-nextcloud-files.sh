#!/bin/bash

source $(dirname "$0")/.env

echo "Scanning ${FILES_DIR}..."

sudo chown -R http:http ${FILES_DIR}
sudo chmod -R 0755 ${FILES_DIR}

docker exec --user www-data nextcloud php occ files:scan --all
