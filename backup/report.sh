#!/bin/bash
# Send a report over admin mail from the last ${MAIL_PERIOD} days

# Set up environment
WORKING_DIR=$(dirname "$(realpath "$0")")
source "${WORKING_DIR}/.env"

require var SERVER_USER

MAIL_PERIOD=7
MAIL_PERIOD_S=$(( MAIL_PERIOD * 86400 ))
MAILDIR=$(sudo -iu ${SERVER_USER} bash -c 'echo "${MAILDIR}"')
MONITOR_MAILBOX=${MAILDIR}"/INBOX/Admin/cur"

require var MAIL_PERIOD
require var MAIL_PERIOD_S
require var MAILDIR
require var MONITOR_MAILBOX

# Keep count each backup type
backblaze_success=0
backblaze_fail=0
batocera_success=0
batocera_fail=0
critical_data_success=0
critical_data_fail=0
files_success=0
files_fail=0
music_success=0
music_fail=0
openwrt_success=0
openwrt_fail=0
opnsense_success=0
opnsense_fail=0
server_success=0
server_fail=0

# count_backup_type(backup_type, backup_status)
#   backup_type     - backup type
#   backup_status   - status of backup
#
# Counts backup statuses for the given type
function count_backup_type() {
  local backup_type="$1"
  local backup_status="$2"

  require var backup_type 
  require var backup_status

  if [[ "${backup_type}" = "backblaze" ]]; then
    if [[ "${backup_status}" = "SUCCESS" ]]; then
      ((backblaze_success++))
    elif [[ "${backup_status}" = "FAIL" ]]; then
      ((backblaze_fail++))
    fi
  elif [[ "${backup_type}" = "batocera" ]]; then
    if [[ "${backup_status}" = "SUCCESS" ]]; then
      ((batocera_success++))
    elif [[ "${backup_status}" = "FAIL" ]]; then
      ((batocera_fail++))
    fi
  elif [[ "${backup_type}" = "critical" ]]; then
    if [[ "${backup_status}" = "SUCCESS" ]]; then
      ((critical_data_success++))
    elif [[ "${backup_status}" = "FAIL" ]]; then
      ((critical_data_fail++))
    fi
  elif [[ "${backup_type}" = "files" ]]; then
    if [[ "${backup_status}" = "SUCCESS" ]]; then
      ((files_success++))
    elif [[ "${backup_status}" = "FAIL" ]]; then
      ((files_fail++))
    fi
  elif [[ "${backup_type}" = "music" ]]; then
    if [[ "${backup_status}" = "SUCCESS" ]]; then
      ((music_success++))
    elif [[ "${backup_status}" = "FAIL" ]]; then
      ((music_fail++))
    fi
  elif [[ "${backup_type}" = "openwrt" ]]; then
    if [[ "${backup_status}" = "SUCCESS" ]]; then
      ((openwrt_success++))
    elif [[ "${backup_status}" = "FAIL" ]]; then
      ((openwrt_fail++))
    fi
  elif [[ "${backup_type}" = "opnsense" ]]; then
    if [[ "${backup_status}" = "SUCCESS" ]]; then
      ((opnsense_success++))
    elif [[ "${backup_status}" = "FAIL" ]]; then
      ((opnsense_fail++))
    fi
  elif [[ "${backup_type}" = "server" ]]; then
    if [[ "${backup_status}" = "SUCCESS" ]]; then
      ((server_success++))
    elif [[ "${backup_status}" = "FAIL" ]]; then
      ((server_fail++))
    fi
  fi
}


mail_log plain "\n-----------------------------------------------------------------------"
mail_log plain "-------------------------- WEEKLY STATUS REPORT -----------------------"
mail_log plain "-----------------------------------------------------------------------\n"

while IFS= read -r -d '' file; do
  subject=$(grep -m1 '^Subject:' "${file}" | sed 's/^Subject:[[:space:]]*//')

  if [[ "${subject}" == *SUCCESS* || "${subject}" == *FAIL* ]]; then
    backup_type=$(echo "${subject}" | cut -d'-' -f2 | awk '{print $1}')
    backup_status=$(echo "${subject}" | awk '{print $1}')
    count_backup_type "${backup_type}" "${backup_status}"
  fi
done < <(find ${MONITOR_MAILBOX} -type f -mtime -${MAIL_PERIOD} -print0)


mail_log plain "-- BACKBLAZE-- "
mail_log plain "SUCCESS:    ${backblaze_success}"
mail_log plain "FAIL:       ${backblaze_fail}"
mail_log plain "TOTAL:      $((backblaze_success + backblaze_fail))"
mail_log plain "EXPECTED:   7"
mail_log plain "\n"

mail_log plain "-- BATOCERA-- "
mail_log plain "SUCCESS:    ${batocera_success}"
mail_log plain "FAIL:       ${batocera_fail}"
mail_log plain "TOTAL:      $((batocera_success + batocera_fail))"
mail_log plain "EXPECTED:   1"
mail_log plain "\n"

mail_log plain "-- CRITICAL DATA -- "
mail_log plain "SUCCESS:    ${critical_data_success}"
mail_log plain "FAIL:       ${critical_data_fail}"
mail_log plain "TOTAL:      $((critical_data_success + critical_data_fail))"
mail_log plain "EXPECTED:   1"
mail_log plain "\n"

mail_log plain "-- FILES -- "
mail_log plain "SUCCESS:    ${files_success}"
mail_log plain "FAIL:       ${files_fail}"
mail_log plain "TOTAL:      $((files_success + files_fail))"
mail_log plain "EXPECTED:   7"
mail_log plain "\n"

mail_log plain "-- MUSIC -- "
mail_log plain "SUCCESS:    ${music_success}"
mail_log plain "FAIL:       ${music_fail}"
mail_log plain "TOTAL:      $((music_success + music_fail))"
mail_log plain "EXPECTED:   1"
mail_log plain "\n"

mail_log plain "-- OPENWRT -- "
mail_log plain "SUCCESS:    ${openwrt_success}"
mail_log plain "FAIL:       ${openwrt_fail}"
mail_log plain "TOTAL:      $((openwrt_success + openwrt_fail))"
mail_log plain "EXPECTED:   1"
mail_log plain "\n"

mail_log plain "-- OPNSENSE -- "
mail_log plain "SUCCESS:    ${opnsense_success}"
mail_log plain "FAIL:       ${opnsense_fail}"
mail_log plain "TOTAL:      $((opnsense_success + opnsense_fail))"
mail_log plain "EXPECTED:   1"
mail_log plain "\n"

mail_log plain "-- SERVER -- "
mail_log plain "SUCCESS:    ${server_success}"
mail_log plain "FAIL:       ${server_fail}"
mail_log plain "TOTAL:      $((server_success + server_fail))"
mail_log plain "EXPECTED:   7"
mail_log plain "\n"


finish "WEEKLY JOB REPORT"
