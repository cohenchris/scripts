#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" 
    exit 1
fi

# Initialize environment
WORKING_DIR=$(dirname "$(realpath "$0")")
source ${WORKING_DIR}/.env

# require var TEST

# On some systems, smartctl is installed in /usr/sbin
export PATH="/usr/sbin:${PATH}"


# test_drives()
#
# Run full S.M.A.R.T. test on SMART_DRIVES and ZFS scrub/trim on ZFS_POOLS
function test_drives() {
  # Smartctl long test
  for drive in ${SMART_DRIVES[@]}; do
    smartctl -t long /dev/${drive} >/dev/null 2>&1
  done

  # ZFS trim/scrub
  for pool in ${ZFS_POOLS[@]}; do
    zpool scrub ${pool}
    zpool trim ${pool}
  done
}


# report_health()
#
# Email a S.M.A.R.T. report for SMART_DRIVES and ZFS pool report for ZFS_POOLS
function report_health()
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

  # Send the summary email
  SUBJECT="${STATUS} - Drive Health Report ${DATE}"
  send_email "${EMAIL}" "${SUBJECT}" "${BODY}"
  rm ${BODY}
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

# Create array of all drives
SMART_DRIVES=$(ls /dev | grep -E '^(sd[a-z]+|nvme[0-9]+n[0-9]+|ada[0-9]+|da[0-9]+)$' | sort)

# Create array of all ZFS pools
ZFS_POOLS=($(zpool list -H -o name))

# Parse and handle arguments
if [ "$1" == "test" ]; then
  test_drives
elif [ "$1" == "report" ]; then
  report_health
else
  mail_log plain "Invalid argument - choose one of [test, report]."
  status="FAIL"
fi

finish
