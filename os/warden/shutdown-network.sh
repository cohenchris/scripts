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

# DRY_RUN=1 (or --dry-run) still sends the real Signal notifications (tagged
# [DRY RUN]), but powers nothing off (neither the other servers nor warden). Use
# it to test the wiring.
DRY_RUN="${DRY_RUN:-0}"

# Initial notification text
title="UPS on battery - shutting down"
body="Warden issued a network-wide shutdown: the UPS reached low battery. All servers are powering off now."

# Seconds to wait on the notification request before giving up
NOTIFY_TIMEOUT=10

# Seconds between scheduling warden's own poweroff and it happening, so the
# final notification can go out in the meantime
SELF_SHUTDOWN_DELAY=10

# Signal endpoint/numbers are read from .env - see sample.env. Defaults are
# applied in load_env().

# Shutdown targets are also read from .env. They must be declared here, at the
# top level: .env is sourced inside load_env(), and without a global
# `declare -A` the assignment there would create an indexed array instead.
#   SHUTDOWN_CMDS  - user@host -> command to run on it
#   SHUTDOWN_ORDER - user@host targets in the order to shut them down
declare -A SHUTDOWN_CMDS=()
SHUTDOWN_ORDER=()

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


# Send a message to SIGNAL_RECIPIENTS via the signal-cli REST API.
#
# Usage: send_notification <message>
# Returns 0 if the API accepted it (HTTP 2xx), 1 otherwise.
function send_notification()
{
  local message="$1"

  if [[ -z "${SIGNAL_SENDER}" || -z "${SIGNAL_RECIPIENTS}" ]]; then
    log "ERROR: SIGNAL_SENDER and SIGNAL_RECIPIENTS must be set - skipping notification"
    return 1
  fi

  if [[ "${DRY_RUN}" == "1" ]]; then
    message="[DRY RUN] ${message}"
  fi

  local url="${SIGNAL_API_ENDPOINT%/}/v2/send"

  # Build the recipients JSON array
  local recipient recipients_json=""
  for recipient in ${SIGNAL_RECIPIENTS}; do
    recipients_json+="${recipients_json:+,}\"$(json_escape "${recipient}")\""
  done

  local payload
  payload="{\"message\": \"$(json_escape "${message}")\", \"number\": \"$(json_escape "${SIGNAL_SENDER}")\", \"recipients\": [${recipients_json}]}"

  local http_code
  http_code=$(curl -X POST                                         \
                   -H "Content-Type: application/json"             \
		   "${url}"                                        \
                   -d "${payload}"                                 \
                   -s -o /dev/null                                 \
                   -w "%{http_code}"                               \
		   --max-time "${NOTIFY_TIMEOUT}")                 \

  log "signal send returned HTTP ${http_code}"
  [[ "${http_code}" =~ ^2 ]]
}


# Shut down every other machine on the network over SSH, running
# SHUTDOWN_CMDS[target] on each target in SHUTDOWN_ORDER (both from .env).
#
# Do NOT shut down warden here - shutdown_self() handles that last.
function shutdown_all_devices()
{
  if [[ ${#SHUTDOWN_ORDER[@]} -eq 0 ]]; then
    log "WARNING: SHUTDOWN_ORDER is empty - no devices to shut down"
    return 0
  fi

  # Warn about targets that have a command but would never be run
  local target
  for target in "${!SHUTDOWN_CMDS[@]}"; do
    if [[ " ${SHUTDOWN_ORDER[*]} " != *" ${target} "* ]]; then
      log "WARNING: ${target} is in SHUTDOWN_CMDS but not SHUTDOWN_ORDER - skipping it"
    fi
  done

  # user@host -> ssh exit code
  local -A results=()
  local cmd rc failed=0

  for target in "${SHUTDOWN_ORDER[@]}"; do
    # :- so a missing entry is reported instead of tripping `set -u`
    cmd="${SHUTDOWN_CMDS[${target}]:-}"

    if [[ -z "${cmd}" ]]; then
      log "ERROR: no command for ${target} in SHUTDOWN_CMDS - skipping it"
      results["${target}"]="no command"
      failed=1
      send_notification "❌ Shutdown failed for ${target#*@}"
      continue
    fi

    if [[ "${DRY_RUN}" == "1" ]]; then
      log "[dry-run] would run '${cmd}' on ${target}"
      results["${target}"]="dry-run"
      send_notification "✅ ${target#*@} shutdown successfully"
      continue
    fi

    log "powering off ${target} ('${cmd}')"
    ssh -o BatchMode=yes -o ConnectTimeout=5 "${target}" "${cmd}"
    rc=$?
    results["${target}"]="${rc}"

    # Machine name in notifications is the host part of user@host
    if [[ ${rc} -ne 0 ]]; then
      log "WARNING: '${cmd}' on ${target} exited ${rc}"
      failed=1
      send_notification "❌ Shutdown failed for ${target#*@}"
    else
      send_notification "✅ ${target#*@} shutdown successfully"
    fi
  done

  log "shutdown_all_devices summary:"
  for target in "${SHUTDOWN_ORDER[@]}"; do
    log "  ${target}: ${results[${target}]}"
  done

  return ${failed}
}


# Power off this machine (warden), last.
#
# The poweroff is scheduled SELF_SHUTDOWN_DELAY seconds out, and the final
# notification is sent while it waits - nothing can be sent once it's off.
# systemd-run hands the timer to PID 1, so it still fires even if upsmon (and
# this script with it) gets killed as the system goes down.
function shutdown_self()
{
  local name="${HOSTNAME%%.*}"

  if [[ "${DRY_RUN}" == "1" ]]; then
    log "[dry-run] would schedule ${name} poweroff in ${SELF_SHUTDOWN_DELAY}s"
    send_notification "✅ ${name} shutdown successfully"$'\n\n'"Shutdown complete"
    return 0
  fi

  log "scheduling ${name} poweroff in ${SELF_SHUTDOWN_DELAY}s"
  # AccuracySec defaults to 1 minute, which would let the timer fire late
  if systemd-run --on-active="${SELF_SHUTDOWN_DELAY}"  \
                 --timer-property=AccuracySec=1s       \
                 systemctl poweroff; then
    send_notification "✅ ${name} shutdown successfully"$'\n\n'"Shutdown complete"
    return 0
  fi

  # Scheduling failed - report it, then power off right away anyway rather
  # than let the UPS die under a running machine
  log "ERROR: failed to schedule ${name} poweroff - powering off now"
  send_notification "❌ Shutdown failed for ${name}"
  systemctl poweroff
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
  send_notification "${title}"$'\n\n'"${body}" || log "continuing despite notification failure"
  shutdown_all_devices
  shutdown_self
}

main "$@"
