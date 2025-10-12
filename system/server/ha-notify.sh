#!/bin/bash

# Load environment variables
WORKING_DIR=$(dirname "$(realpath "$0")")
source "${WORKING_DIR}/../.env"

MAX_NOTIFICATION_ATTEMPTS=100
title=$1
body=$2

require var "${title}"
require var "${body}"
require var "${HA_NOTIFY_WEBHOOK_ENDPOINT}"

# Send the POST request until it succeeds
for (( attempt=1; attempt<=MAX_NOTIFICATION_ATTEMPTS; attempt++ ))
do
  response=$(curl -s -o /dev/null                               \
                  -w "%{http_code}"                             \
                  -X POST                                       \
                  -H "Content-Type: application/json"           \
                  -d "{\"title\": \"${title}\", \"body\": \"${body}\"}"  \
                  "${HA_NOTIFY_WEBHOOK_ENDPOINT}")

  if [ "${response}" -eq 200 ]; then
      echo "Notification sent successfully!"
      exit 0
  else
      echo "Notification failed, trying again..."
      sleep 5
  fi
done

echo "Unable to send notification :("
exit 1
