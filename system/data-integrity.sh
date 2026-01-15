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


# smart_summarize()
#
# Print out full S.M.A.R.T. summary for the externally SMART_DRIVES
function smart_summarize()
{
  # Return immediately if there is nothing to summarize
  [[ -z "${SMART_DRIVES}" ]] && return

  echo -e "-----------------------------------------------------------------------"
  echo -e "------------------------- SMARTCTL MONITORING -------------------------"
  echo -e "-----------------------------------------------------------------------"

  # Summarize each declared smartctl drive
  for drive in "${SMART_DRIVES[@]}"; do
    echo -e "\n############################## ${drive} ##############################"

    local smartctl_output_short=$(smartctl -H ${drive})

    if [[ ${smartctl_output_short} == *"PASSED"* ]]; then
      # Print short-form health that basically only shows "PASSED"
      echo -e "${smartctl_output_short}"
    elif [[ ${smartctl_output_short} == *"Unable to detect device type"* ]]; then
      echo -e "${drive} is not S.M.A.R.T. capable, skipping..."
    else
      # There's something wrong, print a more comprehensive summary
      local smartctl_output_long=$(smartctl -a ${drive})

      echo -e "${smartctl_output_long}"
    fi

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

# Create array of all drives
SMART_DRIVES=($(smartctl --scan | awk '{print $1}'))

# Create array of all ZFS pools
ZFS_POOLS=($(zpool list -H -o name))


# Parse and handle arguments
if [ "$1" == "test" ]; then
  integrity_test
  exit
elif [ "$1" == "report" ]; then
  integrity_report | send-email "${EMAIL}" "Data Integrity Report ${DATE}"
else
  echo "Invalid argument - choose one of [test, report]."
fi
