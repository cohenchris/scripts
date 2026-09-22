#!/usr/bin/env bash

# Bail if attempting to substitute an unset variable
set -eu

WORKING_DIR=$(dirname "$(realpath "$0")")

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
  WARDEN_DIR="/home/${USER}/warden"
  sudo -u "${USER}" mkdir -p "${WARDEN_DIR}"
  cp "${WORKING_DIR}"/docker-compose.yml "${WARDEN_DIR}"/docker-compose.yml
  cp "${WORKING_DIR}"/sample.env "${WARDEN_DIR}"/.env
  chown "${USER}":"${USER}" "${WARDEN_DIR}"/docker-compose.yml "${WARDEN_DIR}"/.env

  echo "NOTE: ${WARDEN_DIR}/.env was created from sample.env - update it with your UPS settings before the stack will work correctly."

  cd "${WARDEN_DIR}"
  sudo -u "${USER}" docker compose up -d
}


install_docker
deploy_docker_containers


echo
echo "Setup complete!"
