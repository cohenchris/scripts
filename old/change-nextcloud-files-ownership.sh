#!/bin/bash

sudo chown -R www-data:www-data /home/phrog/files
sudo chmod -R 0755 /home/phrog/files

docker exec --user www-data nextcloud php occ files:scan --all
