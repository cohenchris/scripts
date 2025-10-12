#!/bin/bash

WORKING_DIR=$(dirname "$(realpath "$0")")
source "${WORKING_DIR}/.env"

require var "${BATOCERA_HOST}"
require var "${BATOCERA_MAC}"


# batocera_mount(mount_dir)
#   mount_dir - directory at which we should mount the Batocera userdata directory
#
# Mount Batocera userdata directory to a local directory
function batocera_mount()
{
  local mount_dir=$1
  require var "${mount_dir}"

  if [ -n "$(ls -A "${mount_dir}" 2>/dev/null)" ]; then
    echo "ERROR: directory \"${mount_dir}\" is not empty, cannot mount..."
    exit 1
  fi

  echo "Sending wake command to \"${BATOCERA_HOST}\""
  wakeonlan "${BATOCERA_MAC}"

  echo "Mounting \"${BATOCERA_HOST}:/userdata\" at \"${mount_dir}\"..."
  mkdir -p "${mount_dir}"
  sshfs "${BATOCERA_HOST}:/userdata" "${mount_dir}"

  if [ $? -ne 0 ]; then
    echo "ERROR: Batocera mounting failed. Is the host up?"

    if [ -n "$(ls -A "${mount_dir}" 2>/dev/null)" ]; then
      echo "ERROR: directory \"${mount_dir}\" is not empty, cannot remove..."
    else
      rm -r "${mount_dir}"
    fi

    exit 1
  fi

  echo "Batocera successfully mounted at \"${mount_dir}\"!"
}


# batocera_unmount(mount_dir)
#   mount_dir - local directory where Batocera userdata directory is mounted
#
# Unmount Batocera userdata directory from local directory
function batocera_unmount()
{
  local mount_dir=$1
  require var "${mount_dir}"
  
  if [ ! -d "${mount_dir}" ]; then
    echo "Failed to unmount - directory \"${mount_dir} does not exist..."
    exit 1
  fi

  echo "Unmounting \"${mount_dir}\"..."
  umount "${mount_dir}"

  if [ $? -ne 0 ]; then
    echo "ERROR: failed to unmount \"${mount_dir}\"..."
    exit 1
  fi

  if [ -n "$(ls -A "${mount_dir}" 2>/dev/null)" ]; then
    echo "WARNING: directory \"${mount_dir}\" is not empty, cannot remove..."
  else
    echo "Removing directory \"${mount_dir}\"..."
    rm -r "${mount_dir}"
  fi
}


CMD=$1
MOUNT_DIR=$2

if ! [[ -n "${CMD}" && -n "${MOUNT_DIR}" ]]; then
  echo "Usage: batocera.sh [mount,unmount/umount] [mount_dir]"
  exit 1
fi

if [ "${CMD}" == "mount" ]; then
  batocera_mount "${MOUNT_DIR}"
elif [ "${CMD}" == "unmount" ] || [ "${CMD}" == "umount" ]; then
  batocera_unmount "${MOUNT_DIR}"
else
  echo "Usage: batocera.sh [mount,unmount/umount] [mount_dir]"
fi
