#!/bin/bash

WORKING_DIR=$(dirname "$(realpath "$0")")
source ${WORKING_DIR}/.env

require var BACKBLAZE_BUCKET

# b2_mount(mount_dir)
#   mount_dir - directory at which we should mount the Backblaze bucket
#
# Mount remote Backblaze bucket to a local directory
function b2_mount()
{
  local mount_dir="$1"

  require var mount_dir

  # Ensure that there is a proper config for "backblaze" with rclone
  local remotes=$(rclone listremotes)
  local found=0

  for remote in $remotes; do
      # Check if the string is in the current remote name
      if [[ "$remote" == "backblaze:" ]]; then
          found=1
          break
      fi
  done

  if [ ${found} -eq 0 ]; then
    echo "ERROR: No remote named \"backblaze\". Please create one using rclone config."
    exit 1
  fi
  
  if [ -n "$(ls -A ${mount_dir} 2>/dev/null)" ]; then
    echo "ERROR: directory \"${mount_dir}\" is not empty, cannot mount..."
    exit 1
  fi

  mkdir -p ${mount_dir}

  echo "Mounting Backblaze bucket ${BACKBLAZE_BUCKET}..."
  rclone mount backblaze:${BACKBLAZE_BUCKET} ${mount_dir} --daemon --vfs-cache-mode full

  if [ $? -ne 0 ]; then
    echo "ERROR: Backblaze mounting failed, please check rclone and .env configuration..."

    if [ -n "$(ls -A ${mount_dir} 2>/dev/null)" ]; then
      echo "ERROR: directory \"${mount_dir}\" is not empty, cannot remove..."
    else
      rm -r ${mount_dir}
    fi

    exit 1
  fi

  echo "Backblaze bucket \"${BACKBLAZE_BUCKET}\" successfully mounted at \"${mount_dir}\"!"
}


# b2_unmount(mount_dir)
#   mount_dir - local directory where Backblaze bucket is mounted
#
# Unmount Backblaze bucket from local directory
function b2_unmount()
{
  local mount_dir="$1"
  require var mount_dir

  if [ ! -d "${mount_dir}" ]; then
    echo "Failed to unmount - directory \"${mount_dir}\" does not exist..."
    exit 1
  fi

  echo "Unmounting Backblaze bucket ${BACKBLAZE_BUCKET}..."
  fusermount3 -u ${mount_dir}

  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to unmount \"${mount_dir}\"..."
    exit 1
  fi

  if [ -n "$( ls -A ${mount_dir} 2>/dev/null)" ]; then
    echo "WARNING: directory ${mount_dir} is not empty, cannot remove..."
  else
    echo "Removing directory ${mount_dir}..."
    rm -r ${mount_dir}
  fi
}


B2_FUSE_CMD=$1
B2_MOUNT_DIR=$2

if ! [[ -n "${B2_FUSE_CMD}" && -n "${B2_MOUNT_DIR}" ]]; then
  echo "Usage: b2-fuse.sh [mount,unmount/umount] [mount_dir]"
  exit 1
fi

if [ "${B2_FUSE_CMD}" == "mount" ]; then
  b2_mount ${B2_MOUNT_DIR}
elif [ "${B2_FUSE_CMD}" == "unmount" ] || [ "${B2_FUSE_CMD}" == "umount" ]; then
  b2_unmount ${B2_MOUNT_DIR}
else
  echo "Usage: b2-fuse.sh [mount,unmount/umount] [mount_dir]"
  exit 1
fi
