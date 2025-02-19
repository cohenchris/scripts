#!/bin/bash

# Install glances dependencies and service
paru -Sy --noconfirm python-fastapi uvicorn python-jinja-time
sudo cp glances.service /etc/systemd/system

# Install nvidia GPU power savings dependencies and service
paru -Sy --noconfirm nvidia-lts nvidia-container-toolkit python-nvidia-ml-py
sudo cp nvidia-gpu-power-savings.service /etc/systemd/system

# Install network UPS tools and service
paru -Sy --noconfirm nut
sudo cp ./nut/*.conf /etc/nut
sudo chown -R root:nut /etc/nut/*
sudo chmod 640 /etc/nut/*


# Reload systemd, then enable + start services
sudo systemctl daemon-reload

sudo systemctl enable nvidia-gpu-power-savings.service
sudo systemctl start nvidia-gpu-power-savings.service

sudo systemctl enable glances.service
sudo systemctl start glances.service

sudo upsdrvctl start
sudo systemctl enable nut.target nut-driver.target nut-driver-enumerator.service
sudo systemctl start nut.target nut-driver.target nut-driver-enumerator.service
