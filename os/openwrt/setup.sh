#!/usr/bin/env bash

if [[ "$(id -u)" -ne 0 ]]; then
    echo "This script must be run as root" 
    exit 1
fi

SCRIPTS_BASE_DIR=$(realpath "$(dirname "$(realpath "$0")")/../..")

# Install crontab
echo "Installing OpenWRT backup cron job..."
cat <<EOF | crontab -
PATH=/usr/sbin:/usr/bin:/sbin:/bin:${SCRIPTS_BASE_DIR}/bin

# Backup config every Sunday at 3 am
0 3 * * 0 (${SCRIPTS_BASE_DIR}/backup/openwrt.sh)
EOF

echo
echo "Setup complete!"
