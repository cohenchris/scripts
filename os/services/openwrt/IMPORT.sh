#!/bin/bash

if [[ "$(id -u)" -ne 0 ]]; then
    echo "This script must be run as root" 
    exit 1
fi

# Install msmtp
opkg update
opkg install msmtp msmtp-mta

# SMTP Host URL
echo
read -p "Enter SMTP Host URL for your mailserver (no http:// or https://): " SMTP_HOST_URL 

# Email
echo
read -p "Enter your root email: " EMAIL_USERNAME

# Password
echo
read -s -p "Enter the password for ${EMAIL_USERNAME}: " EMAIL_PASSWORD

# Copy test config file to final location
MSMTPRC_PATH="/etc/msmtprc"
mkdir -p $(dirname ${MSMTPRC_PATH})
cp ./msmtprc ${MSMTPRC_PATH}

# Splice the required fields into the final config file
sed -i "s|<msmtp_host>|${SMTP_HOST_URL}|g" ${MSMTPRC_PATH}
sed -i "s|<msmtp_user>|${EMAIL_USERNAME}|g" ${MSMTPRC_PATH}
sed -i "s|<msmtp_password>|${EMAIL_PASSWORD}|g" ${MSMTPRC_PATH}

# Set proper permissions
echo
echo "Setting permissions for ${MSMTPRC_PATH}..."
chmod 600 ${MSMTPRC_PATH}

# Send test email
echo
echo "Test email!" | msmtp "${EMAIL_USERNAME}"

if [ $? -ne 0 ]; then
  echo
  echo "ERROR: MSMTP setup failed, manual intervention required."
  echo "Please check config file at \"${MSMTPRC_PATH}\""
else
  echo
  echo "MSMTP setup was successful!"
fi
