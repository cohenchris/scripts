#!/bin/bash

WORKING_DIR=$(dirname "$0")
source $WORKING_DIR/.env

sudo chown -R $USER:1000 ${MEDIA_DIR}

sudo find ${MEDIA_DIR} -type d -exec chmod 775 {} \;
sudo find ${MEDIA_DIR} -type f -exec chmod 644 {} \;
