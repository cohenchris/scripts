#!/usr/bin/env bash

# Bail if attempting to substitute an unset variable
set -eu

WORKING_DIR=$(dirname "$(realpath "$0")")
WARDEN_DIR="/home/${USER}/warden"

if [[ "$(id -u)" -eq 0 ]]; then
    echo "This script must NOT be run as root"
    exit 1
fi

# Install Docker, then deploy the Network UPS Tools + Uptime Kuma stack via its compose file
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

function deploy_docker_containers() {
  echo "Deploying Docker Containers..."
  sudo -u "${USER}" mkdir -p "${WARDEN_DIR}"

  # Copy the warden folder, minus setup.sh and README.md (skip if already running
  # from the destination). dotglob so hidden files like .env are included.
  if [[ "$(realpath "${WORKING_DIR}")" != "$(realpath "${WARDEN_DIR}")" ]]; then
    shopt -s dotglob
    local f
    for f in "${WORKING_DIR}"/*; do
      case "$(basename "${f}")" in
        setup.sh|README.md) continue ;;
      esac
      cp -a "${f}" "${WARDEN_DIR}"/
    done
    shopt -u dotglob
  fi

  # Seed .env from sample.env only if one wasn't copied over or already present
  if [[ ! -f "${WARDEN_DIR}"/.env ]]; then
    cp "${WARDEN_DIR}"/sample.env "${WARDEN_DIR}"/.env
    echo "NOTE: ${WARDEN_DIR}/.env was created from sample.env - update it with your UPS settings before the stack will work correctly."
  fi

  # Same for the shutdown script's config
  if [[ ! -f "${WARDEN_DIR}"/.shutdown-network.conf ]]; then
    cp "${WARDEN_DIR}"/sample.shutdown-network.conf "${WARDEN_DIR}"/.shutdown-network.conf
    echo "NOTE: ${WARDEN_DIR}/.shutdown-network.conf was created from sample.shutdown-network.conf - update it with your Signal settings and shutdown targets."
  fi

  chown -R "${USER}":"${USER}" "${WARDEN_DIR}"

  cd "${WARDEN_DIR}"
  sudo -u "${USER}" docker compose up -d
}


# Install host upsmon and point it at the containerized upsd, with
# shutdown-network.sh as its SHUTDOWNCMD. The container only runs upsd - this is
# what actually watches the UPS and triggers the network shutdown.
function configure_upsmon()
{
  echo "Configuring upsmon..."
  local shutdown_script="${WARDEN_DIR}/shutdown-network.sh"
  # Published by the nut container in docker-compose.yml
  local nut_port=3493

  # Read the upsd credentials from .env in a subshell, so nothing else in it
  # leaks into this script
  local ups_user ups_password
  ups_user=$(source "${WARDEN_DIR}"/.env && printf '%s' "${UPS_USER:-}")
  ups_password=$(source "${WARDEN_DIR}"/.env && printf '%s' "${UPS_PASSWORD:-}")

  if [[ -z "${ups_user}" || -z "${ups_password}" ]]; then
    echo "WARNING: UPS_USER/UPS_PASSWORD are not set in ${WARDEN_DIR}/.env - skipping upsmon setup. Set them and re-run."
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
SHUTDOWNCMD "${shutdown_script}"
EOF
  # Contains the upsd password
  sudo chown root:nut /etc/nut/upsmon.conf
  sudo chmod 640 /etc/nut/upsmon.conf

  sudo systemctl enable nut-monitor.service
  sudo systemctl restart nut-monitor.service

  # The container may still be starting, so only warn
  if ! upsc "ups@localhost:${nut_port}" ups.status > /dev/null 2>&1; then
    echo "WARNING: could not reach upsd at localhost:${nut_port} yet - check 'docker compose ps' and 'journalctl -u nut-monitor'"
  fi
}


install_docker
deploy_docker_containers
configure_upsmon


echo
echo "Setup complete!"
