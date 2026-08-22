# Warden

Custom scripts, services, and configuration files for a machine whose sole responsibility is running [Network UPS Tools](https://networkupstools.org/) (UPS monitoring/shutdown) and [Uptime Kuma](https://github.com/louislam/uptime-kuma) (uptime monitoring).

This machine is Arch Linux based, and uses `paru` as its AUR helper.




# Table of Contents

- [Docker Compose Stack](#Docker-Compose-Stack)
  - [Prerequisites](#Prerequisites)
  - [Configuration](#Configuration)
  - [Use](#Use)
- [Automated Setup Script](#Automated-Setup-Script)
  - [Use](#Use-1)




## Docker Compose Stack
[`docker-compose.yml`](docker-compose.yml)

A single Docker Compose file that runs both services this machine is responsible for:
- **Network UPS Tools (NUT)** - monitors a USB-connected UPS via [`instantlinux/nut-upsd`](https://hub.docker.com/r/instantlinux/nut-upsd), listening on port 3493
- **Uptime Kuma** - a self-hosted uptime monitoring tool with a web UI, served on port 80

### Prerequisites
- `docker` and `docker-compose` are installed (`paru -S docker docker-compose`)
- The `docker` service is enabled and running
- Your user is a member of the `docker` group
- The UPS is connected to the machine via USB

### Configuration
Copy [`sample.env`](sample.env) to `.env` and fill in your UPS's settings (user/password, driver, USB device, serial number, vendor ID) before bringing the stack up.

### Use
1. Manual setup

```sh
mkdir -p ~/warden
cp ./docker-compose.yml ~/warden
cp ./sample.env ~/warden/.env
# now edit ~/warden/.env with your UPS's settings
docker compose -f ~/warden/docker-compose.yml up -d
```

Uptime Kuma's data will persist in `~/warden/config`, and its web UI will be available on port 80.

2. Automated setup using [`setup.sh`](setup.sh)




## Automated Setup Script
[`setup.sh`](setup.sh)

This script fully configures this machine's responsibilities: NUT and Uptime Kuma, both deployed together via [`docker-compose.yml`](docker-compose.yml).

It will:
- Install `docker` and `docker-compose`, enable the Docker service, and add your user to the `docker` group
- Copy [`docker-compose.yml`](docker-compose.yml) and [`sample.env`](sample.env) (renamed to `.env`) into `~/warden`
- Bring the stack up with `docker compose up -d`

### Use
Call this script as root from the command line:
```sh
sudo ./setup.sh
```
You will be prompted for the username to operate as (used for `paru` calls and to own `~/warden`).

The script creates `~/warden/.env` from `sample.env` on every run - after setup, edit it with your UPS's actual settings and run `docker compose up -d` again from `~/warden` to pick up the changes.
