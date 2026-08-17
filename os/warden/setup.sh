#!/usr/bin/env bash

# Bail if attempting to substitute an unset variable
set -u

WORKING_DIR=$(dirname "$(realpath "$0")")

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


# Install and configure Network UPS Tools, then start monitoring the UPS
function setup_nut()
{
  echo "Installing Network UPS Tools..."
  sudo -u "${USERNAME}" paru -Sy --noconfirm nut

  echo "Configuring Network UPS Tools..."
  cp "${WORKING_DIR}"/nut/* /etc/nut
  chown -R root:nut /etc/nut/*
  chmod 640 /etc/nut/*

  echo "Starting Network UPS Tools services..."
  upsdrvctl start
  systemctl enable --now nut.target nut-driver.target nut-driver-enumerator.service
}


# Install Docker, then deploy Uptime Kuma via its compose file
function setup_uptime_kuma()
{
  echo "Installing Docker..."
  sudo -u "${USERNAME}" paru -Sy --noconfirm docker docker-compose
  systemctl enable --now docker.service
  usermod -aG docker "${USERNAME}"

  echo "Deploying Uptime Kuma..."
  UPTIME_KUMA_DIR="/home/${USERNAME}/uptimekuma"
  sudo -u "${USERNAME}" mkdir -p "${UPTIME_KUMA_DIR}"
  cp "${WORKING_DIR}"/uptimekuma-compose.yaml "${UPTIME_KUMA_DIR}"/docker-compose.yml
  chown "${USERNAME}":"${USERNAME}" "${UPTIME_KUMA_DIR}"/docker-compose.yaml

  cd "${UPTIME_KUMA_DIR}"
  sudo -u "${USERNAME}" docker compose up -d
}


setup_nut
setup_uptime_kuma


echo
echo "Setup complete!"
