# Arch Linux

Custom scripts, services and configuration files for a typical Linux machine.
The import script is tailored towards Arch Linux, but these services should work on any systemd-based Linux distribution.




# Table of Contents

- [Install Arch on ZFS](#Install-Arch-on-ZFS)
  - [Prerequisites](#Prerequisites)
  - [Use](#Use)
- [Sync Mirrored EFI Boot Partitions](#Sync-Mirrored-EFI-Boot-Partitions)
  - [Prerequisites](#Prerequisites-1)
  - [Use](#Use-1)
- [Replace and Resilver a Drive in a ZFS Root Pool](#Replace-and-Resilver-a-Drive-in-a-ZFS-Root-Pool)
  - [Prerequisites](#Prerequisites-2)
  - [Use](#Use-2)
- [Rescue Corrupted EFI Boot Partition](#Rescue-Corrupted-EFI-Boot-Partition)
  - [Prerequisites](#Prerequisites-3)
  - [Use](#Use-3)
- [Arch Env Setup])(#Arch-Env-Setup)
  - [Prerequisites](#Prerequisites-4)
  - [Use](#Use-4)




## Install Arch on ZFS
[`arch-install.sh`](arch-install.sh)

This is an all-in-one script to install Arch on two drives as a mirrored ZFS root pool.

It will:
- Partition both drives for ZFS root pool
- Create root pool and datasets
- Configure auto-mounting of root pool, datasets, and EFI boot partition using systemd.mount (no fstab!)
- Set up basic fresh Arch install things (e.g. users, hostname, NTP, sudo management, locale, etc.)
- Install base packages for bare minimum functionality
- Install AUR helper
- Configure bootctl bootloader
- Sync EFI partition on both ZFS mirrored root drives to allow booting from either drive

### Prerequisites
- You have 2 drives connected which will be used as boot drives
- The 2 drives are the same size
- You have a live Arch Linux USB with ZFS installed
- You have a wired internet connection

### Use
To use this script, simply boot from a live Arch Linux USB on your target system and run.
Please pay attention, as the script will ask you various questions throughout its execution.
When the script is done, you should reboot, remove the live USB, and boot into your new Arch Linux installation!




## Sync Mirrored EFI Boot Partitions
[`arch-boot-mirror.sh [root_pool_name]`](arch-boot-mirror.sh)

This keeps a mirrored ZFS root pool's EFI partitions in sync.
For this to work, one partition must be mounted at /boot, and the other must be unmounted.

Initially, I had this running with a pacman hook, but the hook would run before data in the EFI partition was actually updated.
So, instead, this should be run manually.

### Prerequisites
- You have 2 identical boot drives which were configured with 2 partitions - one EFI partition and one ZFS root partition
- One of the EFI boot partitions is automatically mounted when the system is booted.

### Use
This script should be run manually whenever a package is updated that will modify the data present in your mounted EFI boot partition.
These packages include, but are not limited to:
- `linux-lts`
- `mkinitcpio`
- `systemd`
- `intel-ucode`
- `efibootmgr`

I highly recommend automating the mirroring of your EFI boot partitions to minimize the amount of time your EFI boot partitions will be out of sync.
If you have a drive failure, and the surviving disk's EFI partition is out of date, you will almost certainly run into undefined behavior due to kernel mismatching issues.
Personally, I have an [`update`](../../bin/update) script that does a variety of things to update and clean my system.
At the very end of this script, I call this script to mirror the EFI boot partitions.
This means that the script is called whether the EFI boot partition data is updated or not, it's better to be safe.




## Replace and Resilver a Drive in a ZFS Root Pool
[`arch-root-resilver.sh`](arch-root-resilver.sh)

In case of a drive failure, on your mirrored ZFS root pool, this script assists in seamlessly resilvering a replacement drive.
It will resilver the ZFS partition, clone the EFI boot partition to the new drive, AND update the systemd.mount service which auto-mounts the EFI boot partition.

### Prerequisites
- You have a mirrored ZFS root pool
- You have removed the defective ZFS boot drive from your system
- You are booted from the remaining ZFS boot drive
- The remaining ZFS boot drive EFI partition is mounted at /boot

### Use
To use this script, simply boot from the surviving drive in your ZFS root pool.
This script is intended to be used when directly booted from the surviving drive, but may work fine if you need to rescue the system by chrooting from a live USB.




## Rescue Corrupted EFI Boot Partition
[`arch-rescue.sh`](arch-rescue.sh)

Since I have a ZFS root pool set up with two mirrored drives, there is some complication with maintaining the EFI boot partitions.
Sometimes, they just break after an update if I'm not careful.
This script is meant to help get the system up and running more quickly than if you were to manually do so.

### Prerequisites
- You have a ZFS root pool
- You have set the relevant variables inside of the script
- You have a live Arch USB with ZFS installed.

### Use
To use this script, boot into the live USB stick with Arch + ZFS.
Then, simply run it!
Everything should be taken care of, and if all commands ran successfully, you will have a working system on next reboot.




## Arch Env Setup
[`arch-env-setup.sh`](arch-env-setup.sh)

This script configures common programs and daemons used for some of my Arch Linux installs.

### Prerequisites
- You have installed Arch Linux
- You have rebooted from the live USB installer and logged in

### Use
To use this script, simply run it and enter any information requested.
