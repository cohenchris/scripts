#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" 
    exit 1
fi

# Initialize environment
WORKING_DIR=$(dirname "$(realpath "$0")")
source ${WORKING_DIR}/.env
DATE=$(date +"%Y%m%d")
STATUS="SUCCESS"
BODY=/tmp/body


# require(var)
#   var - variable to check
#
# This function will throw an error if the provided variable is not set
function require() {
  local var="$1"

  if [[ -z "${!var}" ]]; then
    # Log variable name and calling function name
    echo -e "${RED}ERROR - ${var} is not set in ${FUNCNAME[1]:-env}${NC}"
    status="FAIL"
  fi
}


# test_drives()
#
# Run full smartctl and ZFS tests on the defined drives
function test_drives() {
  # Smartctl long test
  for drive in ${SMART_DRIVES[@]}; do
    smartctl -t long ${drive} >/dev/null 2>&1
  done

  # ZFS trim/scrub
  for pool in ${ZFS_POOLS[@]}; do
    zpool scrub ${pool}
    zpool trim ${pool}
  done
}


# report_health()
#
# Send smartctl and ZFS reports via email
function report_health()
{
  rm -f ${BODY}

  # If there are S.M.A.R.T. devices detected, report on them
  if [[ ${#SMART_DRIVES[@]} -gt 0 ]]; then
    smart_summarize
  fi

  # If there are ZFS pools detected, report on them
  if [[ ${#ZFS_POOLS[@]} -gt 0 ]]; then
    zfs_summarize
  fi


  # Send the summary email
  SUBJECT="${STATUS} - Drive Health Report ${DATE}"
  send_email "${EMAIL}" "${SUBJECT}" "${BODY}"
  rm ${BODY}
}


# smart_summarize()
#
# Print out full S.M.A.R.T. summary
function smart_summarize()
{
  echo >> ${BODY}
  echo "-----------------------------------------------------------------------" >> ${BODY}
  echo "------------------------- SMARTCTL MONITORING -------------------------" >> ${BODY}
  echo "-----------------------------------------------------------------------" >> ${BODY}
  echo >> ${BODY}

  # Summarize each declared smartctl drive
  for drive in ${SMART_DRIVES[@]}; do
    echo "############################## ${drive} ##############################" >> ${BODY}

    local smartctl_output_short=$(smartctl -H ${drive})

    if [[ ${smartctl_output_short} == *"PASSED"* ]]; then
      # Print short-form health that basically only shows "PASSED"
      echo ${smartctl_output_short} >> ${BODY}
    elif [[ ${smartctl_output_short} == *"Unable to detect device type"* ]]; then
      echo "${drive} is not S.M.A.R.T. capable, skipping..." >> ${BODY}
    else
      # There's something wrong, print a more comprehensive summary
      local smartctl_output_long=$(smartctl -a ${drive})

      echo ${smartctl_output_long} >> ${BODY}
      STATUS="FAIL"
    fi

    echo >> ${BODY}

  done
}


# zfs_summarize()
#
# Print out full ZFS pool summary
function zfs_summarize()
{
  echo >> ${BODY}
  echo "-----------------------------------------------------------------------" >> ${BODY}
  echo "---------------------------- ZFS MONITORING ---------------------------" >> ${BODY}
  echo "-----------------------------------------------------------------------" >> ${BODY}
  echo >> ${BODY}

  # Summarize each declared ZFS pool
  for pool in ${ZFS_POOLS[@]}; do
    echo "############################## ${pool} ##############################" >> ${BODY}

    zpool status ${pool} >> ${BODY}

    if [[ $? -ne 0 ]]; then
      status="FAIL"
    fi

    echo >> ${BODY}

  done
}


# send_email(email, subject, body)
#   email   - destination email address
#   subject - subject of outgoing email address
#   body    - body of outgoing email address
#
# Sends an email by polling until success
function send_email() {
  local email="$1"
  local subject="$2"
  local body="$3"
  local MAX_MAIL_ATTEMPTS=50

  require email
  require subject
  require body

  # Poll email send
  while ! neomutt -s "${subject}" -- ${email} < ${body}
  do
    echo -e "${RED}email failed, trying again...${NC}"

    # Limit attempts. If it goes infinitely, it could fill up the disk.
    MAX_MAIL_ATTEMPTS=$((MAX_MAIL_ATTEMPTS-1))
    if [[ ${MAX_MAIL_ATTEMPTS} -eq 0 ]]; then
      echo -e "${RED}send_email failed${NC}"
      fail
    fi

    sleep 5
  done

  echo -e "${GREEN}email sent!${NC}"
}



# Create array of all drives
SMART_DRIVES=($(lsblk -nd -o name | sed 's/^/\/dev\//'))

# Create array of all ZFS pools
ZFS_POOLS=($(zpool list -H -o name))

# Parse and handle arguments
if [ "$1" == "test" ]; then
  test_drives
elif [ "$1" == "report" ]; then
  report_health
else
  echo "Invalid argument - choose one of [test, report]."
  exit 1
fi
