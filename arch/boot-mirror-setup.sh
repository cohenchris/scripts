#!/bin/bash

# User must run as root
if [[ "$(id -u)" -ne 0 ]]; then
    echo "This script must be run as root" 
    exit 1
fi

# Ask for pool name to work on
zpool list
echo
read -p "Please type the name of the root pool: " ZFS_ROOT_POOL_NAME

# Confirm pool choice
echo
zpool status ${ZFS_ROOT_POOL_NAME}
echo

read -p "Is this the root pool? (y/N) " yn

case $yn in
  [Yy]* ) ;;
  *     ) exit;;
esac

# Get this script's directory
OS_SCRIPTS_DIR=$(dirname "$(realpath "$0")")

echo
echo "Creating new pacman systemd hook..."

mkdir -p /etc/pacman.d/hooks/
cat <<EOF > /etc/pacman.d/hooks/100-systemd-boot.hook
[Trigger]
Type = Package
Operation = Upgrade
Target = systemd

[Action]
Description = update systemd-boot
When = PostTransaction
Exec = ${OS_SCRIPTS_DIR}/boot-mirror.sh ${ZFS_ROOT_POOL_NAME}
EOF

echo
echo "EFI boot partitions will now be synced when systemd is updated!"
