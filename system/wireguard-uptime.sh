#!/usr/bin/env bash

# Reports WireGuard tunnel health to a push-monitoring webhook (e.g. Uptime Kuma).
# Confirms the interface has an established peer and that traffic actually flows,
# then pushes the status and round-trip latency to the webhook.

# Initialize environment
WORKING_DIR=$(dirname "$(realpath "$0")")
source "${WORKING_DIR}/.env"

# Host pinged to confirm the tunnel is passing traffic (Google DNS)
PING_TARGET="8.8.8.8"


# Ensure required variables are set
require var "${WG_INTERFACE}"
require var "${WEBHOOK_URL}"

# Check whether the WireGuard interface has an established peer
if wg show "${WG_INTERFACE}" | grep -q "peer"; then
  STATUS="up"
  MSG="connected"

  # Confirm the tunnel actually passes traffic by measuring round-trip latency
  PING=$(ping -c 4 "${PING_TARGET}" | tail -1 | awk '{print $4}' | cut -d '/' -f 2)
  if [[ -z "${PING}" ]]; then
    STATUS="down"
    MSG="no ping response"
    PING="-1"
  fi
else
  STATUS="down"
  MSG="disconnected"
  PING="0"
fi

# Push the result to the monitoring webhook and capture the response
RESPONSE=$(curl -s -G "${WEBHOOK_URL}" \
  --data-urlencode "status=${STATUS}" \
  --data-urlencode "msg=${MSG}" \
  --data-urlencode "ping=${PING}")

# Report what was sent, plus the webhook's response
echo "Status: ${STATUS}"
echo "Message: ${MSG}"
echo "Ping: ${PING}"
echo "Webhook Response: ${RESPONSE}"
