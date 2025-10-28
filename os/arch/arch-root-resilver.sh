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
read -p "Enter target device to resilver (in the format /dev/sdX): " ZFS_RESILVER_DEV_NAME

# Confirm device choice
echo
fdisk -l "${ZFS_RESILVER_DEV_NAME}"
echo

read -p "Is this device choice correct? (y/N) " yn

case "${yn}" in
  [Yy]* ) ;;
  *     ) exit;;
esac

######################
# DRIVE PARTITIONING #
######################
# Destroy all existing partitions
sgdisk --zap-all "${ZFS_RESILVER_DEV_NAME}"
# 
# # Create boot partitions
sgdisk -n1:0:+4G -t1:ef00 "${ZFS_RESILVER_DEV_NAME}"
# 
# # Create ZFS partitions
sgdisk -n2:0:0 -t2:bf00 "${ZFS_RESILVER_DEV_NAME}"
# 
# # Create boot filesystem for both drives
mkfs.vfat "${ZFS_RESILVER_DEV_P1_NAME}"

######################
# SUMMARY OF CHANGES #
######################
# Have user verify settings
echo
echo "Please look over the following settings and confirm correctness:"
echo

zpool status

# Replicate source
ZFS_EXISTING_DEV_P2_ID=$(zpool status "${ZFS_POOL_NAME}" | awk '/ONLINE/ {print $1}')
ZFS_EXISTING_DEV_NAME=$(readlink -f "/dev/disk/by-id/${ZFS_EXISTING_DEV_P2_ID}")
ZFS_EXISTING_DEV_NAME="/dev/$(lsblk -no PKNAME "${ZFS_EXISTING_DEV_NAME}")"
ZFS_EXISTING_DEV_P1_NAME=$(lsblk -nr -o NAME "${ZFS_EXISTING_DEV_NAME}" | awk 'NR==2 {print "/dev/"$1}')
ZFS_EXISTING_DEV_P2_NAME=$(lsblk -nr -o NAME "${ZFS_EXISTING_DEV_NAME}" | awk 'NR==3 {print "/dev/"$1}')
echo
echo "---------- Surviving ZFS device to replicate ----------"
echo "Device name: ${ZFS_EXISTING_DEV_NAME}"
echo "Boot partition: ${ZFS_EXISTING_DEV_P1_NAME}"
echo "ZFS partition: ${ZFS_EXISTING_DEV_P2_NAME}"
echo "ZFS partition ID: ${ZFS_EXISTING_DEV_P2_ID}"

# Replicate target
ZFS_RESILVER_DEV_P1_NAME=$(lsblk -nr -o NAME "${ZFS_RESILVER_DEV_NAME}" | awk 'NR==2 {print "/dev/"$1}')
ZFS_RESILVER_DEV_P2_NAME=$(lsblk -nr -o NAME "${ZFS_RESILVER_DEV_NAME}" | awk 'NR==3 {print "/dev/"$1}')
ZFS_RESILVER_DEV_P2_ID=$(ls -l /dev/disk/by-id/ | grep "$(basename $(readlink -f "${ZFS_RESILVER_DEV_P2_NAME}"))" | awk '{print "/dev/disk/by-id/" $9}')
echo
echo "---------- Target device to resilver ----------"
echo "Device name: ${ZFS_RESILVER_DEV_NAME}"
echo "Boot partition: ${ZFS_RESILVER_DEV_P1_NAME}"
echo "ZFS partition: ${ZFS_RESILVER_DEV_P2_NAME}"
echo "ZFS partition ID: ${ZFS_RESILVER_DEV_P2_ID}"

# ZFS device GUID to replace
ZFS_DEV_TO_REPLACE_GUID=$(zpool status "${ZFS_POOL_NAME}" | awk '/UNAVAIL/ {print $1}')
echo
echo "---------- Unavailable ZFS drive to replace ----------"
echo "GUID: ${ZFS_DEV_TO_REPLACE_GUID}"

echo
echo "---------- STEPS TO BE TAKEN ----------"
echo "Restore boot partition:"
echo -e "\tdd if=${ZFS_EXISTING_DEV_P1_NAME} of=${ZFS_RESILVER_DEV_P1_NAME}"
echo "Resilver ZFS partition:"
echo -e "\tzfs replace ${ZFS_POOL_NAME} ${ZFS_DEV_TO_REPLACE_GUID} ${ZFS_RESILVER_DEV_P2_NAME}"

echo
read -p "Does this look correct? (y/N) " yn

case "${yn}" in
  [Yy]* ) ;;
  *     ) exit;;
esac


############################
# CLONE EFI BOOT PARTITION #
############################
echo
echo "Cloning EFI boot partition on new drive..."
# Unmount existing drive's EFI boot partition and sync to flush all changes to disk
umount /boot
sync
# Use dd to copy existing drive's EFI boot partition to new drive's EFI boot partition
dd if="${ZFS_EXISTING_DEV_P1_NAME}" of="${ZFS_RESILVER_DEV_P1_NAME}" status=progress
mount "${ZFS_EXISTING_DEV_P1_NAME}" /boot

echo
echo "Updating systemd.mount file for EFI boot partition..."
# Create systemd.mount file for boot partition on main drive
BOOT_DRIVE_UUID=$(findmnt -no UUID /boot)
cat <<EOF > /etc/systemd/system/boot.mount
[Unit]
Description=Mount Boot Partition
Wants=local-fs-pre.target
Before=local-fs.target

[Mount]
What=UUID=${BOOT_DRIVE_UUID}
Where=/boot
Type=vfat
Options=defaults,noatime

[Install]
WantedBy=multi-user.target
EOF
  
# Enable systemd auto-mounting for boot drive by default
systemctl enable boot.mount


##########################
# RESILVER ZFS PARTITION #
##########################
echo
echo "Resilvering ZFS partition on new drive..."
zpool replace "${ZFS_POOL_NAME}" "${ZFS_DEV_TO_REPLACE_GUID}" "${ZFS_RESILVER_DEV_P2_ID}"

echo
echo "Done! Please wait for resilver to finish..."
zpool status
