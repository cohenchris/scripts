#!/usr/bin/env bash

WORKING_DIR=$(dirname "$(realpath "$0")")
source "${WORKING_DIR}/../.env"

require var "${SERVER_DIR}"

cd "${SERVER_DIR}"
./stacks stop all

./stacks start all

# Fix nextcloud warnings
"${WORKING_DIR}/nextcloud/nextcloud-install-ffmpeg.sh"
