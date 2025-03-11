# OS Management

One-time use scripts intended to help manage various OS-level components, including a fresh Arch install, ZFS pool management, and services for various systems.
Some may have CATASTROPHIC consequences if used incorrectly, so they should be read and fully understood before use.




# Table of Contents

- [Install Arch on ZFS](#Install-Arch-on-ZFS)
  - [Prerequisites](#Prerequisites)
  - [Use](#Use)
- [Sync Mirrored EFI Partitions](#Sync-Mirrored-EFI-Partitions)
  - [Prerequisites](#Prerequisites-1)
  - [Use](#Use-1)
- [Replace/Resilver a Drive in ZFS Root Pool](#Replace/Resilver-a-Drive-in-ZFS-Root-Pool)
  - [Prerequisites](#Prerequisites-2)
  - [Use](#Use-2)
- [System Services](#System-Services)




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




## Sync Mirrored EFI Partitions
[`boot-mirror.sh [mirror,setup] [root_pool_name]`](boot-mirror.sh)

This keeps a mirrored ZFS root pool's EFI partitions in sync.
For this to work, one partition must be mounted at /boot, and the other must be unmounted.

This is designed to be set up in a cron job or systemd hook.

`boot-mirror.sh setup` creates and enables the systemd service to automate mirroring.

`boot-mirror.sh mirror <root_pool_name>` performs a mirroring operation on the two boot drives.

### Prerequisites
- You have 2 identical boot drives which were configured with 2 partitions - one EFI partition and one ZFS root partition
- One of the EFI boot partitions is automatically mounted when the system is booted.

### Use
While this script may be run manually with the `mirror` argument if desired,
I highly recommend automating the mirroring of your EFI boot partitions to minimize the amount of time your EFI boot partitions will be out of sync.
If you have a drive failure, and the surviving disk's EFI partition is out of date, you will almost certainly run into undefined behavior due to kernel mismatching issues.
The best way to prevent this is to run the script whenever systemd is updated.
To set this up, please run `boot-mirror.sh setup`.




## Replace/Resilver a Drive in ZFS Root Pool
[`root-resilver.sh`](root-resilver.sh)

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




## System Services
[`services/`](services/)

Custom services for different operating systems.
