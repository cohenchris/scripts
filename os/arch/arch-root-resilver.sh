#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e
# Bail if attempting to substitute an unset variable
set -u

# User must run as root
if [[ "$(id -u)" -ne 0 ]]; then
    echo "This script must be run as root" 
    exit 1
fi


# Name of the ZFS pool
ZFS_POOL_NAME=""

# Existing good device in the ZFS pool
ZFS_GOOD_DEVICE=""
ZFS_GOOD_DEVICE_EFI_PARTITION=""
ZFS_GOOD_DEVICE_ZFS_PARTITION=""

# Failed device in the ZFS pool
ZFS_BAD_DEVICE_GUID=""

# Replacment for failed device
ZFS_REPLACEMENT_DEVICE=""
ZFS_REPLACEMENT_DEVICE_EFI_PARTITION=""
ZFS_REPLACEMENT_DEVICE_ZFS_PARTITION=""


function install_dependencies()
{
  # Enable ZFS kernel modules
  modprobe zfs

  if [ $? -ne 0 ]; then
    echo "ZFS kernel module not found, cannot continue."
    exit
  fi

  # Install gptfdisk if not installed
  if ! paru -Q gptfdisk &>/dev/null; then
    paru -Syu gptfdisk
  fi
}

function get_drive_information()
{
  echo
  echo "########################################"
  echo "#           ***WARNING***              #"
  echo "#    THIS SCRIPT WILL RESILVER YOUR    #"
  echo "#    ZFS ROOT POOL ON THE SPECIFIED    #"
  echo "#  DEVICE. MAKE ABSOLUTELY SURE THAT   #"
  echo "#    THE DEVICE NAME IS CORRECT OR     #"
  echo "#   YOU RISK CATASTROPHIC DATA LOSS.   #"
  echo "########################################"

  # Ask for pool name to work on
  zpool list
  echo
  read -p "Please select the name of the desired target pool: " ZFS_POOL_NAME

  # Confirm pool choice
  echo
  zpool status "${ZFS_POOL_NAME}"
  echo

  read -p "Is this pool choice correct? (y/N) " yn

  case "${yn}" in
    [Yy]* ) ;;
    *     ) exit;;
  esac

  # Ask for device name to resilver
  fdisk -l
  echo
  read -p "Enter target device to resilver (in the format /dev/sdX): " ZFS_REPLACEMENT_DEVICE

  # Confirm device choice
  echo
  fdisk -l "${ZFS_REPLACEMENT_DEVICE}"
  echo

  read -p "Is this device choice correct? (y/N) " yn

  case "${yn}" in
    [Yy]* ) ;;
    *     ) exit;;
  esac
}

function find_good_device_paths()
{
  # Existing good device
  ZFS_GOOD_DEVICE_EFI_PARTITION=$(findmnt -no SOURCE /boot)
  ZFS_GOOD_DEVICE_ZFS_PARTITION=$(zpool status -P "${ZFS_POOL_NAME}" | awk '/ONLINE/ {print $1}')
  ZFS_GOOD_DEVICE=$(lsblk -no PKNAME "${ZFS_GOOD_DEVICE_ZFS_PARTITION}" | xargs -I{} echo "/dev/{}")

  echo "Auto-detected good ZFS device to clone"
  echo
  echo "Device name: ${ZFS_GOOD_DEVICE}"
  echo "EFI partition: ${ZFS_GOOD_DEVICE_EFI_PARTITION}"
  echo "ZFS partition: ${ZFS_GOOD_DEVICE_ZFS_PARTITION}"
  echo
  read -p "Does this look correct? (y/N) " yn

  case "${yn}" in
    [Yy]* ) ;;
    *     ) exit;;
  esac
}

function clone_partitions()
{
  echo "Cloning partition table from old device to new device..."

  echo -e "\nRunning the following:"
  echo -e "\t# Clone partition table from old device to new device"
  echo -e "\tsgdisk --replicate "${ZFS_REPLACEMENT_DEVICE}" "${ZFS_GOOD_DEVICE}""

  echo -e "\t# Randomize GUIDs on the new disk"
  echo -e "\tsgdisk -G "${ZFS_REPLACEMENT_DEVICE}""

  echo -e "\t# Verify the partition table"
  echo -e "\tsgdisk -p "${ZFS_REPLACEMENT_DEVICE}"\n"

  read -p "Does this look correct? (y/N) " yn

  case "${yn}" in
    [Yy]* ) ;;
    *     ) exit;;
  esac

  # Clone partition table from old device to new device
  sgdisk --replicate "${ZFS_REPLACEMENT_DEVICE}" "${ZFS_GOOD_DEVICE}"

  # Randomize GUIDs on the new disk
  sgdisk -G "${ZFS_REPLACEMENT_DEVICE}"

  # Verify the partition table
  sgdisk -p "${ZFS_REPLACEMENT_DEVICE}"

  # Create boot filesystem for new device
  mkfs.vfat "${ZFS_REPLACEMENT_DEVICE_EFI_PARTITION}"
}

find_new_device_paths()
{
  # New replacement device
  ZFS_REPLACEMENT_DEVICE_EFI_PARTITION=$(lsblk -rno PATH,PARTTYPE "${ZFS_REPLACEMENT_DEVICE}" | awk '$2 ~ /c12a7328-f81f-11d2-ba4b-00a0c93ec93b/ {print $1}')
  ZFS_REPLACEMENT_DEVICE_ZFS_PARTITION=$(lsblk -rno PATH,PARTTYPE "${ZFS_REPLACEMENT_DEVICE}" | awk '$2 ~ /6a85cf4d-1dd2-11b2-99a6-080020736631/ {print $1}')

  # Convert ZFS partition to the globally unique /dev/disk/by-id device name
  for dev_by_id in /dev/disk/by-id/*; do
    if [[ "$(readlink -f "$dev_by_id")" == "$(readlink -f "${ZFS_REPLACEMENT_DEVICE_ZFS_PARTITION}")" ]]; then
      ZFS_REPLACEMENT_DEVICE_ZFS_PARTITION="${dev_by_id}"
      break
    fi
  done

  echo "Please confirm new replacement device details:"
  echo
  echo "Device name: ${ZFS_REPLACEMENT_DEVICE}"
  echo "EFI partition: ${ZFS_REPLACEMENT_DEVICE_EFI_PARTITION}"
  echo "ZFS partition: ${ZFS_REPLACEMENT_DEVICE_ZFS_PARTITION}"
  echo
  read -p "Does this look correct? (y/N) " yn

  case "${yn}" in
    [Yy]* ) ;;
    *     ) exit;;
  esac
}

function summarize_changes()
{
  # Find bad device
  ZFS_BAD_DEVICE_GUID="$(zpool status "${ZFS_POOL_NAME}" | awk '/UNAVAIL/ {print $1}')"

  # Have user verify settings
  echo
  echo "Please look over the following settings and confirm correctness:"
  echo

  zpool status "${ZFS_POOL_NAME}"

  echo
  echo "---------- Surviving ZFS device to replicate ----------"
  echo "Device name: ${ZFS_GOOD_DEVICE}"
  echo "EFI partition: ${ZFS_GOOD_DEVICE_EFI_PARTITION}"
  echo "ZFS partition: ${ZFS_GOOD_DEVICE_ZFS_PARTITION}"

  echo
  echo "---------- Target device to resilver ----------"
  echo "Device name: ${ZFS_REPLACEMENT_DEVICE}"
  echo "EFI partition: ${ZFS_REPLACEMENT_DEVICE_EFI_PARTITION}"
  echo "ZFS partition: ${ZFS_REPLACEMENT_DEVICE_ZFS_PARTITION}"

  echo
  echo "---------- Unavailable ZFS drive to replace ----------"
  echo "GUID: ${ZFS_BAD_DEVICE_GUID}"

  echo
  echo "---------- STEPS TO BE TAKEN ----------"
  echo "Restore boot partition:"
  echo -e "\tdd if=${ZFS_GOOD_DEVICE_EFI_PARTITION} of=${ZFS_REPLACEMENT_DEVICE_EFI_PARTITION}"
  echo
  echo "Replace bad device with replacement device:"
  echo -e "\tzfs replace ${ZFS_POOL_NAME} ${ZFS_BAD_DEVICE_GUID} ${ZFS_REPLACEMENT_DEVICE_ZFS_PARTITION}"

  echo
  read -p "Does this look correct? (y/N) " yn

  case "${yn}" in
    [Yy]* ) ;;
    *     ) exit;;
  esac
}

function replace_failed_drive()
{
  ############################
  # CLONE EFI BOOT PARTITION #
  ############################
  echo
  echo "Cloning EFI boot partition on new drive..."
  # Unmount existing drive's EFI boot partition and sync to flush all changes to disk
  umount /boot
  sync
  # Use dd to copy existing drive's EFI boot partition to new drive's EFI boot partition
  dd if="${ZFS_GOOD_DEVICE_EFI_PARTITION}" of="${ZFS_REPLACEMENT_DEVICE_EFI_PARTITION}" status=progress
  mount "${ZFS_GOOD_DEVICE_EFI_PARTITION}" /boot

  # Install bootloader on new drive
  mkdir -p /replacement_boot
  mount "${ZFS_REPLACEMENT_DEVICE_EFI_PARTITION}" /replacement_boot
  bootctl --path=/replacement_boot install
  umount /replacement_boot
  rm -r /replacement_boot

  ##########################
  # RESILVER ZFS PARTITION #
  ##########################
  echo
  echo "Resilvering ZFS partition on new drive..."
  zpool replace "${ZFS_POOL_NAME}" "${ZFS_BAD_DEVICE_GUID}" "${ZFS_REPLACEMENT_DEVICE_ZFS_PARTITION}"

  echo
  echo "Done! Please wait for resilver to finish..."
  zpool status
}


install_dependencies
get_drive_information
find_good_device_paths
clone_partitions
find_new_device_paths
summarize_changes
replace_failed_drive
