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

  chown -R "${USER}":"${USER}" "${WARDEN_DIR}"

  cd "${WARDEN_DIR}"
  sudo -u "${USER}" docker compose up -d
}


install_docker
deploy_docker_containers


echo
echo "Setup complete!"
