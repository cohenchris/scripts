#!/bin/bash

####################
#    DECLARATION   #
####################
# Require sudo
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
  echo "ERROR: This script must be run as root."
  exit
fi

STARTING_DIR=$(pwd)
echo $STARTING_DIR

WORKING_DIR=$(dirname "$(realpath "$0")")

# List devices
fdisk -l

echo "########################################"
echo "#           ***WARNING***              #"
echo "#    MAKE ABSOLUTELY SURE THAT THE     #"
echo "#  DEVICE NAMES ARE CORRECT, OR YOU    #"
echo "#     RISK CATASTROPHIC DATA LOSS      #"
echo "########################################"
echo

# Ask for USB device name #1
echo "Enter USB device name #1 (in the format /dev/sdX):"
read DEV_NAME_1
echo

# Ask for USB device name #2
echo "Enter USB device name #2 (in the format /dev/sdX):"
read DEV_NAME_2
echo

####################
#       SETUP      #
####################
# Create temp directories for USBs
echo "Creating temp directories for USBs"
if [[ ! -d "/mnt/usb1" ]]; then
  mkdir /mnt/usb1
else
  echo "ERROR: /mnt/usb1 already exists..."
  exit
fi

if [[ ! -d "/mnt/usb2" ]]; then
  mkdir /mnt/usb2
else
  echo "ERROR: /mnt/usb2 already exists..."
  exit
fi

# Mount provided devices to the /mnt directories
echo "Mounting $DEV_NAME_1"
mount $DEV_NAME_1 /mnt/usb1 || exit

echo "Mounting $DEV_NAME_2"
mount $DEV_NAME_2 /mnt/usb2 || exit

# Clear both USBs
echo "Clearing USBs"
rm -r /mnt/usb1/*
rm -r /mnt/usb2/*

####################
#  COPY + DECRYPT  #
####################
# First, copy base misc backup to usb1
echo "Copying misc backup to usb1"
cd /mnt/usb1
cp -r /backups/misc/* .

cd passwords

# Decrypt backup_codes.txt
BACKUP_CODES_PASSWORD=$(cat $WORKING_DIR/backupcodespass)
echo -e "${BACKUP_CODES_PASSWORD}\n:X\n\n\n:wq\n" | /usr/bin/vim backup_codes.txt
unset BACKUP_CODES_PASSWORD

# Decrypt + extract raivo backup
ZIPPASS=$(sed -n '5{s/^[[:space:]]*//;s/[[:space:]]*$//;p;q}' backup_codes.txt)
7z x -p"$ZIPPASS" raivo-otp-export.zip
unset ZIPPASS

cd /mnt

####################
#       CLONE      #
####################
# Clone final contents of usb1 to usb2
echo "Cloning contents of usb1 to usb2"
cp -r /mnt/usb1/* /mnt/usb2/

echo "Contents of USBs:"
ls -R .

####################
#      CLEANUP     #
####################
echo "Cleaning up"
umount /mnt/usb1
umount /mnt/usb2

rm -r /mnt/usb1
rm -r /mnt/usb2

cd $STARTING_DIR
