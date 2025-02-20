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


## Sync Mirrored EFI Partitions
`boot-mirror.sh`

This keeps a mirrored ZFS root pool's EFI partitions in sync.
For this to work, one partition must be mounted at /boot, and the other must be unmounted.

This is designed to be set up in a cron job or systemd hook.

To keep these drives as closely in sync as possible, I highly recommend this to be run whenever systemd is upgraded,
To do so, please run `boot-mirror-setup.sh`.

## Replace/Resilver a Drive in ZFS Root Pool
`root-resilver.sh`

This helps the user replace a failed or missing drive in the ZFS root pool.
It will resilver the ZFS partition, clone the EFI boot partition to the new drive, AND update the systemd.mount service which auto-mounts the EFI boot partition.


## Network UPS Tools
`services/nut/*`

This is a collection of configuration files which configure the "Network UPS Tools" driver to communicate with your UPS.
To use this, you have two options:

1. Manual setup
```sh
cp services/nut/* /etc/nut
cd /etc/nut
chown -R root:nut /etc/nut/*
chmod 640 /etc/nut/*
sudo systemctl enable nut.service
sudo systemctl start nut.service
```
2. Automated setup using `services/import-services.sh`


The default username is `upsmon` and password is `password`.

## Nvidia GPU Power Savings
`services/nvidia-gpu-power-savings.service`

This is a systemd service file which will lower the idle power consumption of your Nvidia GPU.
To use this, you have two options:

1. Manual setup
```sh
cp services/nvidia-gpu-power-savings.service /etc/systemd/system
systemctl daemon-reload
systemctl enable nvidia-gpu-power-savings.service
systemctl start nvidia-gpu-power-savings.service
```
2. Automated setup using `services/import-services.sh`


## Glances
`services/glances.service`

This is a systemd service file which will start a glances webserver.
To use this, you have two options:

1. Manual setup
```sh
cp services/glances.service /etc/systemd/system
systemctl daemon-reload
systemctl enable glances.service
systemctl start glances.service
```
2. Automated setup using `services/import-services.sh`

## Nextcloud AI Task Processing
`services/nextcloud-ai-taskprocessing.sh`

https://docs.nextcloud.com/server/latest/admin_manual/ai/overview.html#systemd-service

This script improves Nextcloud Assistant's AI task pickup speed responsiveness. By default, an assistant query will be processed as a background job, which is run every 5 minutes. This script, along with `nextcloud-ai-worker@.service`, processes AI tasks as soon as they are scheduled, rather than the user having to wait up to 5 minutes.

To use this script, first modify the script path present in `nextcloud-ai-worker@.service` and move it to the systemd services folder:
`mv nextcloud-ai-worker@.service /etc/systemd/system`

Then, enable and start the service 4 or more times:
`for i in {1..4}; do systemctl enable --now nextcloud-ai-worker@$i.service; done`

Check the status for success and ensure the workers have been deployed:
`systemctl status nextcloud-ai-worker@1.service`
`systemctl list-units --type=service | grep nextcloud-ai-worker`

`services/glances.service`

This is a systemd service file which will start a glances webserver.
To use this, you have two options:

1. Manual setup
```sh
cp services/glances.service /etc/systemd/system
systemctl daemon-reload
systemctl enable glances.service
systemctl start glances.service
```
2. Automated setup using `services/import-services.sh`
