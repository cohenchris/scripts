#!/bin/bash

if [[ "$(id -u)" -ne 0 ]]; then
    echo "This script must be run as root" 
    exit 1
fi

GLANCES_HOST=localhost
GLANCES_PORT=61208

# Check if glances has crashed
curl --silent --output /dev/null ${GLANCES_HOST}:${GLANCES_PORT}
GLANCES_CRASHED=${?}

GLANCES_PID=$(ps -aux | grep glances | grep python | awk '{print $2}')

# If glances has crashed, restart the service
if [ ${GLANCES_CRASHED} -ne 0 ]; then
  [ ! -z "${GLANCES_PID}" ] && kill -9 ${GLANCES_PID}

  echo "glances service appears to be down. Restarting..."

  # Play nice with both Linux and FreeBSD
  if [ "$(uname)" = "FreeBSD" ]; then
    service glances restart
  else # Assuming systemd Linux
    systemctl restart glances
  fi
fi
