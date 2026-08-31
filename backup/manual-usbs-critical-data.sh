#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e
# Bail if attempting to substitute an unset variable
set -u

# Set up environment
WORKING_DIR=$(dirname "$(realpath "$0")")
USB1_MNT_PATH=/mnt/usb1
USB2_MNT_PATH=/mnt/usb2
source "${WORKING_DIR}/.env"

# Name of the critical data directory as it will appear on the root of each USB
CRITICAL_DATA_DIR_NAME=$(basename "${CRITICAL_DATA_LOCAL_BACKUP_DIR}")

# Include bin/ directory from this repository in the system PATH
SCRIPTS_DIR=$(realpath "${WORKING_DIR}"/../bin)
export PATH="${PATH}:${SCRIPTS_DIR}"

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

require var "${USB1_DEV_NAME}"
require var "${USB2_DEV_NAME}"
require var "${CRITICAL_DATA_LOCAL_BACKUP_DIR}"
require var "${WORKING_DIR}"
require var "${BACKUP_CODES_PASS_FILE}"
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

# Ensure USBs are unmounted and temp mount directories are removed on exit,
# regardless of whether the script succeeds or aborts partway through
function cleanup()
{
  mountpoint -q "${USB1_MNT_PATH}" && umount "${USB1_MNT_PATH}"
  mountpoint -q "${USB2_MNT_PATH}" && umount "${USB2_MNT_PATH}"
  [[ -d "${USB1_MNT_PATH}" ]] && rmdir "${USB1_MNT_PATH}"
  [[ -d "${USB2_MNT_PATH}" ]] && rmdir "${USB2_MNT_PATH}"
}
trap cleanup EXIT

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
rm -r "${USB1_MNT_PATH:?}"/*
rm -r "${USB2_MNT_PATH:?}"/*

####################
#  COPY + DECRYPT  #
####################
# First, copy the base critical data backup to usb1. Copy the directory itself
# (not just its contents) so it lands as a subdirectory on the root of the drive.
echo
echo "Copying critical data backup to ${USB1_MNT_PATH}/${CRITICAL_DATA_DIR_NAME}..."
cp -r "${CRITICAL_DATA_LOCAL_BACKUP_DIR}" "${USB1_MNT_PATH}"

# Decrypt backup_codes.txt on usb1
BACKUP_CODES_PASSWORD=$(cat "${BACKUP_CODES_PASS_FILE}")
echo -e "${BACKUP_CODES_PASSWORD}\n:X\n\n\n:wq\n" | /usr/bin/vim -es -u NONE -i NONE "${USB1_MNT_PATH}/${CRITICAL_DATA_DIR_NAME}/mfa/backup_codes.txt"
unset BACKUP_CODES_PASSWORD

####################
#     CHECKSUM     #
####################
# Generate a checksum manifest of the critical data directory, stored alongside
# it in the parent directory (the root of the drive). Paths in the manifest are
# relative to the drive root so it can be verified in place with `sha256sum -c`.
echo
echo "Generating checksum manifest at ${USB1_MNT_PATH}/${CRITICAL_DATA_DIR_NAME}.sha256..."
( cd "${USB1_MNT_PATH}" && find "${CRITICAL_DATA_DIR_NAME}" -type f -exec sha256sum {} + | sort -k2 ) > "${USB1_MNT_PATH}/${CRITICAL_DATA_DIR_NAME}.sha256"

# Drop a short README describing how to verify the checksum manifest
cat <<EOF > "${USB1_MNT_PATH}/README.md"
# Critical data backup

This drive holds a backup of critical data in the \`${CRITICAL_DATA_DIR_NAME}/\`
directory. \`${CRITICAL_DATA_DIR_NAME}.sha256\` is a SHA-256 checksum manifest of
every file in that directory.

## Verifying the backup

From the root of this drive, run:

    sha256sum -c ${CRITICAL_DATA_DIR_NAME}.sha256

Every line should report \`OK\`. A \`FAILED\` line means that file no longer
matches the checksum recorded when the backup was made (corruption or
tampering); a \`No such file or directory\` line means a file is missing.

## Regenerating the manifest

If you intentionally change the contents of \`${CRITICAL_DATA_DIR_NAME}/\`, rebuild
the manifest from the root of this drive with:

    find ${CRITICAL_DATA_DIR_NAME} -type f -exec sha256sum {} + | sort -k2 > ${CRITICAL_DATA_DIR_NAME}.sha256
EOF

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
  echo "ERROR: ${USB1_MNT_PATH} is empty, backup failed..."
  exit 1
fi
if [ -z "$(ls -A "${USB2_MNT_PATH}")" ]; then
  echo "ERROR: ${USB2_MNT_PATH} is empty, backup failed..."
  exit 1
fi
echo "Done!"
echo
