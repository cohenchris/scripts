#!/bin/bash

docker exec nextcloud apt -y update
docker exec nextcloud apt -y install libmagickcore-6.q16-6-extra ffmpeg
