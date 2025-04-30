#!/bin/bash

if [[ "$(id -u)" -ne 0 ]]; then
    echo "This script must be run as root" 
    exit 1
fi

SCRIPTS_BASE_DIR=$(realpath "$(dirname "$(realpath "$0")")/../../..")

# Install Glances webserver FreeBSD service
echo "Installing Glances webserver FreeBSD service..."
pkg update
pkg install py311-glances
cp ./glances /usr/local/etc/rc.d
echo 'glances_enable="YES"' >> /etc/rc.conf
service glances enable
service glances start

# Install OPNSense backup action
echo
echo "Installing and configuring OPNSense backup OPNSense action..."
cp ./actions_backupopnsense.conf /usr/local/opnsense/service/conf/actions.d
sed -i "" "s|<scriptsdir>|${SCRIPTS_BASE_DIR}|g" /usr/local/opnsense/service/conf/actions.d/actions_backupopnsense.conf

# Install Glances auto-restart action
echo
echo "Installing and configuring Glances auto-restart OPNSense action..."
cp ./actions_restartglances.conf /usr/local/opnsense/service/conf/actions.d
sed -i "" "s|<scriptsdir>|${SCRIPTS_BASE_DIR}|g" /usr/local/opnsense/service/conf/actions.d/actions_restartglances.conf

# Install drive health monitoring action
echo
echo "Installing and configuring drive health monitoring OPNSense action..."
cp ./actions_drivehealth.conf /usr/local/opnsense/service/conf/actions.d
sed -i "" "s|<scriptsdir>|${SCRIPTS_BASE_DIR}|g" /usr/local/opnsense/service/conf/actions.d/actions_drivehealth.conf

# Restart configd to index new OPNSense actions
echo
echo "Restarting config to index new OPNSense actions..."
service configd restart

echo "Import complete! Please schedule cron jobs for your new actions from the OPNSense web UI."
