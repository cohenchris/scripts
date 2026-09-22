#!/usr/bin/env bash

# Bail if attempting to substitute an unset variable
set -u

WORKING_DIR=$(dirname "$(realpath "$0")")

if [[ "$(id -u)" -eq 0 ]]; then
    echo "This script must NOT be run as root"
    exit 1
fi

# Install Docker, then deploy the Network UPS Tools + Uptime Kuma stack via its compose file
function setup_warden_stack()
{
  echo "Installing Docker..."
  sudo apt-get docker docker-compose
  sudo systemctl enable --now docker.service
  sudo usermod -aG docker "${USER}"

  echo "Deploying Docker Containers..."
  WARDEN_DIR="/home/${USER}/warden"
  sudo -u "${USER}" mkdir -p "${WARDEN_DIR}"
  cp "${WORKING_DIR}"/docker-compose.yml "${WARDEN_DIR}"/docker-compose.yml
  cp "${WORKING_DIR}"/sample.env "${WARDEN_DIR}"/.env
  chown "${USER}":"${USER}" "${WARDEN_DIR}"/docker-compose.yml "${WARDEN_DIR}"/.env

  echo "NOTE: ${WARDEN_DIR}/.env was created from sample.env - update it with your UPS settings before the stack will work correctly."

  cd "${WARDEN_DIR}"
  sudo -u "${USER}" docker compose up -d
}


setup_warden_stack


echo
echo "Setup complete!"
