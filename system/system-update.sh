#!/usr/bin/env bash

# Location of this scripts git repository

WORKING_DIR=$(dirname "$(realpath "$0")")
source "${WORKING_DIR}/.env"

SCRIPTS_DIR=$(dirname "${WORKING_DIR}")

function update_arch()
{
  # Synchronizes all packages from repositories
  # Downloads fresh package database from the servers
  # Upgrades all outdated packages to their latest versions
  paru -Syu --noconfirm

  # Clear all package cache
  paru -Scc --noconfirm

  # Docker maintenance if applicable
  if [[ -z "${DOCKER_STACKS_HOME_DIR}" ]]; then
    echo 'WARNING: variable ${DOCKER_STACKS_HOME_DIR} is not set in the environment, no docker maintenance will be performed.'
  else
    require var "${DOCKER_STACKS_HOME_DIR}"
    require dir "${DOCKER_STACKS_HOME_DIR}"

    # Update and restart all docker containers in docker-compose.yml
    cd "${DOCKER_STACKS_HOME_DIR}"
    ./stacks.sh update
    ./stacks.sh up

    # Clean docker environment
    docker system prune -a -f
  fi

  # Mirror EFI boot partitions
  sudo "${SCRIPTS_DIR}/os/arch/arch-boot-mirror.sh" zroot
}

function update_ubuntu()
{
  sudo apt-get update -y
  sudo apt-get upgrade -y
  sudo apt-get autoremove -y
}

function update_openwrt()
{
  opkg update

  echo "!!!!!!!!!! WARNING !!!!!!!!!!"
  echo "About to perform a system upgrade!"
  echo "This will install the newest firmware version and reboot the device."
  echo "Some settings will be lost, you will have to re-configure certain settings."
  read -p "Would you like to continue? " yn

  case ${yn} in
    [Yy]* ) ;;
    *     ) exit;;
  esac

  # Upgrade system
  owut upgrade
}

function update_opnsense()
{
  # Update base system
  sudo opnsense-update

  # Update plugins/packages
  sudo opnsense-update -p
  sudo pkg update
  sudo pkg upgrade
}


# Determine which client is running this script
# Ubuntu-based Linux
if command -v apt &> /dev/null; then
  update_ubuntu

# OpenWRT
elif command -v opkg &> /dev/null; then
  update_openwrt

# Arch Linux Lab
elif command -v pacman &> /dev/null; then
  update_arch

# OPNSense (FreeBSD)
elif command -v pkg &> /dev/null; then
  update_opnsense

# Unknown system
else
  echo "Unable to auto-detect system, cannot update..."
  exit 1
fi

