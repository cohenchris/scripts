#!/bin/bash

yes | paru -Syu

if [ $? -ne 0 ]; then
  exit
fi

cd /home/phrog/server
docker-compose pull
docker-compose up -d

yes | docker system prune
