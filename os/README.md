# OS-related scripts for homelab

## Install Arch on ZFS
`arch-install.sh`

This is an all-in-one script to install Arch on a mirrored ZFS root pool.
It will:
- Partition both drives for ZFS root pool
- Create root pool and datasets
- Configure auto-mounting of root pool, datasets, and EFI boot partition using systemd.mount (no fstab!)
- Set up basic fresh Arch install things (e.g. users, hostname, NTP, sudo management, locale, etc.)
- Install base packages for bare minimum functionality
- Install AUR helper
- Configure bootctl bootloader
- Sync EFI partition on both ZFS mirrored root drives to allow booting from either drive

### Sync Mirrored EFI Partitions
`boot-mirror.sh`

This keeps a mirrored ZFS root pool's EFI partitions in sync.
For this to work, one partition must be mounted at /boot, and the other must be unmounted.

This is designed to be set up in a cron job or systemd hook.

To set this up to be run whenever systemd is upgraded, run `boot-mirror-setup.sh`.

### Replace/Resilver a Drive in ZFS Root Pool
`root-resilver.sh`

This helps the user replace a failed or missing drive in the ZFS root pool.
It will resilver the ZFS partition, clone the EFI boot partition to the new drive, AND update the systemd.mount service which auto-mounts the EFI boot partition.
