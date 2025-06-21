#!/bin/bash

if [[ "$(id -u)" -ne 0 ]]; then
    echo "This script must be run as root" 
    exit 1
fi

read -p "Enter your username: " USERNAME

if ! id "${USERNAME}" &>/dev/null; then
  echo "ERROR: User ${USERNAME} does not exist"
  exit 1
fi

read -p "Operate as user ${USERNAME}? (y/N) " yn

case "${yn}" in
  [Yy]* ) ;;
  *     ) exit;;
esac

SCRIPTS_BASE_DIR=$(realpath "$(dirname "$(realpath "$0")")/../../..")

# Install glances dependencies and service
echo "Installing Glance webserver service..."
sudo -u "${USERNAME}" paru -Sy --noconfirm glances python-fastapi uvicorn python-jinja-time hddtemp python-docker python-matplotlib python-netifaces2
cp glances.service /etc/systemd/system

# Install nvidia GPU power savings dependencies and service
echo
echo "Installing Nvidia GPU power savings service..."
sudo -u "${USERNAME}" paru -Sy --noconfirm nvidia-lts nvidia-container-toolkit python-nvidia-ml-py
cp nvidia-gpu-power-savings.service /etc/systemd/system

# Install network UPS tools and service
echo
echo "Installing and configuring Network UPS tools..."
sudo -u "${USERNAME}" paru -Sy --noconfirm nut
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

# Set up email notifications
cd "${SCRIPTS_BASE_DIR}/os/services/email"
./setup.sh

echo
echo "Setup complete!"
