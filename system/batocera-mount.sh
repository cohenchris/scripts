#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e
# Bail if attempting to substitute an unset variable
set -u

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
  require dir "${mount_dir}"
  mount_dir=$(realpath "${mount_dir}")

  if [ -n "$(ls -A "${mount_dir}" 2>/dev/null)" ]; then
    echo "ERROR: directory \"${mount_dir}\" is not empty, cannot mount..."
    exit 1
  fi

  echo "Sending wake command to \"${BATOCERA_HOST}\""
  wakeonlan "${BATOCERA_MAC}"

  echo "Mounting \"${BATOCERA_HOST}:/userdata\" at \"${mount_dir}\"..."
  local mount_cmd="sshfs ${BATOCERA_HOST}:/userdata ${mount_dir}"

  if ! eval "${mount_cmd}"; then
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
  require dir "${mount_dir}"
  mount_dir=$(realpath "${mount_dir}")
  
  if [ ! -d "${mount_dir}" ]; then
    echo "Failed to unmount - directory \"${mount_dir} does not exist..."
    exit 1
  fi

  echo "Unmounting \"${mount_dir}\"..."
  local umount_cmd="umount ${mount_dir}"

  if ! eval "${umount_cmd}"; then
    echo "ERROR: failed to unmount \"${mount_dir}\"..."
    exit 1
  fi

  echo "Batocera successfully umounted from \"${mount_dir}\"!"
}


CMD=$1
MOUNT_DIR=$2

if ! [[ -n "${CMD}" && -n "${MOUNT_DIR}" ]]; then
  echo "Usage: batocera-mount.sh [mount,unmount/umount] [mount_dir]"
  exit 1
fi

if [ "${CMD}" == "mount" ]; then
  batocera_mount "${MOUNT_DIR}"
elif [ "${CMD}" == "unmount" ] || [ "${CMD}" == "umount" ]; then
  batocera_unmount "${MOUNT_DIR}"
else
  echo "Usage: batocera-mount.sh [mount,unmount/umount] [mount_dir]"
fi
