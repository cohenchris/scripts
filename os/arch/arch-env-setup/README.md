
- [Network UPS Tools](#Network-UPS-Tools)
  - [Prerequisites](#Prerequisites)
  - [Use](#Use)
- [Nvidia GPU Power Savings](#Nvidia-GPU-Power-Savings)
  - [Prerequisites](#Prerequisites-1)
  - [Use](#Use-1)
- [Glances](#Glances)
  - [Prerequisites](#Prerequisites-2)
  - [Use](#Use-2)

  

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
2. Automated setup using [`arch-env-setup.sh`](../arch-env-setup.sh)




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
2. Automated setup using [`arch-env-setup.sh`](../arch-env-setup.sh)




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
2. Automated setup using [`arch-env-setup.sh`](../arch-env-setup.sh)
