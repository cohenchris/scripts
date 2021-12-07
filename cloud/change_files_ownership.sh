#!/bin/bash

sudo chown -R www-data:www-data /home/chris/files
sudo chmod -R 0750 /home/chris/files

docker exec --user www-data nextcloud php occ files:scan --all
