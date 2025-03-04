#!/bin/bash

if [[ "$(id -u)" -ne 0 ]]; then
    echo "This script must be run as root" 
    exit 1
fi

SCRIPTS_BASE_DIR="$(dirname "$(realpath "$0")")/../../../"

# Install glances dependencies and service
echo "Installing Glance webserver service..."
paru -Sy --noconfirm python-fastapi uvicorn python-jinja-time
cp glances.service /etc/systemd/system

# Install nvidia GPU power savings dependencies and service
echo
echo "Installing Nvidia GPU power savings service..."
paru -Sy --noconfirm nvidia-lts nvidia-container-toolkit python-nvidia-ml-py
cp nvidia-gpu-power-savings.service /etc/systemd/system

# Install network UPS tools and service
echo
echo "Installing and configuring Network UPS tools..."
paru -Sy --noconfirm nut
cp ./nut/* /etc/nut
chown -R root:nut /etc/nut/*
chmod 640 /etc/nut/*

# Edit and install nextcloud AI task processing service
echo
echo "Installing and configuring Nextcloud AI Task Processing Workers..."
cp ./nextcloud-ai-worker@.service /etc/systemd/system
sed -i "s|<scriptsdir>|${SCRIPTS_BASE_DIR}|g" /etc/systemd/system/nextcloud-ai-worker@.service


# Reload systemd, then enable + start services
systemctl daemon-reload
systemctl enable --now nvidia-gpu-power-savings.service
systemctl enable --now glances.service
upsdrvctl start
systemctl enable --now nut.target nut-driver.target nut-driver-enumerator.service
for i in {1..4}; do systemctl enable --now nextcloud-ai-worker@$i.service; done

# Install msmtp
paru -Sy --noconfirm msmtp msmtp-mta

# SMTP Host URL
echo
read -p "Enter SMTP Host URL for your mailserver (no http:// or https://): " SMTP_HOST_URL 

# Email
echo
read -p "Enter your root email: " EMAIL_USERNAME

# Password
echo
read -s -p "Enter the password for ${EMAIL_USERNAME}: " EMAIL_PASSWORD

# Copy test config file to final location
MSMTPRC_PATH="/etc/msmtprc"
mkdir -p $(dirname ${MSMTPRC_PATH})
cp ./msmtprc ${MSMTPRC_PATH}

# Splice the required fields into the final config file
sed -i "s|<msmtp_host>|${SMTP_HOST_URL}|g" ${MSMTPRC_PATH}
sed -i "s|<msmtp_user>|${EMAIL_USERNAME}|g" ${MSMTPRC_PATH}
sed -i "s|<msmtp_password>|${EMAIL_PASSWORD}|g" ${MSMTPRC_PATH}

# Set proper permissions
echo
echo "Setting permissions for ${MSMTPRC_PATH}..."
chmod 600 ${MSMTPRC_PATH}

# Send test email
echo
echo "Test email!" | msmtp "${EMAIL_USERNAME}"

if [ $? -ne 0 ]; then
  echo
  echo "ERROR: MSMTP setup failed, manual intervention required."
  echo "Please check config file at \"${MSMTPRC_PATH}\""
else
  echo
  echo "MSMTP setup was successful!"
fi
