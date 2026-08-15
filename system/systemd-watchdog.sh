#!/usr/bin/env bash

# Restarts the given systemd service if it is not currently active.

SERVICE="$1"

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
fi

if [ -z "${SERVICE}" ]; then
    echo "Usage: $0 <service>"
    exit 1
fi

if [ "$(systemctl show "${SERVICE}" --property=LoadState --value)" == "not-found" ]; then
    echo "Service ${SERVICE} does not exist."
    exit 1
fi

if systemctl is-active --quiet "${SERVICE}"; then
    echo "${SERVICE} is active, nothing to do."
    exit 0
fi

echo "${SERVICE} is not active, restarting..."
systemctl restart "${SERVICE}"

if systemctl is-active --quiet "${SERVICE}"; then
    echo "${SERVICE} restarted successfully."
else
    echo "Failed to restart ${SERVICE}."
    exit 1
fi
