#!/bin/bash

WORKING_DIR=$(dirname "$(realpath "$0")")
source ${WORKING_DIR}/../.env

require var SERVER_DIR

# Query vpn container to get public IP
PUBLIC_IP=$(curl -s localhost:8001/v1/publicip/ip | jq -r ".public_ip")
# Query vpn container to get forwarded port
PORT=$(grep "VPN_PORTS" ${SERVER_DIR}/.env | cut -d '=' -f 2)

nc -z $PUBLIC_IP $PORT

# If not connectable, restart
if [ $? -ne 0 ]; then
  echo "qBittorrent not connectable via VPN public IP."
  echo "Restarting VPN..."
  docker restart vpn
  echo "Restarting qBittorrent..."
  docker restart qbittorrent
else
  echo "qBittorrent connectable via VPN public IP."
  echo "No action required!"
fi
