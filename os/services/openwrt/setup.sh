#!/bin/bash

if [[ "$(id -u)" -ne 0 ]]; then
    echo "This script must be run as root" 
    exit 1
fi

SCRIPTS_BASE_DIR=$(realpath "$(dirname "$(realpath "$0")")/../../..")

# Install crontab
BACKUP_CRON_JOB="# Backup config every Sunday at 3 am\n0 3 * * 0 (${SCRIPTS_BASE_DIR}/backup/openwrt.sh)"

echo "Installing OpenWRT backup cron job..."
echo -e "${BACKUP_CRON_JOB}" | crontab -

# Point system DNS to router over localhost
echo "Installing custom DNS settings pointing to router..."
cat <<EOF > /etc/resolv.conf
search lan
nameserver 10.24.0.1
nameserver ::1
EOF

echo "Setup complete!
