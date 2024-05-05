#!/bin/bash

source $(dirname "$0")/.env

sudo chown -R $USER:1000 ${MEDIA_DIR}

sudo find ${MEDIA_DIR} -type d -exec chmod 775 {} \;
sudo find ${MEDIA_DIR} -type f -exec chmod 644 {} \;
