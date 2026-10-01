#!/usr/bin/env bash

# Bail if attempting to substitute an unset variable
set -eu

WORKING_DIR=$(dirname "$(realpath "$0")")
# The compose stack is copied here; the shutdown script runs in place from this repo
DOCKER_DIR="/home/${USER}/docker"
SHUTDOWN_SCRIPT="${WORKING_DIR}/scripts/shutdown-network.sh"

if [[ "$(id -u)" -eq 0 ]]; then
    echo "This script must NOT be run as root"
    exit 1
fi

# Install Docker
function install_docker()
{
  echo "Installing Docker..."
  # Add Docker's official GPG key:
  sudo apt update
  sudo apt install ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  
  # Add the repository to Apt sources:
  sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
  
  sudo apt update

  # Add user to the docker group
  sudo groupadd docker
  sudo usermod -aG docker "${USER}"

  # Install Docker
  sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  # Start Docker service
  sudo systemctl enable docker
  sudo systemctl start docker

}

# Copy the compose stack into place. Creating .env and bringing the stack up
# are left to the user.
function copy_docker_folder()
{
  echo "Copying Docker Compose stack to ${DOCKER_DIR}..."
  mkdir -p "${DOCKER_DIR}"

  # Copy the whole docker/ folder, hidden files (like .env) included
  cp -a "${WORKING_DIR}"/docker/. "${DOCKER_DIR}"/
}


# Install host upsmon and point it at the containerized upsd, with
# shutdown-network.sh as its SHUTDOWNCMD. The container only runs upsd - this is
# what actually watches the UPS and triggers the network shutdown.
function configure_upsmon()
{
  echo "Configuring upsmon..."
  # Published by the nut container in docker-compose.yml
  local nut_port=3493

  # Read the upsd credentials from .env in a subshell, so nothing else in it
  # leaks into this script
  if [[ ! -f "${DOCKER_DIR}"/.env ]]; then
    echo "WARNING: ${DOCKER_DIR}/.env does not exist - skipping upsmon setup. Create it from sample.env and re-run."
    return 0
  fi

  local ups_user ups_password
  ups_user=$(source "${DOCKER_DIR}"/.env && printf '%s' "${UPS_USER:-}")
  ups_password=$(source "${DOCKER_DIR}"/.env && printf '%s' "${UPS_PASSWORD:-}")

  if [[ -z "${ups_user}" || -z "${ups_password}" ]]; then
    echo "WARNING: UPS_USER/UPS_PASSWORD are not set in ${DOCKER_DIR}/.env - skipping upsmon setup. Set them and re-run."
    return 0
  fi

  # Escape for a double-quoted NUT config value
  ups_password="${ups_password//\\/\\\\}"
  ups_password="${ups_password//\"/\\\"}"

  sudo apt install nut-client

  # Keep the stock config around the first time we overwrite it
  sudo cp -n /etc/nut/nut.conf /etc/nut/nut.conf.orig
  sudo cp -n /etc/nut/upsmon.conf /etc/nut/upsmon.conf.orig

  # upsd is in docker, so this host is only a network client
  echo "MODE=netclient" | sudo tee /etc/nut/nut.conf > /dev/null

  # upsmon runs SHUTDOWNCMD as root
  sudo tee /etc/nut/upsmon.conf > /dev/null <<EOF
MONITOR ups@localhost:${nut_port} 1 "${ups_user}" "${ups_password}" primary
MINSUPPLIES 1
SHUTDOWNCMD "${SHUTDOWN_SCRIPT}"
EOF
  # Contains the upsd password
  sudo chown root:nut /etc/nut/upsmon.conf
  sudo chmod 640 /etc/nut/upsmon.conf

  sudo systemctl enable nut-monitor.service
  sudo systemctl restart nut-monitor.service

  # The stack isn't brought up by this script, so only warn
  if ! upsc "ups@localhost:${nut_port}" ups.status > /dev/null 2>&1; then
    echo "WARNING: could not reach upsd at localhost:${nut_port} - bring the stack up with 'docker compose up -d' in ${DOCKER_DIR}, then check 'journalctl -u nut-monitor'"
  fi
}


install_docker
copy_docker_folder
configure_upsmon


echo
echo "Setup complete!"
