# OS Management

These are one-time use scripts intended to help manage various OS-level components, including a fresh Arch install, ZFS pool management, and system services.
Some of these may have CATASTROPHIC effects on your system, so please make sure you fully understand a script before running.

---

## Install Arch on ZFS
`arch-install.sh`

This is an all-in-one script to install Arch on 2 drives as a a mirrored ZFS root pool.

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
This script assumes that:
- You have 2 drives connected which will be used as boot drives
- The 2 drives are the same size
- You have a live Arch Linux USB with ZFS installed
- You have a wired internet connection

### Setup
To use this script, simply boot from a live Arch Linux USB on your target system and run.
Please pay attention, as the script will ask you various questions throughout its execution.
When the script is done, you should reboot, remove the live USB, and boot into your new Arch Linux installation!

## Sync Mirrored EFI Partitions
`boot-mirror.sh`

This keeps a mirrored ZFS root pool's EFI partitions in sync.
For this to work, one partition must be mounted at /boot, and the other must be unmounted.

This is designed to be set up in a cron job or systemd hook.

### Prerequisites
This script assumes that:
- You have 2 identical boot drives which were configured with 2 partitions - one EFI partition and one ZFS root partition
- One of the EFI boot partitions is automatically mounted when the system is booted.

### Setup
While this script may be run manually if desired,
I highly recommend automating the mirroring of your EFI boot partitions to minimize the amount of time your EFI boot partitions will be out of sync.
If you have a drive failure, and the surviving disk's EFI partition is out of date, you will almost certainly run into undefined behavior due to kernel mismatching issues.
The best way to prevent this is to run the script whenever systemd is updated.
To set this up, please run `boot-mirror-setup.sh`.


## Replace/Resilver a Drive in ZFS Root Pool
`root-resilver.sh`

In case of a drive failure, on your mirrored ZFS root pool, this script assists in seamlessly resilvering a replacement drive.
It will resilver the ZFS partition, clone the EFI boot partition to the new drive, AND update the systemd.mount service which auto-mounts the EFI boot partition.

### Prerequisites
This script assumes that:
- You have a mirrored ZFS root pool
- You have removed the defective ZFS boot drive from your system
- You are booted from the remaining ZFS boot drive
- The remaining ZFS boot drive EFI partition is mounted at /boot

### Setup
To use this script, simply boot from the surviving drive in your ZFS root pool.
This script is intended to be used when directly booted from the surviving drive, but may work fine if you need to rescue the system by chrooting from a live USB.


## Systemd Services
`services/`

A collection of various custom systemd services.
