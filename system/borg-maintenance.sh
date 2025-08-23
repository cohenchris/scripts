#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" 
    exit 1
fi


WORKING_DIR=$(dirname "$(realpath "$0")")
source "${WORKING_DIR}/.env"

require var BORG_REPOSITORIES

export BORG_PASSPHRASE=$(cat /home/phrog/scripts/backup/.borgpass)

# borg check --verify-data /path/to/repo
# borg compact /path/to/repo
# 
# 
# # To change compression level, run this
# borg recreate --compression zstd,6 /path/to/repo




# Verify contents of each repository
for repo in "${BORG_REPOSITORIES[@]}"; do
  echo "Verifying contents of borg repository ${repo}..."
  time borg -v check "${repo}" &
done

wait

# Compact segment files in each repository
for repo in "${BORG_REPOSITORIES[@]}"; do
  echo "Compacting borg repository ${repo}..."
  time borg -v compact "${repo}" &
done

wait
