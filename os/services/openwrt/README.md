# OpenWRT Services

Custom services and scripts for a Linux-based OpenWRT distribution.




# Table of Contents

- [OpenWRT Fresh Install Setup](#OpenWRT-Fresh-Install-Setup)
  - [Use](#Use)




## OpenWRT Fresh Install Setup
[`setup.sh`](setup.sh)

Most settings will be restored from an OpenWRT backup.
This script completes a fresh install by modifying system settings which are not restored via OpenWRT backup restore.

### Use
Simply call this script from the command line:
```sh
./setup.sh
```
