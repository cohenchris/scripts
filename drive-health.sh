#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" 
    exit 1
fi

WORKING_DIR=$(dirname "$(realpath "$0")")
source $WORKING_DIR/.env



# smartctl_test()
#
# Run a full smartctl test on the defined drives
function smartctl_test() {
  for drive in ${DRIVES_TO_SCAN[@]}; do
    smartctl -t long $drive >/dev/null 2>&1
  done
}



# smartctl_report()
#
# Send a smartctl report to the email defined in the .env file
function smartctl_report() {
  DATE=$(date +"%Y%m%d")
  STATUS="SUCCESS"
  BODY=/tmp/body
  rm -f $BODY

  # Summarize each declared drive
  for drive in ${DRIVES_TO_SCAN[@]}; do
    echo "------------------------------ $drive ------------------------------" >> $BODY
    if [[ $(smartctl -H $drive) == *"PASSED" ]]; then
      # Print short-form health that basically only shows "PASSED"
      smartctl -H $drive >> $BODY
    else
      # There's something wrong, print a more comprehensive summary
      smartctl -a $drive >> $BODY
      STATUS="FAIL"
    fi
  done

  # Send the summary email
  SUBJECT="$STATUS - Drive Health Report $DATE"
  send_email "$EMAIL" "$SUBJECT" "$BODY"
  rm $BODY
}



# send_email(email, subject, body)
#   email   - destination email address
#   subject - subject of outgoing email address
#   body    - body of outgoing email address
#
# Sends an email by polling until success
function send_email() {
  EMAIL=$1
  SUBJECT=$2
  BODY=$3

  # Sanity check
  if [[ -z "${MAX_MAIL_ATTEMPTS}" || -z "${EMAIL}" || -z "${SUBJECT}" || -z "${BODY}" ]]; then
    echo "send_email - invalid arguments"
    exit 1
  fi

  # Poll email send
  while ! mail -s "${SUBJECT}" ${EMAIL} < ${BODY}
  do
    echo "email failed, trying again..."

    # Limit attempts. If it goes infinitely, it could fill up the disk.
    MAX_MAIL_ATTEMPTS=$((MAX_MAIL_ATTEMPTS-1))
    if [ ${MAX_MAIL_ATTEMPTS} -eq 0 ]; then
      echo "send_email failed,"
      exit 1
    fi

    sleep 5
  done

  echo "email sent!"
}


# Parse arguments
if [ "$1" == "test" ]; then
  smartctl_test
elif [ "$1" == "report" ]; then
  smartctl_report
else
  echo "Invalid argument - choose one of [test, report]."
  exit 1
fi
