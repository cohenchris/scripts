#!/bin/bash

# This script monitors albums if:
# 1. The artist is monitored
# 2. The album has been released in the NUM_DAYS_TO_MONITOR days
# 3. The album is not a single
#
# This functionality is built into Lidarr, but has been broken for a while

NUM_DAYS_TO_MONITOR=${1}

if [ -z "${NUM_DAYS_TO_MONITOR}" ]; then
  echo "Please specify the number of days to monitor"
  exit 1
elif [ "${NUM_DAYS_TO_MONITOR}" -eq 0 ]; then
  echo "Please specify a number of days greater than 0"
  exit 1
fi

# Initialize environment
WORKING_DIR=$(dirname "$(realpath "$0")")
source ${WORKING_DIR}/../.env

# Define constants
lidarr_api_url="${LIDARR_URL}:8686/api/v1"

# Fetch albums from Lidarr API
albums_url="${lidarr_api_url}/album?apikey=${LIDARR_API_KEY}"
response=$(curl -s -X GET "${albums_url}")

# Calculate the date NUM_DAYS_TO_MONITOR days ago in the format required
monitoring_period=$(date -d "-${NUM_DAYS_TO_MONITOR} days" +%Y-%m-%dT%H:%M:%SZ)

# Filter albums with a release date within the last 30 days and monitored artists
# If an album has been released in the last 30 days, the artist is monitored, and it's not a single, select it for updating
next_albums=$(echo "${response}" | jq --arg date "${monitoring_period}" '.[] | select(.releaseDate > $date and .artist.monitored == true and .albumType != "Single")')

# URL to update album monitoring status
update_album_url="${lidarr_api_url}/album/monitor?apikey=${LIDARR_API_KEY}"

# Loop through each album and update its monitoring status if the artist is monitored
jq -c '{id: .id, artistName: .artist.artistName, title: .title}' <<< "${next_albums}" | while read -r album_json; do
    # Extract the album ID, artist name, and album title
    album_id=$(echo "${album_json}" | jq -r '.id')
    artist_name=$(echo "${album_json}" | jq -r '.artistName')
    album_name=$(echo "${album_json}" | jq -r '.title')

    # Print artist and album name for confirmation
    echo "Monitoring ${album_name} by ${artist_name}..."

    # Prepare JSON data for the monitoring update
    album_update_json=$(jq -n --argjson id "${album_id}" '{albumIds: [$id], monitored: true}')

    # Update monitoring status
    curl -s -o /dev/null -X PUT "${update_album_url}" -H "Content-Type: application/json" -d "${album_update_json}"
done
