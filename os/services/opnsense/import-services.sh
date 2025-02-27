#!/bin/bash

SCRIPTS_BASE_DIR="$(dirname "$(realpath "$0")")/../../../"

# Install Glances webserver FreeBSD service
echo "Installing Glances webserver FreeBSD service..."
cp ./glances /usr/local/etc/rc.d
echo 'glances_enable="YES"' >> /etc/rc.conf
service glances enable
service glances start

# Install OPNSense backup action
echo
echo "Installing and configuring OPNSense backup OPNSense action..."
cp ./actions_backupopnsense.conf /usr/local/opnsense/service/conf/actions.d
sudo sed -i "s|<scriptsdir>|${SCRIPTS_BASE_DIR}|g" /usr/local/opnsense/service/conf/actions.d/actions_backupopnsense.conf

# Install Glances auto-restart action
echo
echo "Installing and configuring Glances auto-restart OPNSense action..."
cp ./actions_restartglances.conf /usr/local/opnsense/service/conf/actions.d
sudo sed -i "s|<scriptsdir>|${SCRIPTS_BASE_DIR}|g" /usr/local/opnsense/service/conf/actions.d/actions_restartglances.conf

# Restart configd to index new OPNSense actions
echo
echo "Restarting config to index new OPNSense actions..."
service configd restart

echo "Import complete! Please schedule cron jobs for your new actions from the OPNSense web UI."
