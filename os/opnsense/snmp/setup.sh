#!/usr/bin/env bash

SCRIPTS_DIR=$(realpath ../../../)
mkdir -p /usr/local/etc/snmp/
echo "pass_persist .1.3.6.1.4.1.99999.1 ${SCRIPTS_DIR}/os/opnsense/snmp/snmp-sysmon.py $(which python3) ${SCRIPTS_DIR}/system/system-monitor.py" > /usr/local/etc/snmp/snmpd.local.conf
configctl netsnmp restart
