# Systemd Services

This is a collection of various custom systemd services that I have created.

---

## Network UPS Tools
`nut/*`

This is a collection of configuration files which configure the "Network UPS Tools" systemd service and driver, which communicate with your UPS.

The default username is `upsmon` and password is `password`.

### Prerequisites
This script assumes:
- There is a UPS connected to your computer via USB
- The UPS uses driver `usbhid-ups`

### Setup
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
2. Automated setup using `import-services.sh`


## Nvidia GPU Power Savings
`nvidia-gpu-power-savings.service`

This is a systemd service file which will lower the idle power consumption of your Nvidia GPU.

### Prerequisites
This script assumes:
- You have an Nvidia GPU
- You have proper Nvidia drivers installed
- Your Nvidia GPU is visible on nvidia-smi

### Setup
Two options are available for setup:

1. Manual setup
```sh
cp nvidia-gpu-power-savings.service /etc/systemd/system
systemctl daemon-reload
systemctl enable nvidia-gpu-power-savings.service
systemctl start nvidia-gpu-power-savings.service
```
2. Automated setup using `import-services.sh`


## Glances
`glances.service`

This is a systemd service file which will start a glances webserver.

### Prerequisites
This script assumes:
- Glances and all relevant dependencies are installed
- Nothing is running on port 61208 (the default webserver port for glances)

### Setup
Two options are available for setup:

1. Manual setup
```sh
cp glances.service /etc/systemd/system
systemctl daemon-reload
systemctl enable glances.service
systemctl start glances.service
```
2. Automated setup using `import-services.sh`


## Nextcloud AI Task Processing
`nextcloud-ai-taskprocessing.sh`

https://docs.nextcloud.com/server/latest/admin_manual/ai/overview.html#systemd-service

This script improves Nextcloud Assistant's AI task pickup speed responsiveness. By default, an assistant query will be processed as a background job, which is run every 5 minutes. This script, along with `nextcloud-ai-worker@.service`, processes AI tasks as soon as they are scheduled, rather than the user having to wait up to 5 minutes.

### Prerequisites
This script assumes:
- You have Nextcloud installed with Docker
- The Docker container name is 'nextcloud'
- A working Artificial Intelligence provider is configured

### Setup
Two options are available for setup:

1. Manual setup

Modify the script path present in `nextcloud-ai-worker@.service` and move it to the systemd services folder:

```sh
mv nextcloud-ai-worker@.service /etc/systemd/system
```

Then, enable and start the service 4 or more times:

```sh
for i in {1..4}; do systemctl enable --now nextcloud-ai-worker@$i.service; done
```

Check the status for success and ensure the workers have been deployed:

```sh
systemctl status nextcloud-ai-worker@1.service
systemctl list-units --type=service | grep nextcloud-ai-worker
```

2. Automated setup using `import-services.sh`


## System Mail Transfer Agent
`ssmtp.conf`

Once filled in, this configuration file will enable mail notifications from this system via `ssmtp`.

### Prerequisites
Before use, please:
- Install `ssmtp`
- Fill out credentials in `ssmtp.conf` file as the user with whom you would like to send mail

### Setup
```sh
cp ssmtp.conf /etc/ssmtp
chmod 600 /etc/ssmtp/ssmtp.conf
```
