# Warden

Custom scripts, services, and configuration files for a machine whose sole responsibility is running [Network UPS Tools](https://networkupstools.org/) (UPS monitoring/shutdown) and [Uptime Kuma](https://github.com/louislam/uptime-kuma) (uptime monitoring).

This machine is Arch Linux based, and uses `paru` as its AUR helper.




# Table of Contents

- [Network UPS Tools](#Network-UPS-Tools)
  - [Prerequisites](#Prerequisites)
  - [Use](#Use)
- [Uptime Kuma](#Uptime-Kuma)
  - [Prerequisites](#Prerequisites-1)
  - [Use](#Use-1)
- [Automated Setup Script](#Automated-Setup-Script)
  - [Use](#Use-2)




## Network UPS Tools
[`nut/`](nut/)

Configuration files for [Network UPS Tools (NUT)](https://networkupstools.org/), which monitors a USB-connected UPS and can gracefully shut down the system on power loss.

- [`ups.conf`](nut/ups.conf) - defines the UPS driver (`usbhid-ups`, auto-detected port)
- [`upsd.conf`](nut/upsd.conf) - configures `upsd` to listen on all interfaces
- [`upsd.users`](nut/upsd.users) - defines the `upsmon` user used by the monitoring client
- [`upsmon.conf`](nut/upsmon.conf) - configures `upsmon` to monitor the local UPS as master

### Prerequisites
- The UPS is connected to the machine via USB
- The `nut` package is installed (`paru -S nut`)

Before deploying, review [`nut/upsd.users`](nut/upsd.users) and [`nut/upsmon.conf`](nut/upsmon.conf) and replace the default `password` value with something more secure - just make sure it matches in both files.

### Use
1. Manual setup

```sh
cp ./nut/* /etc/nut
chown -R root:nut /etc/nut/*
chmod 640 /etc/nut/*
upsdrvctl start
systemctl enable --now nut.target nut-driver.target nut-driver-enumerator.service
```

2. Automated setup using [`setup.sh`](setup.sh)




## Uptime Kuma
[`uptimekuma-compose.yaml`](uptimekuma-compose.yaml)

A Docker Compose file for [Uptime Kuma](https://github.com/louislam/uptime-kuma), a self-hosted uptime monitoring tool with a web UI, served on port 80.

### Prerequisites
- `docker` and `docker-compose` are installed (`paru -S docker docker-compose`)
- The `docker` service is enabled and running
- Your user is a member of the `docker` group

### Use
1. Manual setup

```sh
mkdir -p ~/uptimekuma
cp ./uptimekuma-compose.yaml ~/uptimekuma
docker compose -f ~/uptimekuma/uptimekuma-compose.yaml up -d
```

Uptime Kuma's data will persist in `~/uptimekuma/config`, and the web UI will be available on port 80.

2. Automated setup using [`setup.sh`](setup.sh)




## Automated Setup Script
[`setup.sh`](setup.sh)

This script fully configures this machine's two responsibilities: NUT and Uptime Kuma.

It will:
- Install the `nut` package, copy the config files from [`nut/`](nut/) into `/etc/nut`, set proper ownership/permissions, and start + enable the NUT services
- Install `docker` and `docker-compose`, enable the Docker service, add your user to the `docker` group, copy [`uptimekuma-compose.yaml`](uptimekuma-compose.yaml) into `~/uptimekuma`, and bring the Uptime Kuma stack up

### Use
Call this script as root from the command line:
```sh
sudo ./setup.sh
```
You will be prompted for the username to operate as (used for `paru` calls and to own `~/uptimekuma`).
