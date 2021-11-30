#!/bin/bash

sudo chown -R www-data:www-data ~/files
sudo chmod -R 0750 ~/files

cd ~/cloud
docker-compose exec --user www-data nextcloud php occ files:scan --all
