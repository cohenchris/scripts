#!/usr/bin/env bash
#
# shutdown-network.sh
#
# Wired into NUT as the host upsmon SHUTDOWNCMD on the warden machine. When the
# UPS reaches low battery (or an FSD is issued), upsmon runs this script instead
# of a bare `shutdown`. It:
#
#   1. Sends a Signal message through the local signal-cli REST API container
#   2. Shuts down every other machine on the network  (shutdown_all_devices)
#   3. Powers off this machine (warden) last          (shutdown_self)
#
# See the "Network Shutdown" section of the README for configuration.

# Bail if attempting to substitute an unset variable
set -u

#################### Configuration ####################

# DRY_RUN=1 (or --dry-run) still sends the real Signal notification, but powers
# nothing off (neither the other servers nor warden). Use it to test the wiring.
DRY_RUN="${DRY_RUN:-0}"

# Notification text
title="UPS on battery - shutting down"
body="Warden issued a network-wide shutdown: the UPS reached low battery. All servers are powering off now."

# Seconds to wait on the notification request before giving up
NOTIFY_TIMEOUT=10

# Signal endpoint/numbers are read from .env - see sample.env. Defaults are
# applied in load_env().

######################################################


# Log to stderr and syslog so messages land in `journalctl -t shutdown-network`
# (and in the nut-monitor unit's journal when run as SHUTDOWNCMD).
function log()
{
  local msg="$*"
  echo "shutdown-network: ${msg}" >&2
  command -v logger >/dev/null 2>&1 && logger -t shutdown-network -- "${msg}"
}


# Initialize environment - source .env from the script's own directory
# (matches system/b2-mount.sh), then apply defaults for anything left unset
function load_env()
{
  WORKING_DIR=$(dirname "$(realpath "$0")")
  source ${WORKING_DIR}/.env

  # Base URL of the signal-cli REST API (bbernhard/signal-cli-rest-api)
  SIGNAL_API_ENDPOINT="${SIGNAL_API_ENDPOINT:-http://localhost:8080}"
  # Registered Signal number the message is sent from
  SIGNAL_SENDER="${SIGNAL_SENDER:-}"
  # Space-separated recipients: phone numbers and/or group IDs (group.xxxx)
  SIGNAL_RECIPIENTS="${SIGNAL_RECIPIENTS:-}"
}


# Escape a string for embedding inside a JSON string literal
function json_escape()
{
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '%s' "${s}"
}


# Send title/body as a Signal message via the signal-cli REST API
function send_notification()
{
  if [[ -z "${SIGNAL_SENDER}" || -z "${SIGNAL_RECIPIENTS}" ]]; then
    log "ERROR: SIGNAL_SENDER and SIGNAL_RECIPIENTS must be set - skipping notification"
    return 1
  fi

  local url="${SIGNAL_API_ENDPOINT%/}/v2/send"
  local message="${title}"$'\n\n'"${body}"

  # Build the recipients JSON array
  local recipient recipients_json=""
  for recipient in ${SIGNAL_RECIPIENTS}; do
    recipients_json+="${recipients_json:+,}\"$(json_escape "${recipient}")\""
  done

  local payload
  payload="{\"message\": \"$(json_escape "${message}")\", \"number\": \"$(json_escape "${SIGNAL_SENDER}")\", \"recipients\": [${recipients_json}]}"

  local http_code
  http_code=$(curl -s -o /dev/null                               \
                  -w "%{http_code}"                               \
                  --max-time "${NOTIFY_TIMEOUT}"                  \
                  -X POST                                         \
                  -H "Content-Type: application/json"             \
                  -d "${payload}"                                 \
                  "${url}")

  log "signal send returned HTTP ${http_code}"
  [[ "${http_code}" =~ ^2 ]]
}


# Shut down every other machine on the network.
#
# TODO(chris): implement. Suggested shape - loop over an inventory and poweroff
# over SSH as root:
#
#   local hosts=(backups.lan console.lan kvm.lan lab.lan albumwall.lan)
#   for host in "${hosts[@]}"; do
#     log "powering off ${host}"
#     if [[ "${DRY_RUN}" == "1" ]]; then continue; fi
#     ssh -o BatchMode=yes -o ConnectTimeout=5 "root@${host}" 'systemctl poweroff' \
#       || log "WARNING: failed to reach ${host}"
#   done
#
# Do NOT shut down warden here - shutdown_self() handles that last. Leave
# network gear (router.lan, ap.lan) up so the run can finish.
function shutdown_all_devices()
{
  log "shutdown_all_devices: not implemented yet - nothing to do"
}


# Power off this machine (warden), last.
function shutdown_self()
{
  if [[ "${DRY_RUN}" == "1" ]]; then
    log "[dry-run] would power off warden now"
    return 0
  fi

  log "powering off warden"
  # Equivalent to the SHUTDOWNCMD upsmon would otherwise have run
  /sbin/shutdown -h +0 "UPS low battery - warden shutting down" \
    || systemctl poweroff
}


function main()
{
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run) DRY_RUN=1 ;;
      *)         log "ignoring unknown argument: $1" ;;
    esac
    shift
  done

  log "network shutdown initiated (DRY_RUN=${DRY_RUN})"
  load_env
  send_notification || log "continuing despite notification failure"
  shutdown_all_devices
  shutdown_self
}

main "$@"
