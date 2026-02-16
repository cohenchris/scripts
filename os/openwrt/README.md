# OpenWRT Services

Custom scripts, services, and configuration files for a machine running the Linux-based OpenWRT distribution.




# Table of Contents

- [OpenWRT Fresh Install Setup](#OpenWRT-Fresh-Install-env-setup)
  - [Use](#Use)




## OpenWRT Fresh Install Setup
[`openwrt-env-setup.sh`](openwrt-env-setup.sh)

When updating OpenWRT, most settings are restored, but some are wiped.
This script completes a fresh install by modifying system settings which are not restored via OpenWRT backup restore.

### Use
Call this script from the command line:
```sh
./openwrt-env-setup.sh
```
