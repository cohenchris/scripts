#!/bin/bash

# Telnet connection details
HOST=""
USER=""
PASS=""

function parse_power_consumption()
{
  output=$(echo -e "$USER\r$PASS\rshow power inline consumption\r \r \rexit\r" | nc switch.lan 23 2>/dev/null)

  # Parse the output to get the values for "ap" and "backups"
  backups=$(echo "$output" | awk '/gi12/ {print $2}')
  ap=$(echo "$output" | awk '/gi14/ {print $2}')
}

# Parse and handle arguments
if [ "$1" == "ap" ]; then
  parse_power_consumption
  echo $ap
elif [ "$1" == "backups" ]; then
  parse_power_consumption
  echo $backups
else
  echo "Invalid argument - choose one of [ap, backups]."
  exit 1
fi
