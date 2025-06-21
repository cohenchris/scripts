#!/bin/bash

####################
#    DECLARATION   #
####################

# Sourcing .env will redirect all output to a log file
# We do NOT want this here, so save the original file
# descriptors before sourcing .env
exec 3>&1
exec 4>&2

# Set up environment
WORKING_DIR=$(dirname "$(realpath "$0")")
USB1_MNT_PATH=/mnt/usb1
USB2_MNT_PATH=/mnt/usb2
source "${WORKING_DIR}/.env"

# Restore original file descriptors and remove log/mail files
exec 1>&3 3>&-
exec 2>&4
rm "${LOG_FILE}"
rm "${MAIL_FILE}"

# List devices
fdisk -l

echo
echo "########################################"
echo "#           ***WARNING***              #"
echo "#    MAKE ABSOLUTELY SURE THAT THE     #"
echo "#  DEVICE NAMES ARE CORRECT, OR YOU    #"
echo "#     RISK CATASTROPHIC DATA LOSS      #"
echo "########################################"

# Ask for USB device name #1
echo
read -p "Enter USB device name #1 (in the format /dev/sdX): " USB1_DEV_NAME

# Ask for USB device name #2
echo
read -p "Enter USB device name #2 (in the format /dev/sdX): " USB2_DEV_NAME

# Confirm choices
echo
fdisk -l "${USB1_DEV_NAME}"
echo
fdisk -l "${USB2_DEV_NAME}"
echo

require var USB1_DEV_NAME
require var USB2_DEV_NAME
require var CRITICAL_DATA_LOCAL_BACKUP_DIR
require var WORKING_DIR
require var BACKUP_CODES_PASS_FILE
require file "${BACKUP_CODES_PASS_FILE}"

read -p "Are these devices correct? (y/N) " yn

case "${yn}" in
  [Yy]* ) ;;
  *     ) exit;;
esac

####################
#       SETUP      #
####################
# Create temp directories for USBs
echo
echo "Creating temporary mount directories for USBs..."

if [[ ! -d "${USB1_MNT_PATH}" ]]; then
  mkdir "${USB1_MNT_PATH}"
else
  echo "ERROR: ${USB1_MNT_PATH} already exists. Please remove this directory before running this script."
  exit 1
fi

if [[ ! -d "${USB2_MNT_PATH}" ]]; then
  mkdir "${USB2_MNT_PATH}"
else
  echo "ERROR: ${USB2_MNT_PATH} already exists. Please remove this directory before running this script."
  exit 1
fi

# Mount provided devices to their temporary mount directories
echo "Mounting ${USB1_DEV_NAME} to ${USB1_MNT_PATH}..."

mount "${USB1_DEV_NAME}" "${USB1_MNT_PATH}"
MOUNT_STATUS=$?

if [[ "${MOUNT_STATUS}" -ne 0 ]]; then
  echo "ERROR: Mounting ${USB1_DEV_NAME} to ${USB1_MNT_PATH} failed with error code ${MOUNT_STATUS}..."
  exit 1
fi

echo
echo "Mounting ${USB2_DEV_NAME} to ${USB2_MNT_PATH}..."
mount "${USB2_DEV_NAME}" "${USB2_MNT_PATH}"
MOUNT_STATUS=$?
if [[ "${MOUNT_STATUS}" -ne 0 ]]; then
  echo "ERROR: Mounting ${USB2_DEV_NAME} to ${USB2_MNT_PATH} failed with error code ${MOUNT_STATUS}..."
  exit 1
fi

# Clear both USBs
echo
echo "Clearing USBs..."
rm -r "${USB1_MNT_PATH}"/*
rm -r "${USB2_MNT_PATH}"/*

####################
#  COPY + DECRYPT  #
####################
# First, copy base critical data backup to usb1
echo
echo "Copying critical data backup to ${USB1_MNT_PATH}..."
cp -r "${CRITICAL_DATA_LOCAL_BACKUP_DIR}"/* "${USB1_MNT_PATH}"

# Decrypt backup_codes.txt on usb1
BACKUP_CODES_PASSWORD=$(cat "${BACKUP_CODES_PASS_FILE}")
echo -e "${BACKUP_CODES_PASSWORD}\n:X\n\n\n:wq\n" | /usr/bin/vim "${USB1_MNT_PATH}/backup_codes.txt"
unset BACKUP_CODES_PASSWORD

####################
#       CLONE      #
####################
# Clone final contents of usb1 to usb2
echo
echo "Cloning contents of ${USB1_MNT_PATH} to ${USB2_MNT_PATH}..."
cp -r "${USB1_MNT_PATH}"/* "${USB2_MNT_PATH}"

# Verify that backups have been copied to both drives
echo
if [ -z "$(ls -A "${USB1_MNT_PATH}")" ]; then
  echo "ERROR: "${USB1_MNT_PATH}" is empty, backup failed..."
  exit 1
fi
if [ -z "$(ls -A "${USB2_MNT_PATH}")" ]; then
  echo "ERROR: "${USB2_MNT_PATH}" is empty, backup failed..."
  exit 1
fi
echo "Done!"
echo

####################
#      CLEANUP     #
####################
echo
echo "Cleaning up..."
umount "${USB1_MNT_PATH}"
umount "${USB2_MNT_PATH}"

rm -r "${USB1_MNT_PATH}"
rm -r "${USB2_MNT_PATH}"
