# Linux Services

Custom services and configuration files for a typical Linux machine.
The import script is tailored towards Arch Linux, but these services should work on any systemd-based Linux distribution.

---

## Network UPS Tools
[`nut/*`](nut/)

Configuration files for the "Network UPS Tools" driver, which communicate with your UPS.

The default username is `upsmon` and password is `password`.

### Prerequisites
This script assumes:
- There is a UPS connected to your computer via USB
- The UPS uses driver `usbhid-ups`

### Use
Two options are available for setup:

1. Manual setup
```sh
cp nut/* /etc/nut
cd /etc/nut
chown -R root:nut /etc/nut/*
chmod 640 /etc/nut/*
sudo systemctl enable nut.service
sudo systemctl start nut.service
```
2. Automated setup using [`IMPORT.sh`](IMPORT.sh)




## Nvidia GPU Power Savings
[`nvidia-gpu-power-savings.service`](nvidia-gpu-power-savings.service)

This is a systemd service file which will lower the idle power consumption of your Nvidia GPU.

### Prerequisites
This script assumes:
- You have an Nvidia GPU
- You have proper Nvidia drivers installed
- Your Nvidia GPU is visible on nvidia-smi

### Use
Two options are available for setup:

1. Manual setup
```sh
cp nvidia-gpu-power-savings.service /etc/systemd/system
systemctl daemon-reload
systemctl enable nvidia-gpu-power-savings.service
systemctl start nvidia-gpu-power-savings.service
```
2. Automated setup using [`IMPORT.sh`](IMPORT.sh)




## Glances
[`glances.service`](glances.service)

This is a systemd service file which will start a glances webserver.

### Prerequisites
This script assumes:
- Glances and all relevant dependencies are installed
- Nothing is running on port 61208 (the default webserver port for glances)

### Use
Two options are available for setup:

1. Manual setup
```sh
cp glances.service /etc/systemd/system
systemctl daemon-reload
systemctl enable glances.service
systemctl start glances.service
```
2. Automated setup using [`IMPORT.sh`](IMPORT.sh)




## Nextcloud AI Task Processing
[`nextcloud-ai-worker@.service`](nextcloud-ai-worker@.service)

https://docs.nextcloud.com/server/latest/admin_manual/ai/overview.html#systemd-service

This script improves Nextcloud Assistant's AI task pickup speed responsiveness. By default, an assistant query will be processed as a background job, which is run every 5 minutes. This script, along with `nextcloud-ai-worker@.service`, processes AI tasks as soon as they are scheduled, rather than the user having to wait up to 5 minutes.

### Prerequisites
This script assumes:
- You have Nextcloud installed with Docker
- The Docker container name is 'nextcloud'
- A working Artificial Intelligence provider is configured

### Use
Two options are available for setup:

1. Manual setup

Modify the script path present in `nextcloud-ai-worker@.service`.

Then, run the following:

```sh
mv nextcloud-ai-worker@.service /etc/systemd/system
for i in {1..4}; do systemctl enable --now nextcloud-ai-worker@$i.service; done # Modify loop counter for however many workers you desire
```

2. Automated setup using [`IMPORT.sh`](IMPORT.sh)




## System Mail Transfer Agent
[`ssmtp.conf`](ssmtp.conf)

Once filled in, this configuration file will enable mail notifications from this system via `ssmtp`.

### Prerequisites
Before use, please:
- Install `ssmtp`
- Fill out credentials in `ssmtp.conf` file as the user with whom you would like to send mail

### Use
```sh
cp ssmtp.conf /etc/ssmtp
chmod 600 /etc/ssmtp/ssmtp.conf
```
