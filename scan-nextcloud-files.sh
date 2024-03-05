#!/bin/bash

# Optional arugment to pass an alternate username to use for files path
if [ -z "$1" ]; then
  LOCAL_USER=$USER
else
  LOCAL_USER="$1"
fi

sudo chown -R http:http /home/$LOCAL_USER/files
sudo chmod -R 0755 /home/$LOCAL_USER/files

docker exec --user www-data nextcloud php occ files:scan --all
