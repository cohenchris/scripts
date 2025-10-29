# OpenWRT Services

Custom scripts, services, and configuration files for a Linux-based OpenWRT distribution.




# Table of Contents

- [OpenWRT Fresh Install Setup](#OpenWRT-Fresh-Install-env-setup)
  - [Use](#Use)




## OpenWRT Fresh Install Setup
[`openwrt-env-setup.sh`](openwrt-env-setup.sh)

Most settings will be restored from an OpenWRT backup.
This script completes a fresh install by modifying system settings which are not restored via OpenWRT backup restore.

### Use
Simply call this script from the command line:
```sh
./openwrt-env-setup.sh
```
