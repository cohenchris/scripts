# Warden

Custom scripts, services, and configuration files for my watchdog pi.




# Table of Contents

- [Docker Compose Stack](#Docker-Compose-Stack)
  - [Prerequisites](#Prerequisites)
  - [Configuration](#Configuration)
  - [Use](#Use)
- [Automated Setup Script](#Automated-Setup-Script)
  - [Use](#Use-1)
- [Network Shutdown Script](#Network-Shutdown-Script)
  - [Prerequisites](#Prerequisites-1)
  - [Configuration](#Configuration-1)
  - [Use](#Use-2)




## Docker Compose Stack
[`docker-compose.yml`](docker-compose.yml)

- **Network UPS Tools (NUT)** - monitors a USB-connected UPS via [`instantlinux/nut-upsd`](https://hub.docker.com/r/instantlinux/nut-upsd), listening on port 3493
- **Uptime Kuma** - a self-hosted uptime monitoring tool with a web UI, served on port 3001
- **What's Up Docker (WUD)** - watches running containers for newer image tags via [`getwud/wud`](https://github.com/getwud/wud), with a web UI served on port 3000. It watches both the local Docker socket and a remote Docker host (reached over the plain Docker API on port 2375), and authenticates to Docker Hub with an access token to avoid anonymous pull-rate limits. Every other container in the stack carries a `wud.tag.include` label so WUD only flags real version bumps, ignoring `latest`/`-dev`/`-ci`/etc noise on Docker Hub:
  - `uptime-kuma` - `#.#.#-slim`
  - `nut` - `#.#.#-rN`
  - `whatsupdocker` - `#.#.#`
  - `signal` - `#.#`
  - `browserless` - `#.#.#-chrome-stable`

### Prerequisites
- `docker` and `docker-compose` are installed
- The `docker` service is enabled and running
- Your user is a member of the `docker` group
- The UPS is connected to the machine via USB
- The remote Docker host WUD monitors exposes its API on port 2375
- A Docker Hub account with an [access token](https://docs.docker.com/security/for-developers/access-tokens/) for WUD's registry lookups
- An `htpasswd` password hash for the WUD web UI login

### Configuration
Copy [`docker/sample.env`](docker/sample.env) to `docker/.env` and fill it in before bringing the stack up:
- **Network UPS Tools** - UPS user/password, driver, USB device path, serial number, and vendor ID
- **What's Up Docker** - Docker Hub username (`DOCKER_LOGIN`) and access token (`DOCKER_TOKEN`), web UI username (`WUD_USERNAME`) and password hash (`WUD_HTPASSWD_HASH`), and the IP of the remote Docker host to monitor (`WUD_REMOTE_HOST`)

WUD also reads `TZ` from the environment the `docker compose` command runs in, so export it (or set it in `.env`) if you want its logs and schedules in local time.

### Use
1. Manual setup

```sh
mkdir -p ~/docker
cp -a docker/. ~/docker/
cp ~/docker/sample.env ~/docker/.env
# now edit ~/docker/.env with your UPS and WUD settings
docker compose -f ~/docker/docker-compose.yml up -d
```

Uptime Kuma's data will persist in `${CONFIG}/uptime-kuma` (`CONFIG` is set in `.env`), and its web UI will be available on port 3001. WUD's web UI will be available on port 3000.

2. Automated setup using [`setup.sh`](setup.sh)




## Automated Setup Script
[`setup.sh`](setup.sh)

This script fully configures this machine's responsibilities: NUT, Uptime Kuma, and What's Up Docker, all deployed together via [`docker/docker-compose.yml`](docker/docker-compose.yml).

It will:
- Install `docker` and `docker-compose` via `apt-get`, enable the Docker service, and add your user to the `docker` group
- Copy the whole [`docker/`](docker) folder into `~/docker` - it does not create `.env` or bring the stack up
- Install host `upsmon` (credentials from `~/docker/.env`) and point its `SHUTDOWNCMD` at [`scripts/shutdown-network.sh`](scripts/shutdown-network.sh) in this repo (it runs in place, not copied). The script's `.shutdown-network.conf` is left to you

### Use
Call this script as your normal (non-root) user - it escalates internally with `sudo` where needed:
```sh
./setup.sh
```
It operates as the invoking user (`$USER`) - no username prompt, and it will refuse to run if invoked as root.

If `docker/` already has a `.env`, it is copied along with everything else (overwriting `~/docker/.env`); otherwise an existing `~/docker/.env` is left alone. If `~/docker/.env` doesn't exist (or lacks `UPS_USER`/`UPS_PASSWORD`), upsmon setup is skipped - create it from `sample.env`, re-run, and bring the stack up yourself with `docker compose up -d` from `~/docker`.




## Network Shutdown Script
[`scripts/shutdown-network.sh`](scripts/shutdown-network.sh)

Meant to be wired in as the host `upsmon`'s `SHUTDOWNCMD` on warden (the Docker Compose stack only runs `upsd` - it doesn't monitor the UPS itself). When the UPS reaches low battery, or upsmon otherwise issues a forced shutdown, this script runs instead of a bare `shutdown` and:

1. Sends a Signal message through the `signal` container's signal-cli REST API
2. Shuts down every other server on the network (`shutdown_all_devices`)
3. Powers off warden itself, last (`shutdown_self`)

> **Status:** steps 1 and 3 are implemented. `shutdown_all_devices` is currently a stub - see the comment above it in the script for the intended shape (an SSH poweroff loop over a server inventory). Router and AP are intentionally left up so the run can finish; killing mains via the UPS itself is out of scope.

### Prerequisites
- Passwordless root SSH from warden to every server it shuts down, once `shutdown_all_devices` is filled in - `upsmon` runs `SHUTDOWNCMD` as root
- Host `upsmon` installed and configured on warden (`paru -S nut`), with `SHUTDOWNCMD` pointed at this script's path in the repo (it runs in place) in `/etc/nut/upsmon.conf`, then `systemctl enable --now nut-monitor.service`
- The `signal` container running with a registered or linked sender number

### Configuration
The script reads its own config from `.shutdown-network.conf` in its directory, separate from the compose stack's `.env` (copy [`sample.shutdown-network.conf`](scripts/sample.shutdown-network.conf) if you haven't already - it has the placeholder keys). It is sourced as bash:
- `SIGNAL_API_ENDPOINT` - base URL of the signal-cli REST API (default `http://localhost:8080`); the script POSTs to `<endpoint>/v2/send`, so don't include `/v2/send` yourself
- `SIGNAL_SENDER` - Signal number registered/linked in the `signal` container, used as the sender
- `SIGNAL_RECIPIENTS` - space-separated phone numbers and/or group IDs (`group.xxxx`) to message
- `SHUTDOWN_CMDS` - bash array of `"user@host command"` entries, shut down in the order listed (put anything the others are reached through, like the router, last). Don't list warden - it always powers off last:
  ```sh
  SHUTDOWN_CMDS=(
    "root@server1.lan systemctl poweroff"
    "root@router.lan poweroff"
  )
  ```

The notification text (`title`/`body`) and request timeout (`NOTIFY_TIMEOUT`) are hardcoded in the script's Configuration section.

Optional:
- `DRY_RUN=1` (environment variable or `--dry-run`) - send the real Signal notification, but power nothing off (neither the other servers nor warden)

### Use
Test the wiring first - sends the real Signal notification, but nothing is powered off:
```sh
DRY_RUN=1 ./scripts/shutdown-network.sh
# or
./scripts/shutdown-network.sh --dry-run
```

Once host `upsmon` is configured with this script as its `SHUTDOWNCMD`, a real end-to-end test is:
```sh
sudo upsmon -c fsd
```
This actually shuts down the network, so only run it once `shutdown_all_devices` is implemented and everything above is in place.

Logs go to stderr and syslog under the `shutdown-network` tag:
```sh
journalctl -t shutdown-network
```
