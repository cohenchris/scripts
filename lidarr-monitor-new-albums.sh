#!/bin/bash

# This script monitors albums if:
# 1. The artist is monitored
# 2. The album has been released in the last 30 days
# 3. The album is not a single
#
# This functionality is built into Lidarr, but has been broken for a while

# Initialize environment
WORKING_DIR=$(dirname "$(realpath "$0")")
source ${WORKING_DIR}/.env

# Define constants
lidarr_api_url="${LIDARR_URL}:8686/api/v1"

# Fetch albums from Lidarr API
albums_url="${lidarr_api_url}/album?apikey=${LIDARR_API_KEY}"
response=$(curl -s -X GET "${albums_url}")

# Calculate the date 30 days ago in the format required
thirty_days_ago=$(date -d "-30 days" +%Y-%m-%dT%H:%M:%SZ)

# Filter albums with a release date within the last 30 days and monitored artists
# If an album has been released in the last 30 days, the artist is monitored, and it's not a single, select it for updating
next_albums=$(echo "${response}" | jq --arg date "${thirty_days_ago}" '.[] | select(.releaseDate > $date and .artist.monitored == true and .albumType != "Single")')

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
