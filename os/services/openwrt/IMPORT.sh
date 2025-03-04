#!/bin/bash

MSMTPRC_PATH="~/.config/msmtp/config"

# Install msmtp
#opkg update
#opg install msmtp msmtp-mta

# SMTP Host URL
echo
read -p "Enter SMTP Host URL for your mailserver (no http:// or https://): " SMTP_HOST_URL 

# Email
echo
read -p "Enter your email: " EMAIL_USERNAME

# Password
echo
read -s -p "Enter the password for ${EMAIL_USERNAME}: " EMAIL_PASSWORD

# Copy test config file to final location
MSMTPRC_PATH=$(eval echo ${MSMTPRC_PATH})
mkdir -p $(dirname ${MSMTPRC_PATH})
sudo cp ./msmtprc ${MSMTPRC_PATH}

# Splice the required fields into the final config file
sudo sed -i "s|<msmtp_host>|${SMTP_HOST_URL}|g" ${MSMTPRC_PATH}
sudo sed -i "s|<msmtp_user>|${EMAIL_USERNAME}|g" ${MSMTPRC_PATH}
sudo sed -i "s|<msmtp_password>|${EMAIL_PASSWORD}|g" ${MSMTPRC_PATH}

# Set proper permissions
echo "Setting permissions for ${MSMTPRC_PATH}..."
sudo chmod 600 ${MSMTPRC_PATH}

# Send test email
echo
echo "Test email!" | msmtp "${EMAIL_USERNAME}"
