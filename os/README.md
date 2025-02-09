# OS-related scripts for homelab

## Install Arch on ZFS
`arch-install.sh`


### Sync Mirrored EFI Partitions
`boot-mirror.sh`
This keeps a mirrored ZFS root pool's EFI partitions in sync.
For this to work, one partition must be mounted at /boot, and the other must be unmounted.

This is designed to be set up in a cron job or systemd hook.

### Replace/Resilver a Drive in ZFS Root Pool
`root-resilver.sh`

This helps the user replace a failed or missing drive in the ZFS root pool.
It will resilver the ZFS partition, clone the EFI boot partition to the new drive, AND update the systemd.mount service which auto-mounts the EFI boot partition.
