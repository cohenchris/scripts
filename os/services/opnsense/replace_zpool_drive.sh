#!/usr/bin/env bash

# Bail if attempting to substitute an unset variable
set -u

# Name of target ZFS pool
ZFS_POOL_NAME="zroot"

# Do not use full paths, just use device name (e.g. ada0 or ada1)

# OLD_BAD_DEVICE is the name of the bad device present in the ZFS pool>
# Run `zpool status` to find this, and do not include the partition number
# Example:
#
# > zpool status zroot
#
#  pool: zroot
#  state: DEGRADED
# status: One or more devices could not be opened.  Sufficient replicas exist for
#         the pool to continue functioning in a degraded state.
# action: Attach the missing device and online it using 'zpool online'.
#    see: https://openzfs.github.io/openzfs-docs/msg/ZFS-8000-2Q
#   scan: scrub repaired 0B in 00:00:20 with 0 errors on Mon Oct 27 21:57:27 2025
# config:
# 
#         NAME        STATE     READ WRITE CKSUM
#         zroot       DEGRADED     0     0     0
#           mirror-0  DEGRADED     0     0     0
#             ada0p4  UNAVAIL      0     0     0  cannot open
#             ada1p4  ONLINE       0     0     0
#
# In this case,
# OLD_BAD_DEVICE="ada0"
OLD_BAD_DEVICE=""

# Device name of the old ZFS pool drive which is still good
OLD_GOOD_DEVICE=""

# Device name of the new drive which will replace the old bad device
NEW_DEVICE=""

# Partition numbers obtained by running gpart show <device_name>
# Example:
#
# # gpart show ada1
#
# =>        40  1953525088  ada1  GPT  (932G)
#           40      532480     1  efi  (260M)
#       532520        1024     2  freebsd-boot  (512K)
#       533544         984        - free -  (492K)
#       534528    16777216     3  freebsd-swap  (8.0G)
#     17311744  1936211968     4  freebsd-zfs  (923G)
#   1953523712        1416        - free -  (708K)
#
# In this case,
# EFI_PARTITION_NUMBER="1"
# FREEBSD_BOOT_PARTITION_NUMBER="2"
# ZFS_PARTITION_NUMBER="4"

EFI_PARTITION_NUMBER=""
FREEBSD_BOOT_PARTITION_NUMBER=""
ZFS_PARTITION_NUMBER=""

# Detach old bad device from pool
zpool detach ${OLD_BAD_DEVICE}p${ZFS_PARTITION_NUMBER}

# Clone partition table from old device to new device
gpart backup ${OLD_GOOD_DEVICE} | gpart restore -F ${NEW_DEVICE}

# Clone EFI partition 1
dd if=/dev/${OLD_GOOD_DEVICE}${EFI_PARTITION_NUMBER} of=/dev/${NEW_DEVICE}p${EFI_PARTITION_NUMBER}

# Write bootcode to freebsd-boot partition 2
gpart bootcode -b /boot/pmbr -p /boot/gptzfsboot -i ${FREEBSD_BOOT_PARTITION_NUMBER} ${NEW_DEVICE}

# Attach ZFS partition 4 to existing ZFS pool
zpool attach ${ZFS_POOL_NAME} ${OLD_GOOD_DEVICE}p${ZFS_PARTITION_NUMBER} ${NEW_DEVICE}p4
