#!/usr/bin/env bash

if ! command -v bash &> /dev/null; then
  pkg install bash
fi

if [[ "$(id -u)" -ne 0 ]]; then
    echo "This script must be run as root" 
    exit 1
fi

SCRIPTS_BASE_DIR=$(realpath "$(dirname "$(realpath "$0")")/../../..")

echo "Updating packages and repositories..."
pkg update

# Install smartmontools
pkg install smartmontools
cp /usr/local/etc/smartd.conf.sample /usr/local/etc/smartd.conf
sysrc smartd_enable="YES"
service smartd enable
service smartd start

# Install OPNSense backup action
echo
echo "Installing and configuring OPNSense backup OPNSense action..."
cp ./actions_backupopnsense.conf /usr/local/opnsense/service/conf/actions.d
sed -i "" "s|<scriptsdir>|${SCRIPTS_BASE_DIR}|g" /usr/local/opnsense/service/conf/actions.d/actions_backupopnsense.conf

# Install drive health monitoring action
echo
echo "Installing and configuring drive health monitoring OPNSense action..."
cp ./actions_drivehealth.conf /usr/local/opnsense/service/conf/actions.d
sed -i "" "s|<scriptsdir>|${SCRIPTS_BASE_DIR}|g" /usr/local/opnsense/service/conf/actions.d/actions_drivehealth.conf

# Restart configd to index new OPNSense actions
echo
echo "Restarting config to index new OPNSense actions..."
service configd restart

# Set up email notifications
cd "${SCRIPTS_BASE_DIR}/os/services/email"
./setup.sh

echo
echo "Setup complete! Please schedule cron jobs for your new actions from the OPNSense web UI."
