#!/usr/bin/env bash

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" 
    exit 1
fi

# Initialize environment
WORKING_DIR=$(dirname "$(realpath "$0")")
source ${WORKING_DIR}/.env

# Current date
DATE=$(date +"%m/%d/%Y")

# FreeBSD workarounds
if [ "$(uname)" = "FreeBSD" ]; then
  # Add my custom PATH to the user's environment
  # This would usually be set in the environment itself (either cron or the user's profile).
  # OPNSense takes control of crontab and we cannot set the correct PATH for cron.
  # Therefore, we set it manually here.
  export PATH="${PATH}:${WORKING_DIR}/../bin"
fi

############################## CHECKING ##############################
# integrity_test()
#
# Run multifaceted integrity check
function integrity_test() {
  # Smartctl long test
  for drive in "${SMART_DRIVES[@]}"; do
    echo "Running integrity test on drive ${drive}..."
    echo -e "\tsmartctl -t long ${drive}"
    smartctl -t long ${drive} >/dev/null 2>&1
  done

  # ZFS trim/scrub
  for pool in "${ZFS_POOLS[@]}"; do
    echo "Scrubbing ZFS pool ${pool}..."
    echo -e "\tzpool scrub ${pool}"
    zpool scrub ${pool}

    echo "Trimming ZFS pool ${pool}..."
    echo -e "\tzpool trim ${pool}"
    zpool trim ${pool}
  done

  # Perform maintenance on borg repositories
  for repo_path in "${BORG_REPOSITORIES[@]}"; do
    echo "Performing maintenance on borg repository ${repo_path}..."
    borg_maintenance "${repo_path}" &
    sleep 30
  done

  # Wait for all backgrounded maintenance jobs to finish before returning
  wait
}


# borg_maintenance(repo_path)
#   repo_path - path borg repository on which to perform maintenance
#
# Perform maintenance on a borg repository
#
# NOTE
# To change compression level, run this
# borg recreate --compression zstd,6 /path/to/repo
function borg_maintenance()
{
  local repo_path="$1"
  require dir "${repo_path}"

  # create temp logfile
  temp_repo_logfile=$(mktemp)
  echo -e "\n############################## ${repo_path} ##############################" > "${temp_repo_logfile}"

  # verify contents
  # for a full integrity verification, add the --verify-data flag here
  # full integrity verification will read, decrypt, and decompress the repository
  # otherwise, a simple CRC32 check will be run
  echo "Verifying the contents of borg repository \"${repo_path}\"" >> "${temp_repo_logfile}"
  time borg -v check "${repo_path}" >> "${temp_repo_logfile}" 2>&1

  # compact segment files
  echo -e "\nCompacting segment files for borg repository \"${repo_path}\"" >> "${temp_repo_logfile}"
  time borg -v compact "${repo_path}" >> "${temp_repo_logfile}" 2>&1

  echo -e "\nFinished maintenance on borg repository \"${repo_path}\"!" >> "${temp_repo_logfile}"

  # Print all logs for this repo at once
  echo >> "${BORG_LOGFILE}"
  echo >> "${BORG_LOGFILE}"
  cat "${temp_repo_logfile}" >> "${BORG_LOGFILE}"
}

############################## REPORTING ##############################
# integrity_report()
#
# Construct a data integrity report email
function integrity_report()
{
  # If there are S.M.A.R.T. devices detected, report on them
  smart_summarize

  # If there are ZFS pools detected, report on them
  zfs_summarize

  # Report on borg maintenance
  borg_summarize
}


# borg_summarize()
#
# Print out full details on borg maintenance operations
function borg_summarize()
{
  # Return immediately if there is nothing to summarize
  [[ ! -f "${BORG_LOGFILE}" ]] && return

  echo -e "-----------------------------------------------------------------------"
  echo -e "--------------------------- BORG MAINTENANCE --------------------------"
  echo -e "-----------------------------------------------------------------------"

  cat "${BORG_LOGFILE}"
  echo -e "\n"
  echo -e "\n"
}


# smart_value(output, key)
#   output - smartctl output
#   key    - label (including colon) at the start of the line, e.g. "Serial Number:"
#
# Print the value of the first "key   value" line in smartctl output
function smart_value()
{
  awk -v k="$2" 'index($0, k) == 1 { v = substr($0, length(k) + 1); sub(/^[ \t]+/, "", v); print v; exit }' <<< "$1"
}


# smart_attr(output, id)
#   output - smartctl output
#   id     - ATA attribute ID, e.g. 5
#
# Print "<ATTRIBUTE_NAME> <RAW_VALUE>" for an ATA attribute, or nothing if the drive lacks it
function smart_attr()
{
  awk -v id="$2" '
    # Attribute rows have flags in either brief ("PO--CK") or old ("0x0033") format
    $1 == id && ((length($3) == 6 && $3 ~ /^[-POSRCK]+$/) || $3 ~ /^0x[0-9a-f]+$/) {
      start = ($3 ~ /^0x/) ? 10 : 8
      raw = $start
      for (i = start + 1; i <= NF; i++) raw = raw " " $i
      print $2, raw
      exit
    }' <<< "$1"
}


# smart_devstat(output, description)
#   output      - smartctl output
#   description - ATA Device Statistics description, e.g. "Logical Sectors Written"
#
# Print the value of an ATA Device Statistics entry, or nothing if the drive lacks it
function smart_devstat()
{
  awk -v d="$2" '
    $1 ~ /^0x[0-9a-f]+$/ && NF >= 6 {
      desc = $6
      for (i = 7; i <= NF; i++) desc = desc " " $i
      if (desc == d && $4 ~ /^[0-9]+$/) { print $4; exit }
    }' <<< "$1"
}


# smart_lifetime_bytes(output, direction)
#   output    - smartctl output
#   direction - "Read" or "Written"
#
# Print the all-time bytes read/written by a drive, or nothing if it cannot be determined
function smart_lifetime_bytes()
{
  local output="$1"
  local direction="$2"
  local count name raw sector_size

  # NVMe - data units are 1000 512-byte sectors
  count=$(smart_value "${output}" "Data Units ${direction}:" | awk '{ gsub(/,/, "", $1); print $1 }')
  if [[ "${count}" =~ ^[0-9]+$ ]]; then
    echo $(( count * 512000 ))
    return
  fi

  sector_size=$(awk '/^Sector Sizes?:/ { print $3; exit }' <<< "${output}")
  [[ "${sector_size}" =~ ^[0-9]+$ ]] || sector_size=512

  # ATA - Device Statistics are standardized, so prefer them
  count=$(smart_devstat "${output}" "Logical Sectors ${direction}")
  if [[ "${count}" =~ ^[0-9]+$ ]]; then
    echo $(( count * sector_size ))
    return
  fi

  # ATA - fall back to vendor-specific attributes 242 (read) / 241 (written), whose unit depends on the name
  local id=241
  [[ "${direction}" == "Read" ]] && id=242
  read -r name raw <<< "$(smart_attr "${output}" "${id}")"
  raw="${raw%% *}"
  [[ "${raw}" =~ ^[0-9]+$ ]] || return
  case "${name}" in
    *32MiB*) echo $(( raw * 32 * 1024 * 1024 )) ;;
    *GiB*)   echo $(( raw * 1024 * 1024 * 1024 )) ;;
    *LBAs*)  echo $(( raw * sector_size )) ;;
  esac
}


# smart_bytes_summary(bytes, rating, rating_name)
#   bytes       - all-time bytes read or written
#   rating      - (optional) TB written rating of the drive, in TB
#   rating_name - (optional) name of the rating, e.g. "TBW"
#
# Print a human-readable amount of data, and its percentage of the rating if a rating name is given
function smart_bytes_summary()
{
  [[ -z "$1" ]] && { echo "N/A"; return; }

  awk -v b="$1" -v t="$2" -v n="$3" 'BEGIN {
    if (b >= 1e12)     printf "%.2f TB", b / 1e12
    else if (b >= 1e9) printf "%.2f GB", b / 1e9
    else               printf "%.2f MB", b / 1e6

    if (n == "") {
      printf "\n"
    } else if (t ~ /^[0-9]+(\.[0-9]+)?$/ && t > 0) {
      p = b / (t * 1e12) * 100
      printf " (%.1f%% of %s %s rating%s)\n", p, t, n, (p > 100) ? " - EXCEEDS RATING" : ""
    } else {
      printf " (no %s rating set)\n", n
    }
  }'
}


# smart_drive_devices(drive)
#   drive - drive as passed to smartctl, e.g. "/dev/sda"
#
# Print every device node that lives on a drive (its disks, their partitions, and anything layered on top), one per line.
# The drive may be a disk itself or a controller with disks attached (e.g. /dev/nvme0), in which case every disk is searched.
function smart_drive_devices()
{
  local drive="$1" disks disk

  if [ "$(uname)" = "FreeBSD" ]; then
    drive="${drive#/dev/}"
    # Disks attached to the drive if it is a controller, otherwise the drive itself
    disks=$(camcontrol devlist -v 2>/dev/null | awk -v c="${drive}" -v k="$(sysctl -n kern.disks)" '
      BEGIN { n = split(k, d, " "); for (i = 1; i <= n; i++) disk[d[i]] }
      /^scbus[0-9]+ on / { ctl = $3; next }
      ctl == c && match($0, /\([^)]*\)$/) {
        n = split(substr($0, RSTART + 1, RLENGTH - 2), p, ",")
        for (i = 1; i <= n; i++) if (p[i] in disk) print p[i]
      }')
    [[ -z "${disks}" ]] && disks="${drive}"
    for disk in ${disks}; do
      # Partitions/slices are named <disk>p<N> or <disk>s<N>, optionally with a GELI ".eli" suffix
      ls /dev | grep -E "^${disk}([ps][0-9].*)?$" | sed 's|^|/dev/|'
      # GEOM labels (gpt/, gptid/, diskid/, ...) pointing at the disk or its partitions
      glabel status -s 2>/dev/null | awk -v d="${disk}" '$3 ~ "^" d "([ps][0-9].*)?$" { print "/dev/" $1 }'
    done
  else
    drive=$(realpath "${drive}")
    # Find the drive's sysfs device, then every block device beneath it (the disk itself, a controller's disks, partitions)
    local type=block sysdev
    [[ -c "${drive}" ]] && type=char
    sysdev=$(realpath "/sys/dev/${type}/$(( 0x$(stat -c %t "${drive}") )):$(( 0x$(stat -c %T "${drive}") ))" 2>/dev/null)
    [[ -z "${sysdev}" ]] && return
    for disk in /sys/class/block/*; do
      # lsblk adds anything layered on top, e.g. LUKS or LVM
      [[ "$(realpath "${disk}")/" == "${sysdev}/"* ]] && lsblk -lnpo NAME "/dev/${disk##*/}" 2>/dev/null
    done | sort -u
  fi
}


# smart_drive_mounts(drive)
#   drive - drive as passed to smartctl, e.g. "/dev/sda"
#
# Print the directories a drive is mounted to, or nothing if it is not mounted.
# Directly mounted filesystems go on one line, then each ZFS pool on the drive gets a line of its own.
function smart_drive_mounts()
{
  local devices pool mounts
  devices=$(smart_drive_devices "$1")
  [[ -z "${devices}" ]] && return

  # Filesystems mounted directly from the drive
  mounts=$(mount | awk 'NR == FNR { dev[$1]; next } $1 in dev { print $3 }' <(echo "${devices}") - | paste -sd ',' - | sed 's/,/, /g')
  [[ -n "${mounts}" ]] && echo "${mounts}"

  # ZFS pools with a vdev on the drive - list the pool's mounted datasets
  for pool in "${ZFS_POOLS[@]}"; do
    zpool status -LP "${pool}" 2>/dev/null | awk 'NR == FNR { dev[$1]; next } $1 in dev { found = 1 } END { exit !found }' <(echo "${devices}") - || continue
    mounts=$(zfs list -H -r -t filesystem -o mounted,mountpoint "${pool}" 2>/dev/null | awk -F '\t' '$1 == "yes" { print $2 }' | paste -sd ',' - | sed 's/,/, /g')
    echo "${mounts:-not mounted} (ZFS)"
  done
}


# smart_summarize()
#
# Print out a S.M.A.R.T. summary for the externally defined SMART_DRIVES
function smart_summarize()
{
  # Return immediately if there is nothing to summarize
  [[ -z "${SMART_DRIVES}" ]] && return

  # ATA attributes worth watching, by ID
  local ata_attributes=(5 197 198 187 188 199 9 12)
  # NVMe health log fields worth watching
  local nvme_attributes=(
    "Critical Warning"
    "Available Spare"
    "Available Spare Threshold"
    "Percentage Used"
    "Media and Data Integrity Errors"
    "Error Information Log Entries"
    "Unsafe Shutdowns"
    "Power On Hours"
    "Power Cycles"
  )

  echo -e "-----------------------------------------------------------------------"
  echo -e "------------------------- SMARTCTL MONITORING -------------------------"
  echo -e "-----------------------------------------------------------------------"

  if [[ ${#SMART_TBW_RATING[@]} -ne ${#SMART_DRIVES[@]} ]]; then
    echo -e "\nWARNING: SMART_DRIVES has ${#SMART_DRIVES[@]} entries but SMART_TBW_RATING has ${#SMART_TBW_RATING[@]} - ratings may be misaligned!"
  fi

  # Summarize each declared smartctl drive
  local i drive output rc model serial health mounts
  local temp_cur temp_min temp_max id key name value raw selftest
  for i in "${!SMART_DRIVES[@]}"; do
    drive="${SMART_DRIVES[$i]}"
    echo -e "\n############################## ${drive} ##############################"

    output=$(smartctl -x "${drive}" 2>&1)
    rc=$?
    # Bit 0 - command line/device type error, bit 1 - device open failed
    if (( rc & 3 )); then
      echo -e "${drive} could not be opened or is not S.M.A.R.T. capable, skipping..."
      continue
    fi

    # Summary, as tab-separated "label<TAB>value" lines aligned by column
    {
      # Name
      model=$(smart_value "${output}" "Device Model:")
      [[ -z "${model}" ]] && model=$(smart_value "${output}" "Model Number:")
      [[ -z "${model}" ]] && model=$(smart_value "${output}" "Product:")
      serial=$(smart_value "${output}" "Serial Number:")
      [[ -z "${serial}" ]] && serial=$(smart_value "${output}" "Serial number:")
      printf "Model:\t%s (S/N %s)\n" "${model:-N/A}" "${serial:-N/A}"

      # Mount points, one group per line - continuation lines get a placeholder label (".") so column keeps them aligned
      mounts=$(smart_drive_mounts "${drive}")
      awk 'NR == 1 { printf "Mounts:\t%s\n", $0; next } { printf ".\t%s\n", $0 }' <<< "${mounts:-not mounted}"

      # Health
      health=$(smart_value "${output}" "SMART overall-health self-assessment test result:")
      [[ -z "${health}" ]] && health=$(smart_value "${output}" "SMART Health Status:")
      printf "Health:\t%s\n" "${health:-N/A}"

      # Temperature - NVMe does not track lifetime min/max
      temp_cur=$(smart_value "${output}" "Current Temperature:" | awk '{ print $1 }')
      [[ -z "${temp_cur}" ]] && temp_cur=$(smart_value "${output}" "Temperature:" | awk '{ print $1 }')
      [[ -z "${temp_cur}" ]] && temp_cur=$(smart_attr "${output}" 194 | awk '{ print $2 }')
      read -r temp_min temp_max <<< "$(awk '/^Lifetime +Min\/Max Temperature:/ { split($4, t, "/"); print t[1], t[2]; exit }' <<< "${output}")"
      [[ "${temp_min}" =~ ^-?[0-9]+$ ]] || temp_min=$(smart_devstat "${output}" "Lowest Temperature")
      [[ "${temp_max}" =~ ^-?[0-9]+$ ]] || temp_max=$(smart_devstat "${output}" "Highest Temperature")
      temp_cur="${temp_cur:+${temp_cur}C}"
      temp_min="${temp_min:+${temp_min}C}"
      temp_max="${temp_max:+${temp_max}C}"
      printf "Temperature:\t%s current, %s min, %s max\n" "${temp_cur:-N/A}" "${temp_min:-N/A}" "${temp_max:-N/A}"

      # All-time reads/writes
      printf "Reads:\t%s\n" "$(smart_bytes_summary "$(smart_lifetime_bytes "${output}" Read)")"
      printf "Writes:\t%s\n" "$(smart_bytes_summary "$(smart_lifetime_bytes "${output}" Written)" "${SMART_TBW_RATING[$i]}" TBW)"

      # Most recent self-test - the first entry after the self-test log header (ATA "# 1", NVMe " 0")
      selftest=$(awk '
        /Test_Description/ { found = 1; next }
        found && NF {
          sub(/^ *(# *)?[0-9]+ +/, "")
          split($0, f, /  +/)
          hours = (f[3] ~ /%$/) ? f[4] : f[3]
          printf "%s - %s (%s hours)\n", f[1], f[2], hours
          exit
        }' <<< "${output}")
      printf "Last self-test:\t%s\n" "${selftest:-N/A}"
    } | column -t -s $'\t' | sed 's/^\./ /'

    # Key attributes, omitting any the drive does not report
    echo "Attributes:"
    {
      for id in "${ata_attributes[@]}"; do
        read -r name raw <<< "$(smart_attr "${output}" "${id}")"
        [[ -n "${name}" ]] && printf "%s\t%s\n" "${name}" "${raw}"
      done
      value=$(smart_devstat "${output}" "Percentage Used Endurance Indicator")
      [[ -n "${value}" ]] && printf "Percentage Used Endurance Indicator\t%s%%\n" "${value}"
      for key in "${nvme_attributes[@]}"; do
        value=$(smart_value "${output}" "${key}:")
        [[ -n "${value}" ]] && printf "%s\t%s\n" "${key}" "${value}"
      done
    } | column -t -s $'\t' | sed 's/^/  /'

  done

  echo -e "\n"
  echo -e "\n"
}


# zfs_summarize()
#
# Print out full ZFS pool summary for the externally defined ZFS_POOLS
function zfs_summarize()
{
  # Return immediately if there is nothing to summarize
  [[ -z "${ZFS_POOLS}" ]] && return

  echo -e "-----------------------------------------------------------------------"
  echo -e "---------------------------- ZFS MONITORING ---------------------------"
  echo -e "-----------------------------------------------------------------------"

  # Summarize each declared ZFS pool
  for pool in "${ZFS_POOLS[@]}"; do
    echo -e "\n############################## ${pool} ##############################"
    echo -e "$(zpool status ${pool})"
  done

  echo -e "\n"
  echo -e "\n"
}


############################## MAIN ##############################
# If BORG_REPOSITORIES is set, configure related environment variables
if [[ -n "${BORG_REPOSITORIES[*]}" ]]; then
  # Ensure borg-related variables are set
  require var "${BORG_PASS_FILE}"
  require file "${BORG_PASS_FILE}"
  require var "${BORG_REPOSITORIES}"
  require var "${EMAIL}"

  # Create borg logfile (and remove existing)
  export BORG_PASSPHRASE=$(cat "${BORG_PASS_FILE}")
  BORG_LOGFILE=${XDG_CACHE_HOME:-${HOME}/.local/cache}/borg_maintenance.txt
  mkdir -p "$(dirname "${BORG_LOGFILE}")"
  rm -f "${BORG_LOGFILE}"
fi

# Create array of all ZFS pools
ZFS_POOLS=()
if command -v zpool &>/dev/null; then
  ZFS_POOLS=($(zpool list -H -o name))
else
  echo "WARNING: zpool is not installed, skipping ZFS checks. If you have ZFS pools, install ZFS to monitor them." >&2
fi


# Parse and handle arguments
if [ "$1" == "test" ]; then
  integrity_test
  exit
elif [ "$1" == "report" ]; then
  integrity_report | send-email -e "${EMAIL}" -s "Data Integrity Report ${DATE}"
else
  echo "Invalid argument - choose one of [test, report]."
fi
