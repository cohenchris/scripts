# https://www.youtube.com/watch?v=CcSjnqreUcQ
# 1. Boot into live USB
# 2. Run this script
# 3. Reboot
# 4. YADM dotfiles restore + bootstrap


# pre_chroot_setup()
#
# Arch Linux setup which is executed in a live USB.
# Responsible for partitioning ZFS root pool devices, creating mirrored ZFS root pool, system bootstrapping, and more. 
function pre_chroot_setup()
{
  ##############################
  # QUERY USER FOR DRIVE NAMES #
  ##############################
  # List devices
  fdisk -l

  echo
  echo "########################################"
  echo "#           ***WARNING***              #"
  echo "#  THIS SCRIPT WILL CREATE A MIRRORED  #"
  echo "#    ZFS ROOT POOL ON THE SPECIFIED    #"
  echo "#  DEVICES. MAKE ABSOLUTELY SURE THAT  #"
  echo "#   THE DEVICE NAMES ARE CORRECT OR    #"
  echo "#   YOU RISK CATASTROPHIC DATA LOSS.   #"
  echo "########################################"

  # Ask for ZFS root pool device name #1
  echo
  read -p "Enter target ZFS root pool device name #1 (in the format /dev/sdX): " ZFS_ROOT1_DEV_NAME

  # Ask for ZFS root pool device name #2
  echo
  read -p "Enter target ZFS root pool device name #2 (in the format /dev/sdX): " ZFS_ROOT2_DEV_NAME

  # Confirm choices
  echo
  fdisk -l ${ZFS_ROOT1_DEV_NAME}
  echo
  fdisk -l ${ZFS_ROOT2_DEV_NAME}
  echo

  read -p "Are these devices correct? (y/N) " yn

  case $yn in
    [Yy]* ) ;;
    *     ) exit;;
  esac

  ######################
  # DRIVE PARTITIONING #
  ######################
  # Destroy all existing partitions
  sgdisk --zap-all ${ZFS_ROOT1_DEV_NAME}
  sgdisk --zap-all ${ZFS_ROOT2_DEV_NAME}

  # Create boot partitions
  sgdisk -n1:0:+4G -t1:ef00 ${ZFS_ROOT1_DEV_NAME}
  sgdisk -n1:0:+4G -t1:ef00 ${ZFS_ROOT2_DEV_NAME}

  # Create ZFS partitions
  sgdisk -n2:0:0 -t2:bf00 ${ZFS_ROOT1_DEV_NAME}
  sgdisk -n2:0:0 -t2:bf00 ${ZFS_ROOT2_DEV_NAME}

  # Define partitions 1 and 2 for each drive
  ZFS_ROOT1_P1_DEV_NAME=$(lsblk -nr -o NAME "${ZFS_ROOT1_DEV_NAME}" | awk 'NR==2 {print "/dev/"$1}')
  ZFS_ROOT1_P2_DEV_NAME=$(lsblk -nr -o NAME "${ZFS_ROOT1_DEV_NAME}" | awk 'NR==3 {print "/dev/"$1}')
  ZFS_ROOT2_P1_DEV_NAME=$(lsblk -nr -o NAME "${ZFS_ROOT2_DEV_NAME}" | awk 'NR==2 {print "/dev/"$1}')
  ZFS_ROOT2_P2_DEV_NAME=$(lsblk -nr -o NAME "${ZFS_ROOT2_DEV_NAME}" | awk 'NR==3 {print "/dev/"$1}')

  # Create boot filesystem for both drives
  mkfs.vfat "${ZFS_ROOT1_P1_DEV_NAME}"
  mkfs.vfat "${ZFS_ROOT2_P1_DEV_NAME}"

  ##########################
  # ZFS ROOT POOL CREATION #
  ##########################
  # Enable ZFS kernel modules
  modprobe zfs

  if [ $? -ne 0 ]; then
    echo "ZFS kernel module not found, cannot continue."
    exit
  fi

  # ZFS systemd automatic mounting cache - used later
  mkdir -p /etc/zfs/zfs-list.cache
  touch /etc/zfs/zfs-list.cache/zroot
  systemctl enable zfs-zed.service
  systemctl restart zfs-zed.service

  # ZFS root
  zpool create -f \
               -o ashift=12 \
               -O compression=lz4 \
               -O atime=off \
               -O xattr=sa \
               -O acltype=posixacl\
               -O relatime=on \
               -O canmount=off \
               -O dnodesize=auto \
               -O normalization=formD \
               -O mountpoint=none \
               -O devices=off \
               -R /mnt \
               zroot mirror "${ZFS_ROOT1_P2_DEV_NAME}" "${ZFS_ROOT2_P2_DEV_NAME}"


  ########################
  # ZFS DATASET CREATION #
  ########################
  # root dataset
  zfs create -o mountpoint=none -o canmount=off zroot/ROOT

  # dataset holding arch linux filesystem
  zfs create -o mountpoint=/ -o canmount=noauto zroot/ROOT/arch

  # user home directory
  zfs create -o mountpoint=/home zroot/home

  # root home directory
  zfs create -o mountpoint=/root zroot/home/root

  # directories that are more temporary + not desired for a snapshot
  zfs create -o mountpoint=/var zroot/var
  zfs create -o mountpoint=/var/log zroot/var/log
  zfs create -o mountpoint=/var/cache zroot/var/cache

  # Unmount all datasets
  zfs umount -a
  rm -rf /mnt/*

  # Export pool and re-import to /mnt
  zpool export zroot
  zpool import -d /dev/disk/by-id -R /mnt zroot -N

  # Mount arch linux root manually, then all other datasets on top of it
  zfs mount zroot/ROOT/arch
  zfs mount -a

  # Mount main boot partition
  mkdir /mnt/boot
  mount "${ZFS_ROOT1_P1_DEV_NAME}" /mnt/boot

  # Install base tools + linux kernel + vim
  pacstrap /mnt base base-devel linux-lts linux-firmware intel-ucode vim vi

  ##################################
  # ZFS DATASET AUTOMATIC MOUNTING #
  ##################################
  # Instructions from zfs-mount-generator manpage
  # https://openzfs.github.io/openzfs-docs/man/master/8/zfs-mount-generator.8.html

  # If cache file is empty, manually trigger ZEDLET to refresh
  if ! [ -s /etc/zfs/zfs-list.cache/zroot ]; then
    zfs set relatime=off zroot/ROOT
    zfs inherit relatime zroot/ROOT
  fi

  # If still empty, exit
  if ! [ -s /etc/zfs/zfs-list.cache/zroot ]; then
    echo "Unable to populate zfs-list.cache, exiting..."
    exit
  fi

  # Copy ZFS automatic mounting cache to target drive
  mkdir -p /mnt/etc/zfs/zfs-list.cache
  cp /etc/zfs/zfs-list.cache/zroot /mnt/etc/zfs/zfs-list.cache/zroot

  # Delete the altroot '/mnt', otherwise datasets will be mounted at /mnt
  sed -i 's|/mnt||g' /mnt/etc/zfs/zfs-list.cache/zroot

  ####################
  # CHROOT EXECUTION #
  ####################
  # Copy this script into your new Arch system to continue bootstrapping
  cp "$0" /mnt/root/
  chmod +x /mnt/root/"$0"

  # Go into your new Arch partition and continue executing this script
  arch-chroot /mnt /root/"$0"

  # Delete bootstrapping script
  rm /mnt/root/"$0"
}


# post_chroot_setup()
#
# Arch Linux setup which is executed after chrooting into a fresh Arch Linux install.
# Responsible for root user/password, personal user/password, hostname, permissions, system time, networking, basic packages, bluetooth, crontab, AUR helper, automatic drive mounting, and more.
function post_chroot_setup() {
  ##############################################
  # USERS, PERMISSIONS, LOCAL MACHINE SETTINGS #
  ##############################################
  # Root user password
  echo "First, we need to set a password for the root user."
  passwd

  # Personal user username/password
  echo
  echo "Now, we will set up your personal user."
  read -p "Username: " USERNAME
  useradd -mg wheel "${USERNAME}"
  passwd ${USERNAME}
  echo

  # Set hostname
  echo
  read -p "Machine hostname: " HOSTNAME
  echo ${HOSTNAME} > /etc/hostname

  # Give sudo access to all members of the wheel group
  echo "Giving sudo access to all members of the wheel group..."
  sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

  # Enable NTP
  echo "Enabling NTP..."
  timedatectl set-ntp true

  # Set language and time zone
  echo
  echo "Setting language and time zone..."
  sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
  locale-gen
  echo "LANG=en_US.UTF-8" > /etc/locale.conf
  ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime

  # Configure local machine addresses
  echo
  echo "Configuring local machine addresses..."
  echo -e "127.0.0.1 localhost\n::1 localhost\n127.0.1.1 arch.localdomain arch" > /etc/hosts

  ##################
  # BASIC PACKAGES #
  ##################
  # Install core basic packages
  echo
  echo "Installing core basic packages..."
  pacman-key --init
  pacman-key --populate archlinux
  pacman -Syu --noconfirm \
    efibootmgr \
    networkmanager \
    network-manager-applet \
    wireless_tools \
    wpa_supplicant \
    dialog \
    os-prober \
    mtools \
    dosfstools \
    linux-lts-headers \
    git \
    pipewire-pulse \
    bluez \
    bluez-utils \
    xdg-utils \
    xdg-user-dirs \
    rsync \

  # Enable internet
  echo
  echo "Enabling NetworkManager..."
  systemctl enable NetworkManager

  # Enable bluetooth
  echo
  echo "Enabling bluetooth..."
  systemctl enable bluetooth

  # Enable cron
  echo
  echo "Enabling cron..."
  systemctl enable cronie

  # Install paru AUR helper
  echo
  echo "Installing paru AUR helper..."
  cd /home/${USERNAME}
  sudo -u ${USERNAME} git clone https://aur.archlinux.org/paru.git
  cd paru
  sudo -u ${USERNAME} makepkg -si --noconfirm
  cd ../
  rm -rf paru/
  cd

  # Install ZFS and YADM
  echo
  echo "Installing and enabling ZFS utilities and services + YADM dotfiles manager..."
  sudo -u ${USERNAME} paru -Syu --noconfirm yadm zfs-dkms zfs-utils
  sudo systemctl enable zfs.target \
                        zfs-import.target \
                        zfs-volumes.target \
                        zfs-import-scan.service \
                        zfs-volume-wait.service \
                        zfs-zed.service \

  # Generate hostid file to uniquely identify this machine to ZFS
  zgenhostid $(hostid)

  ############################
  # DRIVE AUTOMATIC MOUNTING #
  ############################
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

  ##############
  # BOOTLOADER #
  ##############
  echo
  echo "Configuring bootloader..."
  # Configure intial ramdisk (add 'zfs' to the HOOKS list after 'block')
  sed -i '/^HOOKS=/s/\(.*block\)/\1 zfs/' /etc/mkinitcpio.conf
  mkinitcpio -P

  # Install bootloader to /boot
  bootctl --path=/boot install

  # Bootloader - set default entry selection and menu timeout
  cat <<EOF > /boot/loader/loader.conf
default arch
timeout 5
EOF

  # Create bootloader entry for Arch Linux main kernel
  cat <<EOF > /boot/loader/entries/arch.conf
title Arch Linux
linux /vmlinuz-linux-lts
initrd /intel-ucode.img
initrd /initramfs-linux-lts.img
options zfs=zroot/ROOT/arch rw
EOF

  # Create bootloader entry for Arch Linux fallback kernel
  cat <<EOF > /boot/loader/entries/arch-fallback.conf
title Arch Linux (Fallback)
linux /vmlinuz-linux-lts
initrd /intel-ucode.img
initrd /initramfs-linux-lts-fallback.img
options zfs=zroot/ROOT/arch rw
EOF

  # Pacman hook to update bootctl when systemd is updated
  # `bootctl update`
  #   - copies the latest bootloader binaries to the EFI partition and makes
  #   - ensures the bootloader is installed correctly
  mkdir -p /etc/pacman.d/hooks/
  cat <<EOF > /etc/pacman.d/hooks/100-systemd-boot.hook
[Trigger]
Type = Package
Operation = Upgrade
Target = systemd

[Action]
Description = update systemd-boot
When = PostTransaction
Exec = /usr/bin/bootctl update
EOF
}


########
# MAIN #
########
# User must run as root
if [[ "$(id -u)" -ne 0 ]]; then
    echo "This script must be run as root" 
    exit 1
fi

# User must be in UEFI mode - this will be empty if not
if [ -z "$(ls /sys/firmware/efi)" ]; then
  echo "ERROR: The system is not booted in UEFI mode, cannot continue."
  exit
fi

if [[ -f /etc/hostname && "$(cat /etc/hostname)" == "archiso" ]]; then
  echo "Running on live USB, proceeding with pre-chroot setup..."
  pre_chroot_setup

  echo
  echo "Mirroring boot partition on second drive..."
  # Unmount first drive's EFI boot partition and sync to flush all changes to disk
  umount /mnt/boot
  sync
  # Use dd to copy first drive's EFI boot partition to second drive's EFI boot partition
  sudo dd if=${ZFS_ROOT1_P1_DEV_NAME} of=${ZFS_ROOT2_P1_DEV_NAME} status=progress

  # Unmount to prevent data corruption
  echo
  echo "Unmounting all drives..."
  zfs umount -a
  umount -R /mnt
  # If we don't export the ZFS pools, import may fail when you boot your new Arch Linux system
  zpool export -a

  echo
  echo "Setup complete!"
  echo "If all has gone well, please reboot and remove the installation media."
  echo "After reboot, system is ready for YADM dotfiles sync + bootstrapping script."
else
  echo "Running inside chroot, proceeding with post-chroot setup..."
  post_chroot_setup
fi
