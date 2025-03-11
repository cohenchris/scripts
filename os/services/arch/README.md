# Arch Linux Services

Custom services and configuration files for a typical Linux machine.
The import script is tailored towards Arch Linux, but these services should work on any systemd-based Linux distribution.




# Table of Contents

- [Network UPS Tools](#Network-UPS-Tools)
  - [Prerequisites](#Prerequisites)
  - [Use](#Use)
- [Nvidia GPU Power Savings](#Nvidia-GPU-Power-Savings)
  - [Prerequisites](#Prerequisites)
  - [Use](#Use)
- [Glances](#Glances)
  - [Prerequisites](#Prerequisites)
  - [Use](#Use)
- [Nextcloud AI Task Processing](#Nextcloud-AI-Task-Processing)
  - [Prerequisites](#Prerequisites)
  - [Use](#Use)
- [MSMTP SMTP client](#MSMTP-SMTP-client)
  - [Prerequisites](#Prerequisites)
  - [Use](#Use)




## Network UPS Tools
[`nut/*`](nut/)

Configuration files for the "Network UPS Tools" driver, which communicate with your UPS.

The default username is `upsmon` and password is `password`.

### Prerequisites
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




## MSMTP SMTP client
[`msmtprc`](msmtprc)

This is a configuration file for the `msmtp` SMTP client. This is what will allow email notifications to be sent automatically via cron jobs and privileged scripts.

### Prerequisites
Before configuring `msmtp`, please install the following:
- `msmtp`
- `msmtp-mta`

### Use
Two options are available for setup:

1. Manual setup

First, fill in the config file:
  - `<msmtp_host>` will be your SMTP URL
  - `<msmtp_user>` will be the email you would like to send mail as
  - `<msmtp_password>` will be the password for `<msmtp_user>`

Then, copy into the proper location + set permissions
```sh
cp ./msmtprc /etc/msmtprc
chown root:root /etc/msmtprc
chmod 600 /etc/msmtprc
```

2. Automated setup using [`IMPORT.sh`](IMPORT.sh)

This script will prompt you for your SMTP URL, email, and password.
Once provided, it will copy the config file so that it's visible to MSMTP, fill in your details, and set proper permissions.
