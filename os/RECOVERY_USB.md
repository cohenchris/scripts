# Recovery USB Stick Information


## Arch w/ ZFS
https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs

Pre-built ISO available on releases page




## OPNSense

### Installation Media
Download the OPNSense installation image [here](https://opnsense.org/download/)

The `vga` image type is for installation using a monitor.
The `serial` image type is for installation through the serial console port.

Write the image to a USB drive.

### Configuration Restoration
To restore the configuration from a backup, you will need a second USB drive.
OPNSense only reads FAT32 drives for config import, so format it as FAT32 and copy the backup's `conf/` directory onto it:

```sh
# Format to FAT32 (replace sdX1 with the drive's partition)
sudo mkfs.vfat -F 32 /dev/sdX1

# Mount USB
mkdir -p ~/usb
sudo mount /dev/sdX1 ~/usb

# Extract the OPNSense config onto the USB
tar -xvf /path/to/opnsense-backup-<date>.tar.gz -C /tmp
sudo cp -r /tmp/conf ~/usb/

# Unmount USB
sudo umount ~/usb
rmdir ~/usb
```

When installing OPNSense, please insert both USB drives.
After booting from the installation media drive, you will eventually be prompted to import an existing config.
When it prompts you, select the configuration restoration USB drive.




## OpenWRT
Build an image for your device with the [OpenWRT Firmware Selector](https://firmware-selector.openwrt.org/).
