# Warden

Custom scripts, services, and configuration files for a small always-on watchdog machine (UPS monitoring, uptime monitoring, and image update notifications).




# Table of Contents

- [Docker Compose Stack](#docker-compose-stack)
  - [Prerequisites](#prerequisites)
  - [Configuration](#configuration)
  - [Use](#use)
- [Automated Setup Script](#automated-setup-script)
  - [Use](#use-1)
- [Network Shutdown Script](#network-shutdown-script)
  - [Prerequisites](#prerequisites-1)
  - [Configuration](#configuration-1)
  - [Use](#use-2)




## Docker Compose Stack
[`docker/docker-compose.yml`](docker/docker-compose.yml)

- **Network UPS Tools (NUT)** - runs `upsd` for a USB-connected UPS (port 3493)
- **Uptime Kuma** - uptime monitoring web UI (port 3001)
- **What's Up Docker (WUD)** - watches the local and one remote Docker host for image updates and sends email notifications (port 3000)
- **signal** - signal-cli REST API, used by the [network shutdown script](#network-shutdown-script) to send notifications (port 8080)
- **browserless** - headless Chrome (port 3002)

### Prerequisites
- Docker with the compose plugin, with your user in the `docker` group
- The UPS is connected via USB
- The remote Docker host exposes its API over TLS (port 2376), with client certs placed in `${CONFIG}/docker-tls/<WUD_REMOTE_HOST>/{ca,cert,key}.pem`
- A Docker Hub [access token](https://docs.docker.com/security/for-developers/access-tokens/) and an `htpasswd` hash for the WUD web UI login

### Configuration
Copy [`docker/sample.env`](docker/sample.env) to `.env` and fill it in. It covers the general settings (`TZ`, `CONFIG`), the UPS details, and WUD's Docker Hub login, web UI login, remote host, and SMTP settings.

### Use
1. Manual setup

```sh
mkdir -p ~/warden
cp -a docker/. ~/warden/
cp ~/warden/sample.env ~/warden/.env
# now edit ~/warden/.env
docker compose -f ~/warden/docker-compose.yml up -d
```

2. Automated setup using [`setup.sh`](setup.sh)




## Automated Setup Script
[`setup.sh`](setup.sh)

Sets up a Debian-based warden machine:
- Installs Docker from Docker's apt repository and adds your user to the `docker` group
- Copies [`docker/`](docker) to `~/warden` (it does not create `.env` or start the stack)
- Installs host `upsmon` and points its `SHUTDOWNCMD` at [`scripts/shutdown-network.sh`](scripts/shutdown-network.sh), which runs in place from this repo

### Use
Run as your normal (non-root) user. It uses `sudo` where needed:
```sh
./setup.sh
```

The upsmon step needs the UPS credentials from `~/warden/.env`. If that file isn't filled in yet, fill it in, re-run, then start the stack with `docker compose up -d` from `~/warden`.




## Network Shutdown Script
[`scripts/shutdown-network.sh`](scripts/shutdown-network.sh)

Runs as host `upsmon`'s `SHUTDOWNCMD`. When the UPS reaches low battery (or upsmon issues a forced shutdown), it:

1. Sends a Signal notification through the `signal` container
2. Shuts down each configured machine over SSH
3. Powers off warden itself, last

Telling the UPS itself to cut power is not handled.

### Prerequisites
- Host `upsmon` configured by [`setup.sh`](#automated-setup-script)
- Passwordless root SSH from warden to each machine it shuts down (`upsmon` runs the script as root)
- The `signal` container running with a registered or linked sender number

### Configuration
Copy [`scripts/sample.shutdown-network.conf`](scripts/sample.shutdown-network.conf) to `.shutdown-network.conf` in the same directory and fill it in:
- `SIGNAL_API_ENDPOINT`, `SIGNAL_SENDER`, `SIGNAL_RECIPIENTS` - where and to whom notifications are sent
- `SHUTDOWN_CMDS` - `"user@host command"` entries, run in the order listed. Don't list warden.
  ```sh
  SHUTDOWN_CMDS=(
    "root@host1 systemctl poweroff"
    "root@host2 poweroff"
  )
  ```

### Use
Dry run (sends the real notification, powers nothing off):
```sh
./scripts/shutdown-network.sh --dry-run    # or DRY_RUN=1
```

Real end-to-end test. **This really shuts everything down:**
```sh
sudo upsmon -c fsd
```

Logs go to syslog under the `shutdown-network` tag (`journalctl -t shutdown-network`).
