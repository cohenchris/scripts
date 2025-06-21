#!/bin/bash

WORKING_DIR=$(dirname "$(realpath "$0")")
source "${WORKING_DIR}/../.env"

require var SERVER_DIR

cd "${SERVER_DIR}"
docker-compose down

docker-compose up -d --remove-orphans

# Fix nextcloud warnings
"${WORKING_DIR}/nextcloud/nextcloud-install-ffmpeg.sh"
