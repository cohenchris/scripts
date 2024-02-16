#!/bin/bash

declare -a endpoints=(
  audiobooks.lan
  audiobookshelf.lan
  bitwarden.lan
  collabora.lan
  ddns.lan
  ebooks.lan
  freshrss.lan
  homeassistant.lan
  lidarr.lan
  nextcloud.lan
  nzbget.lan
  overseerr.lan
  plex.lan
  prowlarr.lan
  qbittorrent.lan
  radarr.lan
  rssbridge.lan
  searx.lan
  sonarr.lan
  tautulli.lan
  wud.lan
)

declare -a containers=(
  audiobooks
  audiobookshelf
  bitwarden
  collabora
  ddns
  ebooks
  freshrss
  homeassistant
  lidarr
  nextcloud
  nzbget
  overseerr
  plex
  prowlarr
  qbittorrent
  radarr
  rssbridge
  searx
  sonarr
  tautulli
  wud
)

declare -a vpn_containers=(
  audiobooks
  ebooks
  lidarr
  nzbget
  prowlarr
  qbittorrent
  radarr
  sonarr
)

for i in "${!endpoints[@]}"; do
  response_code=$(curl --insecure https://${endpoints[$i]} -o /dev/null -s -w "%{http_code}\n")

  if [[ $response_code -eq 502 ]]; then
    echo "502 error for ${endpoints[$i]} - Restarting ${containers[$i]}..."

    # VPN sometimes fails. If a container connected to VPN is failing, restart VPN just in case
    if [[ "${vpn_containers[@]}" =~ "${containers[$i]}" ]]; then
      echo "Container ${containers[$i]} is connected to VPN. Restarting VPN..."
      docker restart vpn
    fi

    # Restart failing container
    docker restart ${containers[$i]}
  fi

done
