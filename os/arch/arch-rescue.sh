#!/usr/bin/env bash


# Exit immediately if a command exits with a non-zero status
set -e
# Bail if attempting to substitute an unset variable
set -u


########## DEFINES ##########
#############################
# Your username on the target OS
MAIN_USER=""

# Hardcode boot drives EFI partitions here in the form /dev/sdX or /dev/nvmeXnXpX
# If you only have one drive, leave the second define blank
# *_EFI is for the EFI boot partition path
ZPOOL_DISK_1_EFI=""
ZPOOL_DISK_2_EFI=""


if [ -z "${MAIN_USER}" ] || [ -z "${ZPOOL_DISK_1_EFI}" ]; then
  echo "ERROR! Please set all variables before running this script"
  exit 1
fi


function mount_zroot_pool()
{
  echo "Mounting ZFS pool \"zroot\"..."

  # Skip if zroot is already mounted
  while read -r pool; do
    if [ "${pool}" = "zroot" ]; then
      echo "ZFS pool \"zroot\" is already mounted."
      return
    fi
  done < <(zpool list -H | cut -d$'\t' -f 1)

  # Mount zroot
  mkdir -p /mnt/boot
  zpool import -f -d /dev/disk/by-id -R /mnt zroot -N
  zfs mount zroot/ROOT/arch
  zfs mount -a
  mount "${ZPOOL_DISK_1_EFI}" /mnt/boot
}


function umount_zroot_pool()
{
  echo "Unmounting ZFS pool \"zroot\"..."
  zfs umount -a
  umount -R /mnt
  zpool export -a
  rm -r /mnt/boot
}


# 1. Mount the ZFS pools and the first EFI boot partition
mount_zroot_pool

# 2. Chroot into /mnt and re-install kernel
echo "Re-installing linux-lts and mkinitcpio..."
arch-chroot /mnt sudo -u "${MAIN_USER}" pacman -Syu --noconfirm linux-lts mkinitcpio

# 3. Unmount everything and export ZFS pools
umount_zroot_pool

# 4. Use dd to clone the first EFI boot partition to the second EFI boot partition
echo "Cloning mirrored EFI boot partitions..."
if [ -z "${ZPOOL_DISK_2_EFI}" ]; then
  echo "No second disk specified for the pool zroot, skipping..."
else
  dd if="${ZPOOL_DISK_1_EFI}" of="${ZPOOL_DISK_2_EFI}" status=progress
fi

echo "Done!"
