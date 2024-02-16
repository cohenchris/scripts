#!/bin/bash

sudo chown -R http:http /home/$USER/files
sudo chmod -R 0755 /home/$USER/files

docker exec --user www-data nextcloud php occ files:scan --all
