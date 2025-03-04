#!/bin/bash

WORKING_DIR=$(dirname "$(realpath "$0")")
source ${WORKING_DIR}/.env

require var BACKBLAZE_BUCKET

function b2_mount()
{
  BACKBLAZE_B2_MOUNT_DIR=$1
  require var BACKBLAZE_B2_MOUNT_DIR

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

  if [ $found -eq 0 ]; then
    echo "ERROR: No remote named \"backblaze\". Please create one using rclone config."
    exit 1
  fi
  
  if [ -n "$(ls -A ${BACKBLAZE_B2_MOUNT_DIR} 2>/dev/null)" ]; then
    echo "ERROR: directory ${BACKBLAZE_B2_MOUNT_DIR} is not empty, cannot mount..."
    exit 1
  fi

  mkdir -p ${BACKBLAZE_B2_MOUNT_DIR}

  echo "Mounting Backblaze bucket ${BACKBLAZE_BUCKET}..."
  rclone mount backblaze:${BACKBLAZE_BUCKET} ${BACKBLAZE_B2_MOUNT_DIR} --daemon --vfs-cache-mode full
}


function b2_unmount()
{
  BACKBLAZE_B2_MOUNT_DIR=$1
  require var BACKBLAZE_B2_MOUNT_DIR

  if [ ! -d "${BACKBLAZE_B2_MOUNT_DIR}" ]; then
    echo "Failed to unmount - directory \"${BACKBLAZE_B2_MOUNT_DIR}\" does not exist..."
    exit 1
  fi

  echo "Unmounting Backblaze bucket ${BACKBLAZE_BUCKET}..."
  fusermount3 -u ${BACKBLAZE_B2_MOUNT_DIR}

  if [ -n "$( ls -A ${BACKBLAZE_B2_MOUNT_DIR} 2>/dev/null)" ]; then
    echo "WARNING: directory ${BACKBLAZE_B2_MOUNT_DIR} is not empty, cannot remove..."
  else
    echo "Removing directory ${BACKBLAZE_B2_MOUNT_DIR}"
    rm -r ${BACKBLAZE_B2_MOUNT_DIR}
  fi
}


B2_FUSE_CMD=$1
B2_MOUNT_DIR=$2

if [ "${B2_MOUNT_DIR}" == "" ]; then
  echo "Usage: b2-fuse.sh [mount,unmount] [mount_dir]"
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
