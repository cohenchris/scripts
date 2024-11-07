#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" 
    exit 1
fi

WORKING_DIR=$(dirname "$(realpath "$0")")
source ${WORKING_DIR}/.env


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
  for drive in ${DRIVES_TO_SCAN[@]}; do
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
function report_health() {
  DATE=$(date +"%Y%m%d")
  STATUS="SUCCESS"
  BODY=/tmp/body
  rm -f ${BODY}

  echo >> ${BODY}
  echo "-----------------------------------------------------------------------" >> ${BODY}
  echo "------------------------- SMARTCTL MONITORING -------------------------" >> ${BODY}
  echo "-----------------------------------------------------------------------" >> ${BODY}
  echo >> ${BODY}

  # Summarize each declared smartctl drive
  for drive in ${DRIVES_TO_SCAN[@]}; do
    echo "############################## ${drive} ##############################" >> ${BODY}

    if [[ $(smartctl -H ${drive}) == *"PASSED" ]]; then
      # Print short-form health that basically only shows "PASSED"
      smartctl -H ${drive} >> ${BODY}
    else
      # There's something wrong, print a more comprehensive summary

      smartctl -a ${drive} >> ${BODY}
      STATUS="FAIL"
    fi

  done

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

  # Send the summary email
  SUBJECT="${STATUS} - Drive Health Report ${DATE}"
  send_email "${EMAIL}" "${SUBJECT}" "${BODY}"
  rm ${BODY}
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


# Parse arguments
if [ "$1" == "test" ]; then
  test_drives
elif [ "$1" == "report" ]; then
  report_health
else
  echo "Invalid argument - choose one of [test, report]."
  exit 1
fi
