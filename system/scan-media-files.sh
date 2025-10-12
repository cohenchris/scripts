#!/bin/bash

WORKING_DIR=$(dirname "$(realpath "$0")")
source "${WORKING_DIR}/.env"

require var "${MEDIA_FILES_DIR}"

echo "Working on ${MEDIA_FILES_DIR}"

echo "Changing ownership of all files to ${USER}:1000..."
sudo chown -R "${USER}:1000" "${MEDIA_FILES_DIR}"

echo "Changing permission bits for all directories to 755..."
sudo find "${MEDIA_FILES_DIR}" -type d -exec chmod 755 {} \;

echo "Changing permission bits for all files to 644..."
sudo find "${MEDIA_FILES_DIR}" -type f -exec chmod 644 {} \;

echo "Done!"
