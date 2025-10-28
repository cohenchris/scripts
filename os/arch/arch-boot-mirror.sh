#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e
# Bail if attempting to substitute an unset variable
set -u

# User must run as root
if [[ "$(id -u)" -ne 0 ]]; then
    echo "This script must be run as root" 
    exit
fi



# boot_mirror(zfs_root_pool)
#   zfs_root_pool - name of the ZFS root pool whose EFI boot partitions we should mirror.
#
# Given a ZFS root pool name, determine which drive's EFI boot partition is mounted at /boot, then mirror that partition to the other root pool device's partition.
function boot_mirror()
{
  ZFS_ROOT_POOL="$1"

  if [ -z "${ZFS_ROOT_POOL}" ]; then
    echo "ERROR: must provide a ZFS root pool name."
    exit
  fi

  # Take output of command and feed into array
  ZFS_ROOT_POOL_DEVICES=($(zpool list -v "${ZFS_ROOT_POOL}" -H | awk '$1 !~ /(mirror|raidz|spare|log|cache|special)-?[0-9]*/ {print $1}' | tail -n +2))

  if [ "${#ZFS_ROOT_POOL_DEVICES[@]}" -ne 2 ]; then
    echo "ERROR: this pool is not a mirrored pool with 2 devices."
    exit
  fi

  # /dev/sdX1 format
  PRIMARY_BOOT_PARTITION=$(findmnt /boot -n -o SOURCE)

  # Ensure there is a drive mounted at /boot
  if [ -z "${PRIMARY_BOOT_PARTITION}" ]; then
    echo "ERROR: /boot is not mounted."
    exit 1
  fi

  # translate all ZFS root pool device IDs to corresponding /dev/sdX1 format
  for i in "${!ZFS_ROOT_POOL_DEVICES[@]}"; do
    # Translate device ID to base /dev/sdX device name
    ZFS_ROOT_POOL_DEVICES[i]="/dev/$(lsblk -no PKNAME $(readlink -f "/dev/disk/by-id/${ZFS_ROOT_POOL_DEVICES[i]}"))"
    # Get first partition (EFI boot partition) of the device
    ZFS_ROOT_POOL_DEVICES[i]=$(lsblk -nr -o NAME "${ZFS_ROOT_POOL_DEVICES[i]}" | awk 'NR==2 {print "/dev/"$1}')
  done

  # The device mounted at /boot must be in the ZFS pool we're working on
  if [[ ! "${ZFS_ROOT_POOL_DEVICES[@]}" =~ "${PRIMARY_BOOT_PARTITION}" ]]; then
    echo "ERROR: this pool does not contain the device mounted at /boot."
    exit
  fi

  # Set SECONDARY_BOOT_PARTITION equal to the entry in ZFS_ROOT_POOL_DEVICES which is not equal to PRIMARY_BOOT_PARTITION
  for ZFS_DEVICE in "${ZFS_ROOT_POOL_DEVICES[@]}"; do
    if [[ "${ZFS_DEVICE}" != "${PRIMARY_BOOT_PARTITION}" ]]; then
      SECONDARY_BOOT_PARTITION="${ZFS_DEVICE}"
      break
    fi
  done

  # Sanity check to ensure we've found a secondary EFI boot partition
  if [ -z "${SECONDARY_BOOT_PARTITION}" ]; then
    echo "ERROR: Unable to find secondary EFI boot partition."
    exit
  fi

  echo "Primary: ${PRIMARY_BOOT_PARTITION}"
  echo "Secondary: ${SECONDARY_BOOT_PARTITION}"

  # Update primary EFI boot partition using bootctl
  echo
  echo "Updating EFI boot partition on primary drive..."
  bootctl update

  # Clone primary EFI boot partition to secondary boot partition
  echo
  echo "Cloning primary drive EFI boot partition to secondary drive EFI boot partition..."
  umount /boot
  sync
  dd if="${PRIMARY_BOOT_PARTITION}" of="${SECONDARY_BOOT_PARTITION}" status=progress
  mount "${PRIMARY_BOOT_PARTITION}" /boot

  echo
  echo "Done!"
}

boot_mirror "$1"
