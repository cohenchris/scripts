#!/bin/bash

if [[ "$(id -u)" -ne 0 ]]; then
    echo "This script must be run as root" 
    exit 1
fi

SCRIPTS_BASE_DIR="$(dirname "$(realpath "$0")")/../../../"

# Install glances dependencies and service
echo "Installing Glance webserver service..."
paru -Sy --noconfirm python-fastapi uvicorn python-jinja-time
sudo cp glances.service /etc/systemd/system

# Install nvidia GPU power savings dependencies and service
echo
echo "Installing Nvidia GPU power savings service..."
paru -Sy --noconfirm nvidia-lts nvidia-container-toolkit python-nvidia-ml-py
sudo cp nvidia-gpu-power-savings.service /etc/systemd/system

# Install network UPS tools and service
echo
echo "Installing and configuring Network UPS tools..."
paru -Sy --noconfirm nut
sudo cp ./nut/* /etc/nut
sudo chown -R root:nut /etc/nut/*
sudo chmod 640 /etc/nut/*

# Edit and install nextcloud AI task processing service
echo
echo "Installing and configuring Nextcloud AI Task Processing Workers..."
sudo cp ./nextcloud-ai-worker@.service /etc/systemd/system
sudo sed -i "s|<scriptsdir>|${SCRIPTS_BASE_DIR}|g" /etc/systemd/system/nextcloud-ai-worker@.service


# Reload systemd, then enable + start services
sudo systemctl daemon-reload
sudo systemctl enable --now nvidia-gpu-power-savings.service
sudo systemctl enable --now glances.service
sudo upsdrvctl start
sudo systemctl enable --now nut.target nut-driver.target nut-driver-enumerator.service
for i in {1..4}; do sudo systemctl enable --now nextcloud-ai-worker@$i.service; done
