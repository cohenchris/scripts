#!/usr/bin/env bash

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


ARCH_ENV_SETUP_DIR=$(dirname "$(realpath "$0")")/arch-env-setup


# Install glances dependencies and service
echo "Installing Glance webserver service..."
sudo -u "${USERNAME}" paru -Sy --noconfirm glances python-fastapi uvicorn python-jinja-time hddtemp python-docker python-matplotlib python-netifaces2
cp "${ARCH_ENV_SETUP_DIR}"/glances.service /etc/systemd/system


# Install network UPS tools and service
echo
echo "Installing and configuring Network UPS tools..."
sudo -u "${USERNAME}" paru -Sy --noconfirm nut
cp "${ARCH_ENV_SETUP_DIR}"/nut/* /etc/nut
chown -R root:nut /etc/nut/*
chmod 640 /etc/nut/*


# Reload systemd, then enable + start services
systemctl daemon-reload
systemctl enable --now glances.service
upsdrvctl start
systemctl enable --now nut.target nut-driver.target nut-driver-enumerator.service


echo
echo "Setup complete!"
