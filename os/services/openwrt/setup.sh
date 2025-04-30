#!/bin/ash

# Install crontab
BACKUP_CRON_JOB="# Backup config every Sunday at 3 am\n0 3 * * 0 (/root/scripts/backup/openwrt.sh)"
echo -e "${BACKUP_CRON_JOB}" | crontab -

# Point system DNS to router over localhost
cat <<EOF > /etc/resolv.conf
search lan
nameserver 10.24.0.1
nameserver ::1
EOF
