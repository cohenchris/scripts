# System Configuration

OS-specific system configuration scripts which are mostly intended to be used on a new install.




# Table of Contents

- [Arch Linux](#Arch-Linux)
- [OPNSense](#OPNSense)
- [OpenWRT](#OpenWRT)
- [Setup Email Notifications](#Setup-Email-Notifications)




## Arch Linux
[`arch/`](arch/)

Custom scripts, services and configuration files for a typical Linux machine.
The import script is tailored towards Arch Linux, but these services should work on any systemd-based Linux distribution.




## OPNSense
[`opnsense/`](opnsense/)

Custom scripts, services, and configuration files for a FreeBSD-based OPNSense distribution.




## OpenWRT
[`openwrt/`](openwrt/)

Custom scripts, services, and configuration files for a Linux-based OpenWRT distribution.




## Setup Email Notifications
[`email/`](email/)

Install and configure email notifications on the host machine.
All of my machines have a common need to send notifications via email.
The steps to do this are almost exactly the same, only some differing system dependencies and syntax at some points.
Rather than mostly repeat the same script for every machine-specific subdirectory in here, I've consolidated it all into one setup script.
