#!/usr/bin/env bash

if [[ "$(id -u)" -ne 0 ]]; then
    echo "This script must be run as root" 
    exit 1
fi

SCRIPTS_BASE_DIR=$(realpath "$(dirname "$(realpath "$0")")/../../..")

# Install crontab
echo "Installing OpenWRT backup cron job..."
cat <<EOF | crontab -
PATH=/usr/sbin:/usr/bin:/sbin:/bin:${SCRIPTS_BASE_DIR}/bin

# Backup config every Sunday at 3 am
0 3 * * 0 (${SCRIPTS_BASE_DIR}/backup/openwrt.sh)
EOF

# Point system DNS to router over localhost
echo "Installing custom DNS settings pointing to router..."
cat <<EOF > /etc/resolv.conf
search lan
nameserver 10.24.0.1
nameserver ::1
EOF

# Set up email notifications
cd "${SCRIPTS_BASE_DIR}/os/services/email"
./setup.sh

echo
echo "Setup complete!"
