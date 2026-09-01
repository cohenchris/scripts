# Warden

Custom scripts, services, and configuration files for my watchdog pi.




# Table of Contents

- [Docker Compose Stack](#Docker-Compose-Stack)
  - [Prerequisites](#Prerequisites)
  - [Configuration](#Configuration)
  - [Use](#Use)
- [Automated Setup Script](#Automated-Setup-Script)
  - [Use](#Use-1)




## Docker Compose Stack
[`docker-compose.yml`](docker-compose.yml)

- **Network UPS Tools (NUT)** - monitors a USB-connected UPS via [`instantlinux/nut-upsd`](https://hub.docker.com/r/instantlinux/nut-upsd), listening on port 3493
- **Uptime Kuma** - a self-hosted uptime monitoring tool with a web UI, served on port 3001
- **What's Up Docker (WUD)** - watches running containers for newer image tags via [`getwud/wud`](https://github.com/getwud/wud), with a web UI served on port 3000. It watches both the local Docker socket and a remote Docker host (reached over the plain Docker API on port 2375), and authenticates to Docker Hub with an access token to avoid anonymous pull-rate limits.

### Prerequisites
- `docker` and `docker-compose` are installed
- The `docker` service is enabled and running
- Your user is a member of the `docker` group
- The UPS is connected to the machine via USB
- The remote Docker host WUD monitors exposes its API on port 2375
- A Docker Hub account with an [access token](https://docs.docker.com/security/for-developers/access-tokens/) for WUD's registry lookups
- An `htpasswd` password hash for the WUD web UI login

### Configuration
Copy [`sample.env`](sample.env) to `.env` and fill it in before bringing the stack up:
- **Network UPS Tools** - UPS user/password, driver, USB device path, serial number, and vendor ID
- **What's Up Docker** - Docker Hub username (`DOCKER_LOGIN`) and access token (`DOCKER_TOKEN`), web UI username (`WUD_USERNAME`) and password hash (`WUD_HTPASSWD_HASH`), and the IP of the remote Docker host to monitor (`WUD_REMOTE_HOST`)

WUD also reads `TZ` from the environment the `docker compose` command runs in, so export it (or set it in `.env`) if you want its logs and schedules in local time.

### Use
1. Manual setup

```sh
mkdir -p ~/warden
cp ./docker-compose.yml ~/warden
cp ./sample.env ~/warden/.env
# now edit ~/warden/.env with your UPS and WUD settings
docker compose -f ~/warden/docker-compose.yml up -d
```

Uptime Kuma's data will persist in `~/warden/config`, and its web UI will be available on port 3001. WUD's web UI will be available on port 3000.

2. Automated setup using [`setup.sh`](setup.sh)




## Automated Setup Script
[`setup.sh`](setup.sh)

This script fully configures this machine's responsibilities: NUT, Uptime Kuma, and What's Up Docker, all deployed together via [`docker-compose.yml`](docker-compose.yml).

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

The script creates `~/warden/.env` from `sample.env` on every run - after setup, edit it with your actual UPS and WUD settings and run `docker compose up -d` again from `~/warden` to pick up the changes.
