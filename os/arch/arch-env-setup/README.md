
- [Network UPS Tools](#Network-UPS-Tools)
  - [Prerequisites](#Prerequisites)
  - [Use](#Use)
- [Glances](#Glances)
  - [Prerequisites](#Prerequisites-1)
  - [Use](#Use-1)

  

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
