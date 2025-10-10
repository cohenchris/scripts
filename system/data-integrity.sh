#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" 
    exit 1
fi


# Initialize environment
WORKING_DIR=$(dirname "$(realpath "$0")")
source ${WORKING_DIR}/.env

require var BORG_PASS_FILE
require file "${BORG_PASS_FILE}"
require var BORG_REPOSITORIES
require var EMAIL

# Borg-related environment variables
export BORG_PASSPHRASE=$(cat "${BORG_PASS_FILE}")
BORG_LOGFILE=${XDG_CACHE_HOME:-${HOME}/.local/cache}/borg_maintenance.txt

# On some systems, smartctl is installed in /usr/sbin
export PATH="/usr/sbin:${PATH}"


############################## INTEGRITY CHECKING ##############################

# integrity_test()
#
# Run multifaceted integrity check
function integrity_test() {
  # Smartctl long test
  for drive in ${SMART_DRIVES[@]}; do
    smartctl -t long /dev/${drive} >/dev/null 2>&1
  done

  # ZFS trim/scrub
  for pool in ${ZFS_POOLS[@]}; do
    zpool scrub ${pool}
    zpool trim ${pool}
  done

  # Perform maintenance on borg repositories
  for repo in "${BORG_REPOSITORIES[@]}"; do
    borg_maintenance "${repo}" &
    sleep 1
  done
}


# borg_maintenance(repo)
#   repo - borg repository on which to perform maintenance
#
# Perform maintenance on a borg repository
#
# NOTE
# To change compression level, run this
# borg recreate --compression zstd,6 /path/to/repo
function borg_maintenance()
{
  local repo="$1"
  require directory repo

  # create temp logfile
  temp_repo_logfile=$(mktemp)
  echo "\n############################## ${repo} ##############################" > "${temp_repo_logfile}"

  # verify contents
  # for a full integrity verification, add the --verify-data flag here
  # full integrity verification will read, decrypt, and decompress the repository
  # otherwise, a simple CRC32 check will be run
  echo "Verifying the contents of borg repository \"${repo}\"" >> "${temp_repo_logfile}"
  time borg -v check "${repo}" >> "${temp_repo_logfile}" 2>&1

  # compact segment files
  echo "\nCompacting segment files for borg repository \"${repo}\"" >> "${temp_repo_logfile}"
  time borg -v compact "${repo}" >> "${temp_repo_logfile}" 2>&1

  echo "\nFinished maintenance on borg repository \"${repo}\"!" >> "${temp_repo_logfile}"

  # Print all logs for this repo at once
  echo
  echo
  cat "${temp_repo_logfile}" >> "${BORG_LOGFILE}"
}

############################## REPORTING ##############################

# integrity_report()
#
# Email a S.M.A.R.T. report for SMART_DRIVES and ZFS pool report for ZFS_POOLS
function integrity_report()
{
  rm -f ${BODY}

  # If there are S.M.A.R.T. devices detected, report on them
  if ! [[ -z ${SMART_DRIVES[0]} ]]; then
    smart_summarize
  fi

  # If there are ZFS pools detected, report on them
  if ! [[ -z ${ZFS_POOLS[0]} ]]; then
    zfs_summarize
  fi

  # Report on borg maintenance
  if [[ -f "${BORG_LOGFILE}" ]]; then
    borg_summarize
  fi

  # Send the summary email
  SUBJECT="${STATUS} - Drive Health Report ${DATE}"
  send_email "${EMAIL}" "${SUBJECT}" "${BODY}"
  rm ${BODY}
}

############################## SUMMARIZATION ##############################

# borg_summarize()
#
# Print out full details on borg maintenance operations
function borg_summarize()
{
  mail_log plain "\n-----------------------------------------------------------------------"
  mail_log plain "--------------------------- BORG MAINTENANCE --------------------------"
  mail_log plain "-----------------------------------------------------------------------\n"

  mail_log plain $(echo -e "${BORG_LOGFILE}")
}


# smart_summarize()
#
# Print out full S.M.A.R.T. summary for the externally SMART_DRIVES
function smart_summarize()
{
  mail_log plain "\n-----------------------------------------------------------------------"
  mail_log plain "------------------------- SMARTCTL MONITORING -------------------------"
  mail_log plain "-----------------------------------------------------------------------\n"

  # Summarize each declared smartctl drive
  for drive in ${SMART_DRIVES[@]}; do
    mail_log plain "\n############################## /dev/${drive} ##############################"

    local smartctl_output_short=$(smartctl -H /dev/${drive})

    if [[ ${smartctl_output_short} == *"PASSED"* ]]; then
      # Print short-form health that basically only shows "PASSED"
      mail_log plain "${smartctl_output_short}"
    elif [[ ${smartctl_output_short} == *"Unable to detect device type"* ]]; then
      mail_log plain "/dev/${drive} is not S.M.A.R.T. capable, skipping..."
    else
      # There's something wrong, print a more comprehensive summary
      local smartctl_output_long=$(smartctl -a /dev/${drive})

      mail_log plain "${smartctl_output_long}"
      STATUS="FAIL"
    fi

  done
}


# zfs_summarize()
#
# Print out full ZFS pool summary for the externally defined ZFS_POOLS
function zfs_summarize()
{
  mail_log plain "\n-----------------------------------------------------------------------"
  mail_log plain "---------------------------- ZFS MONITORING ---------------------------"
  mail_log plain "-----------------------------------------------------------------------\n"

  # Summarize each declared ZFS pool
  for pool in ${ZFS_POOLS[@]}; do
    mail_log plain "\n############################## ${pool} ##############################"

    mail_log plain "$(zpool status ${pool})"

    if [[ $? -ne 0 ]]; then
      status="FAIL"
    fi

  done
}


############################## MAIN ##############################

# Create array of all drives
SMART_DRIVES=$(ls /dev | grep -E '^(sd[a-z]+|nvme[0-9]+n[0-9]+|ada[0-9]+|da[0-9]+)$' | sort)

# Create array of all ZFS pools
ZFS_POOLS=($(zpool list -H -o name))

# Parse and handle arguments
if [ "$1" == "test" ]; then
  integrity_test
elif [ "$1" == "report" ]; then
  integrity_report
else
  mail_log plain "Invalid argument - choose one of [test, report]."
  status="FAIL"
fi

finish
