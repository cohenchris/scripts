#!/bin/bash

WORKING_DIR=$(dirname "$(realpath "$0")")
source "${WORKING_DIR}/../../.env"

require var "${NEXTCLOUD_FILES_DIR}"

echo "Working on ${NEXTCLOUD_FILES_DIR}"

echo "Changing ownership of all files to http:http..."

sudo chown -R http:http "${NEXTCLOUD_FILES_DIR}"

echo "Changing permission bits for all directories to 755..."
sudo find "${NEXTCLOUD_FILES_DIR}" -type d -exec chmod 755 {} \;

echo "Changing permission bits for all files to 644..."
sudo find "${NEXTCLOUD_FILES_DIR}" -type f -exec chmod 644 {} \;

echo "Running Nextcloud scan..."
docker exec --user www-data nextcloud php occ files:scan --all

echo "Done!"
