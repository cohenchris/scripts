#!/bin/bash

# Hardcode boot partitions here in the form /dev/sdX or /dev/nvmeXnXpX
MAIN_USER=""
ZPOOL_DISK_1=""
ZPOOL_DISK_2=""

if [ -z "${MAIN_USER}" ] || [ -z "${ZPOOL_DISK_1}" ] || [ -z "${ZPOOL_DISK_2}" ]; then
  echo "ERROR! Please set all variables before running this script"
fi

# Import root ZFS pools and mount all partitions
zpool import -f -d /dev/disk/by-id -R /mnt zroot -N
zfs mount zroot/ROOT/arch
zfs mount -a
mount "${ZPOOL_DISK_1}" /mnt/boot

# Chroot to mounted partitions
# Switch to main user and re-install kernel
arch-chroot /mnt /bin/bash <<EOF
su - "${MAIN_USER}" -c 'paru -Syu --noconfirm linux-lts mkinitcpio'
EOF

# Unmount everything and export ZFS pools
zfs umount -a
umount -R /mnt
zpool export -a

# Use dd to copy first drive's EFI boot partition to second drive's EFI boot partition
sudo dd if="${ZPOOL_DISK_1}" "${ZPOOL_DISK_2}" status=progress

echo "Done!"
