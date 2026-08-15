# System Configuration

OS-specific system configuration scripts which are mostly intended to be used on a new install.




# Table of Contents

- [Arch Linux](#Arch-Linux)
- [OPNSense](#OPNSense)
- [OpenWRT](#OpenWRT)
- [Email](#Email)
- [ZFS Data Pool Disaster Recovery](#ZFS-Data-Pool-Disaster-Recovery)
- [Recovery USB Stick Information](#Recovery-USB-Stick-Information)




## Arch Linux
[`arch/`](arch/)

Custom scripts, services and configuration files for a typical Linux machine.
The import script is tailored towards Arch Linux, but these services should work on any systemd-based Linux distribution.




## OPNSense
[`opnsense/`](opnsense/)

Custom scripts, services, and configuration files for a machine running the FreeBSD-based OPNSense distribution.




## OpenWRT
[`openwrt/`](openwrt/)

Custom scripts, services, and configuration files for a machine running the Linux-based OpenWRT distribution.




## Email
[`email/`](email/)

Install and configure outbound email on the host machine, typically used for cron notifications.




## ZFS Data Pool Disaster Recovery
[`zfs/`](zfs/)

Scripts to recreate a ZFS data pool from nothing, or to replace a single still-working drive in one. Covers data pools only (not the system/root ZFS pool, which is covered by the [Arch Linux](#Arch-Linux) and [OPNSense](#OPNSense) scripts above).




## Recovery USB Stick Information
[`RECOVERY_USB.md`](RECOVERY_USB.md)

Notes on preparing recovery USB media (installation and configuration-restoration drives) for Arch w/ ZFS, OPNSense, and OpenWRT.
