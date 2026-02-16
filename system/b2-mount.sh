#!/usr/bin/env bash

# Initialize environment
WORKING_DIR=$(dirname "$(realpath "$0")")
source ${WORKING_DIR}/.env


# print_remote_buckets(rclone_remote)
#   rclone_remote - Backblaze B2 rclone remote config
#
# Print all buckets present in ${rclone_remote}
function print_remote_buckets()
{
  local rclone_remote="${1}"

  require var "${rclone_remote}"

  # Print each available bucket on the remote
  echo "Available buckets:"
  rclone lsd "${rclone_remote}" | awk '{print $5}' | sed 's/^/\t/'
}


# validate_remote(rclone_remote)
#   rclone_remote - Backblaze B2 rclone remote config
#
# Validate that there exists an rclone remote config ${rclone_remote}
function validate_remote()
{
  local rclone_remote="${1}"

  local remotes=$(rclone listremotes)
  local found=0

  for remote in ${remotes}; do
      # Check if the string is in the current remote name
      if [[ "${remote}" == "${rclone_remote}" ]]; then
          found=1
          break
      fi
  done

  if [[ "${found}" -eq 0 ]]; then
    echo "ERROR: No remote named \"${rclone_remote}\". Please create one using rclone config."
    exit 1
  else
    echo "Remote \"${rclone_remote}\" exists!"
  fi
}


# validate_bucket(rclone_remote, remote_bucket)
#   rclone_remote - Backblaze B2 rclone remote config
#   remote_bucket - Backblaze B2 bucket to mount
#
# Validate that there exists a Backblaze B2 bucket (directory) ${remote_bucket} on rclone remote config ${rclone_remote}
function validate_bucket()
{
  local rclone_remote="${1}"
  local remote_bucket="${2}"

  require var "${rclone_remote}"

  # Check if ${remote_bucket} is specified
  if [[ -z "${remote_bucket}" ]]; then
    echo "ERROR: mount bucket not specified..."
    print_remote_buckets "${rclone_remote}"
    exit 1
  fi

  # Check that there is a bucket ${remote_bucket} in ${rclone_remote}
  rclone lsd ${rclone_remote}${remote_bucket} > /dev/null 2>&1

  if [[ $? -ne 0 ]]; then
    echo "ERROR: mount bucket \"${remote_bucket}\" not available on remote \"${rclone_remote}\""
    print_remote_buckets "${rclone_remote}"
    exit 1
  fi

  echo "Remote bucket \"${remote_bucket}\" exists on remote \"${rclone_remote}\"!"
}


# validate_mount_dir(mount_dir)
#   mount_dir - directory to which we will mount remote Backblaze bucket
#
# Validate that ${mount_dir} is empty or does not yet exist, then create it
function validate_mount_dir()
{
  local mount_dir="${1}"

  require var "${mount_dir}"

  if [[ -n "$(ls -A "${mount_dir}" 2>/dev/null)" ]]; then
    echo "ERROR: directory \"${mount_dir}\" is not empty, cannot mount..."
    exit 1
  fi

  mkdir -p "${mount_dir}"
}


# b2_mount(mount_dir)
#   rclone_remote - Backblaze B2 rclone remote config
#   remote_bucket - Backblaze B2 bucket to mount
#   mount_dir     - directory at which we should mount the Backblaze B2 bucket
#
# Mount remote Backblaze bucket to a local directory
function b2_mount()
{
  local rclone_remote="${1}"
  local remote_bucket="${2}"
  local mount_dir="${3}"

  # Validate that there exists an rclone remote config ${rclone_remote}
  validate_remote "${rclone_remote}"

  # Validate that there exists a Backblaze B2 bucket (directory) ${remote_bucket} on rclone remote config ${rclone_remote}
  validate_bucket "${rclone_remote}" "${remote_bucket}"

  # Validate that ${mount_dir} is empty or does not yet exist, then create it
  validate_mount_dir "${mount_dir}"
  
  # Mount ${remote_bucket} in ${rclone_remote} at ${mount_dir}
  echo "Attempting to mount Backblaze bucket \"${remote_bucket}\"..."
  rclone mount "${rclone_remote}${remote_bucket}" "${mount_dir}" --daemon --vfs-cache-mode full

  if [[ $? -ne 0 ]]; then
    echo "ERROR: Backblaze mounting failed, please check rclone and .env configuration..."

    if [ -n "$(ls -A "${mount_dir}" 2>/dev/null)" ]; then
      echo "ERROR: directory \"${mount_dir}\" is not empty, cannot remove..."
    else
      rm -r "${mount_dir}"
    fi

    exit 1
  fi

  echo "Backblaze bucket \"${remote_bucket}\" from remote \"${rclone_remote}\" successfully mounted at \"${mount_dir}\"!"
}


# b2_unmount(mount_dir)
#   mount_dir - local directory where Backblaze bucket is mounted
#
# Unmount Backblaze bucket from local directory
function b2_unmount()
{
  local mount_dir="${1}"
  require var "${mount_dir}"

  if [[ ! -d "${mount_dir}" ]]; then
    echo "Failed to unmount - directory \"${mount_dir}\" does not exist..."
    exit 1
  fi

  # Check if something is mounted at ${mount_dir}
  mountpoint "${mount_dir}" > /dev/null 2>&1

  if [[ $? -ne 0 ]]; then
    echo "ERROR: Nothing is currently mounted at directory \"${mount_dir}\"..."
    exit 1
  fi

  echo "Attempting to unmount Backblaze bucket..."
  fusermount3 -u "${mount_dir}"

  if [[ $? -ne 0 ]]; then
    echo "ERROR: Failed to unmount bucket at directory \"${mount_dir}\"..."
    exit 1
  else
    echo "Successfully unmounted bucket at directory \"${mount_dir}\"!"
  fi

  if [[ -n "$( ls -A "${mount_dir}" 2>/dev/null)" ]]; then
    echo "WARNING: directory \"${mount_dir}\" is not empty, cannot remove..."
  else
    echo "Removing directory \"${mount_dir}\"..."
    rm -r "${mount_dir}"
  fi
}


# Main execution
CMD="${1}"

if ! [[ -n "${CMD}" ]]; then
  echo "Usage: b2-mount.sh mount [bucket] [mount_dir]"
  echo "       b2-mount.sh unmount [mount_dir]"
  exit 1
fi

if [[ "${CMD}" == "mount" ]]; then
  REMOTE_BUCKET="${2}"
  MOUNT_DIR="${3}"
  b2_mount "${B2_RCLONE_REMOTE}" "${REMOTE_BUCKET}" "${MOUNT_DIR}"
elif [[ "${CMD}" == "unmount" ]] || [[ "${CMD}" == "umount" ]]; then
  MOUNT_DIR="${2}"
  b2_unmount "${MOUNT_DIR}"
else
  echo "Usage: b2-mount.sh mount [remote_bucket] [mount_dir]"
  echo "       b2-mount.sh unmount [mount_dir]"
  exit 1
fi
