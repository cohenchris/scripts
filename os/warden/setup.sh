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


# Install Docker, then deploy the Network UPS Tools + Uptime Kuma stack via its compose file
function setup_warden_stack()
{
  echo "Installing Docker..."
  sudo -u "${USERNAME}" paru -Sy --noconfirm docker docker-compose
  systemctl enable --now docker.service
  usermod -aG docker "${USERNAME}"

  echo "Deploying Network UPS Tools + Uptime Kuma..."
  WARDEN_DIR="/home/${USERNAME}/warden"
  sudo -u "${USERNAME}" mkdir -p "${WARDEN_DIR}"
  cp "${WORKING_DIR}"/docker-compose.yml "${WARDEN_DIR}"/docker-compose.yml
  cp "${WORKING_DIR}"/sample.env "${WARDEN_DIR}"/.env
  chown "${USERNAME}":"${USERNAME}" "${WARDEN_DIR}"/docker-compose.yml "${WARDEN_DIR}"/.env

  echo "NOTE: ${WARDEN_DIR}/.env was created from sample.env - update it with your UPS settings before the stack will work correctly."

  cd "${WARDEN_DIR}"
  sudo -u "${USERNAME}" docker compose up -d
}


setup_warden_stack


echo
echo "Setup complete!"
