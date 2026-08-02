#!/usr/bin/env bash
#
# Disaster recovery script for the 'backups' ZFS pool.
#
# Usage:
#   backups.sh fresh    # drive is gone - rebuild the pool from scratch
#   backups.sh replace  # swap a still-working drive for a new one
#
# Both actions are destructive to the device(s) they operate on and will
# prompt for confirmation before wiping anything.
#
# This script can also be sourced instead (`source backups.sh`) to pull in
# recreate_from_nothing() and replace_drive() without triggering either one.

########################
# DEBUG MODE           #
########################
# Set DEBUG=1 to dry-run every command that would modify the system
# (partitioning, pool creation/replacement, ownership changes). DEBUG=0
# (the default) runs for real. Every command run() handles is always logged
# either way.
DEBUG=1

# run(cmd...)
#
# Logs the exact command being run, then executes it - or, if DEBUG=1, logs
# it and skips execution so nothing is modified on the system.
function run()
{
  echo "[CMD] $*"
  if [[ "${DEBUG}" == "1" ]]; then
    echo "[DRY-RUN] skipping execution (DEBUG=1)"
    return 0
  fi
  "$@"
}

########################
# DEVICE SELECTION     #
########################

# select_new_device(result_var)
#   result_var - name of the caller's variable to store the chosen by-id
#                device path into
#
# Lists every disk on the system with its resolved by-id path, size, and
# model (flagging any already in use by an existing pool), then prompts the
# user to pick one by number instead of typing a path by hand.
function select_new_device()
{
  local -n __select_new_device_result="$1"

  local -a byids
  local line NAME SIZE MODEL SERIAL FSTYPE TYPE
  local i=0

  # Resolve every device currently used by any pool to its canonical path
  # (e.g. /dev/sda) so it can be matched regardless of which by-id alias the
  # pool happens to reference.
  local -a pool_devs
  mapfile -t pool_devs < <(
    zpool status -P 2>/dev/null \
      | grep -oE '/dev/disk/by-id/[^[:space:]]+' \
      | sed -E 's/-part[0-9]+$//' \
      | while IFS= read -r p; do readlink -f "${p}"; done \
      | sort -u
  )

  echo "---------- Available disks ----------"
  while IFS= read -r line; do
    eval "${line}"
    [[ "${TYPE}" != "disk" ]] && continue

    local byid
    byid="$(find /dev/disk/by-id -maxdepth 1 -not -name '*-part*' -lname "*/${NAME}" 2>/dev/null | grep -m1 '/wwn-')"
    [[ -z "${byid}" ]] && byid="$(find /dev/disk/by-id -maxdepth 1 -not -name '*-part*' -lname "*/${NAME}" 2>/dev/null | head -n1)"
    [[ -z "${byid}" ]] && byid="/dev/${NAME}"

    local realdev in_use=""
    realdev="$(readlink -f "${byid}")"
    local pd
    for pd in "${pool_devs[@]}"; do
      if [[ "${pd}" == "${realdev}" ]]; then
        in_use="  [IN USE by an existing pool]"
        break
      fi
    done

    i=$((i + 1))
    byids[${i}]="${byid}"
    printf "  %d) %-58s %8s  %s%s\n" "${i}" "${byid}" "${SIZE}" "${MODEL}" "${in_use}"
  done < <(lsblk -dn -P -o NAME,SIZE,MODEL,SERIAL,FSTYPE,TYPE)
  echo "----------------------------------------------------"

  if [[ "${i}" -eq 0 ]]; then
    echo "ERROR: no disks found"
    return 1
  fi

  local choice
  read -p "Select device number: " choice

  if ! [[ "${choice}" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > i )); then
    echo "ERROR: invalid selection"
    return 1
  fi

  __select_new_device_result="${byids[${choice}]}"
}


# select_pool_device(result_var, pool_name)
#   result_var - name of the caller's variable to store the chosen by-id
#                device path into
#   pool_name  - pool to list the current member devices of
#
# Lists the devices currently in the given pool and prompts the user to pick
# one by number instead of typing a path by hand.
function select_pool_device()
{
  local -n __select_pool_device_result="$1"
  local pool_name="$2"

  local -a devices
  mapfile -t devices < <(zpool status -P "${pool_name}" 2>/dev/null | grep -oE '/dev/disk/by-id/[^[:space:]]+' | sed -E 's/-part[0-9]+$//' | sort -u)

  if [[ "${#devices[@]}" -eq 0 ]]; then
    echo "ERROR: could not determine current devices for pool '${pool_name}'"
    return 1
  fi

  echo "---------- Devices currently in pool '${pool_name}' ----------"
  local idx
  for idx in "${!devices[@]}"; do
    printf "  %d) %s\n" "$((idx + 1))" "${devices[${idx}]}"
  done
  echo "----------------------------------------------------------------"

  local choice
  read -p "Select device number: " choice

  if ! [[ "${choice}" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#devices[@]} )); then
    echo "ERROR: invalid selection"
    return 1
  fi

  __select_pool_device_result="${devices[$((choice - 1))]}"
}

########################
# POOL CONFIGURATION   #
########################
POOL_NAME="backups"
MOUNTPOINT="/backups"

# ashift=12 matches modern 4Kn/512e drives - a safe default for any current
# or replacement drive. The original pool left ashift on auto-detect.
ASHIFT=12

# Ownership to restore on the pool's mountpoint after creation.
OWNER="root"
GROUP="root"

# Remote backup server - referenced only for the informational message in
# recreate_from_nothing() below.
REMOTE_BACKUP_SERVER="backups@backups.lan"


# recreate_from_nothing()
#
# Rebuilds the 'backups' pool from a blank/replacement drive.
function recreate_from_nothing()
{
  [[ "${DEBUG}" == "1" ]] && echo "[DEBUG] DRY-RUN MODE ENABLED - no changes will be made to the system"

  if [[ "$(id -u)" -ne 0 ]]; then
    echo "ERROR: must be run as root"
    return 1
  fi

  if zpool list "${POOL_NAME}" &>/dev/null; then
    if [[ "${DEBUG}" == "1" ]]; then
      echo "[DEBUG] pool '${POOL_NAME}' already exists - continuing anyway since DEBUG is set"
    else
      echo "ERROR: pool '${POOL_NAME}' already exists - destroy it first if this is really what you want"
      return 1
    fi
  fi

  local device
  select_new_device device || return 1

  echo "########################################"
  echo "#              ***WARNING***          #"
  echo "#  THIS WILL DESTROY ALL DATA ON THE  #"
  echo "#  FOLLOWING DEVICE AND RECREATE THE  #"
  echo "#  '${POOL_NAME}' POOL FROM SCRATCH:"
  echo "#    ${device}"
  echo "########################################"
  read -p "Device correct and OK to wipe? (y/N) " yn
  case "${yn}" in
    [Yy]* ) ;;
    *     ) echo "Aborted."; return 1 ;;
  esac

  # Destroy all existing partitions on the target device - it cannot be
  # assumed to be blank
  echo "Wiping ${device}..."
  run sgdisk --zap-all "${device}"
  [[ $? -ne 0 ]] && echo "ERROR: failed to wipe ${device}" && return 1

  # zpool partitions the whole disk itself, no manual partitioning needed
  echo "Creating pool '${POOL_NAME}'..."
  run zpool create -f \
    -o ashift="${ASHIFT}" \
    -o autoexpand=on \
    -O compression=lz4 \
    -O atime=off \
    -O relatime=on \
    -O xattr=sa \
    -O acltype=posixacl \
    -O dnodesize=auto \
    "${POOL_NAME}" "${device}"
  [[ $? -ne 0 ]] && echo "ERROR: zpool create failed" && return 1

  run chown "${OWNER}:${GROUP}" "${MOUNTPOINT}"

  echo "-------------------------------------------------------------"
  echo "Nothing to restore for the '${POOL_NAME}' pool."
  echo "This pool IS the local borg repository store (holds"
  echo "/backups/files, /backups/music, /backups/server,"
  echo "/backups/critical-data, /backups/musicvideos). There is no"
  echo "borg backup of this pool's own contents - the only other copy"
  echo "of this data lives on the remote backup server"
  echo "(${REMOTE_BACKUP_SERVER}). Restore from there manually if needed."
  echo "-------------------------------------------------------------"

  echo "Done. Pool '${POOL_NAME}' is ready."
}


# replace_drive([old_device], [new_device])
#   old_device - by-id path of the still-working drive currently in the pool
#                (optional - prompted for if omitted)
#   new_device - by-id path of the new, blank replacement drive
#                (optional - prompted for if omitted)
#
# Clones the live pool data from old_device onto new_device (via a ZFS
# resilver) and removes old_device from the pool.
function replace_drive()
{
  local old_device="$1"
  local new_device="$2"

  [[ "${DEBUG}" == "1" ]] && echo "[DEBUG] DRY-RUN MODE ENABLED - no changes will be made to the system"

  if [[ "$(id -u)" -ne 0 ]]; then
    echo "ERROR: must be run as root"
    return 1
  fi

  if ! zpool list "${POOL_NAME}" &>/dev/null; then
    echo "ERROR: pool '${POOL_NAME}' does not exist"
    return 1
  fi

  echo "---------- Current '${POOL_NAME}' pool layout ----------"
  zpool status "${POOL_NAME}"
  echo "----------------------------------------------------------"
  echo

  if [[ -z "${old_device}" ]]; then
    select_pool_device old_device "${POOL_NAME}" || return 1
  fi
  if [[ -z "${new_device}" ]]; then
    select_new_device new_device || return 1
  fi

  if ! zpool status "${POOL_NAME}" | grep -q "$(basename "${old_device}")"; then
    echo "ERROR: ${old_device} does not appear to be part of pool '${POOL_NAME}'"
    return 1
  fi

  if [[ ! -e "${new_device}" ]]; then
    echo "ERROR: device ${new_device} not found"
    return 1
  fi

  # The new device must be at least as large as the old one - ZFS itself
  # would refuse the replace, but check up front so we fail with a clear
  # message before wiping anything.
  local old_size new_size
  old_size="$(blockdev --getsize64 "${old_device}" 2>/dev/null)"
  new_size="$(blockdev --getsize64 "${new_device}" 2>/dev/null)"

  if [[ -z "${old_size}" || -z "${new_size}" ]]; then
    echo "ERROR: could not determine device size(s) to compare ${old_device} and ${new_device}"
    return 1
  fi

  if (( new_size < old_size )); then
    echo "ERROR: new device ${new_device} ($(numfmt --to=iec "${new_size}")) is smaller than old device ${old_device} ($(numfmt --to=iec "${old_size}")) - refusing to replace"
    return 1
  fi

  echo "########################################"
  echo "#              ***WARNING***          #"
  echo "#  THIS WILL DESTROY ALL DATA ON:"
  echo "#    ${new_device}"
  echo "#  AND REPLACE ${old_device}"
  echo "#  WITH IT IN POOL '${POOL_NAME}'."
  echo "########################################"
  read -p "Devices correct and OK to proceed? (y/N) " yn
  case "${yn}" in
    [Yy]* ) ;;
    *     ) echo "Aborted."; return 1 ;;
  esac

  # New drive cannot be assumed blank - wipe it first
  echo "Wiping ${new_device}..."
  run sgdisk --zap-all "${new_device}"
  [[ $? -ne 0 ]] && echo "ERROR: failed to wipe ${new_device}" && return 1

  # zpool replace clones the live data from old_device onto new_device via a
  # resilver while the pool stays online; once the resilver finishes,
  # old_device is automatically dropped from the pool.
  echo "Replacing ${old_device} -> ${new_device} in pool '${POOL_NAME}'..."
  run zpool replace -f "${POOL_NAME}" "${old_device}" "${new_device}"
  [[ $? -ne 0 ]] && echo "ERROR: zpool replace failed" && return 1

  echo "Waiting for resilver to complete..."
  run zpool wait -t resilver "${POOL_NAME}"

  # If new_device is larger than what it replaced, claim the extra space.
  # Pools created by recreate_from_nothing() have autoexpand=on and would
  # pick this up automatically, but this is done explicitly as a safety net
  # for pools created before that, or outside these scripts entirely.
  echo "Expanding pool to use any additional capacity on ${new_device} (if any)..."
  run zpool online -e "${POOL_NAME}" "${new_device}"

  zpool status "${POOL_NAME}"
  echo "Done. Verify the status above shows ONLINE with no errors, then physically remove ${old_device}."
}


########
# MAIN #
########

# usage()
#
# Prints the help menu.
function usage()
{
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") <fresh|replace>

  fresh    Recreate the '${POOL_NAME}' pool from nothing - use this when the
           drive is gone entirely (calls recreate_from_nothing).
  replace  Replace a still-working drive in the '${POOL_NAME}' pool with a
           new one (calls replace_drive).

Set DEBUG=1 in the environment to dry-run without modifying the system.
EOF
}

# Only act when executed directly - sourcing this script just defines the
# functions above without running anything.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  case "$1" in
    fresh)
      recreate_from_nothing
      ;;
    replace)
      replace_drive
      ;;
    -h|--help)
      usage
      ;;
    *)
      usage
      exit 1
      ;;
  esac
fi
