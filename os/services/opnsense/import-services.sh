#!/bin/bash

# Install Glances webserver FreeBSD service
echo "Installing Glances webserver FreeBSD service..."
cp ./glances /usr/local/etc/rc.d
echo 'glances_enable="YES"' >> /etc/rc.conf
service glances enable
service glances start

# Install OPNSense backup action
echo
echo "Installing OPNSense backup OPNSense action..."
cp ./actions_backupopnsense.conf /usr/local/opnsense/service/conf/actions.d

# Install Glances auto-restart action
echo
echo "Installing Glances auto-restart OPNSense action..."
cp ./actions_restartglances.conf /usr/local/opnsense/service/conf/actions.d

# Restart configd to index new OPNSense actions
echo
echo "Restarting config to index new OPNSense actions..."
service configd restart

echo "Import complete! Please schedule cron jobs for your new actions from the OPNSense web UI."
