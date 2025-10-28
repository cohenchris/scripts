#!/usr/bin/env bash

if ! dpkg -s ffmpeg &> /dev/null; then
  # Install ffmpeg if not present
  docker exec nextcloud apt -y update
  docker exec nextcloud apt -y upgrade
  docker exec nextcloud apt -y install libmagickcore-6.q16-6-extra ffmpeg
fi
