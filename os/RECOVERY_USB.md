# Recovery USB Stick Information


## Arch w/ ZFS
https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs

Pre-built ISO available on releases page




## OPNSense

### Installation Media
Download the OPNSense installation image [here](https://opnsense.org/download/)>

The `vga` image type is for installation using a monitor.
The `serial` image type is for installation through the serial console port.

Write the image to a USB drive.

### Configuration Restoration
If you would like to restore the configuration from a backup, you will need a second USB drive.

First, grab the desired backup archive.
Please note that OPNSense only supports FAT32-formatted drives, so we must format the drive to FAT32.

```sh
# Format to FAT32
sudo mkfs.vfat /dev/sdX

# Mount USB
mkdir ~/usb
mount /dev/sdX usb
cd usb

# Extract OPNSense config
tar -xvf opnsense-backup-20250803-0300.tar.gz
cp -r conf/ ~/usb
rm opnsense-backup-20250803-0300.tar.gz

# Unmount USB
cd ../
umount usb
rm -r usb
```

When installing OPNSense, please insert both USB drives.
After booting from the installation media drive, you will eventually be prompted to import an existing config.
When it prompts you, select the configuration restoration USB drive.




## OpenWRT
https://firmware-selector.openwrt.org/?version=24.10.2

Currently using NETGEAR WAX220
https://openwrt.org/toh/netgear/wax220
