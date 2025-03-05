#!/bin/bash

if [[ "$(id -u)" -ne 0 ]]; then
    echo "This script must be run as root" 
    exit 1
fi

# Install packages
if command -v apt &> /dev/null; then
  echo "Detected apt (Raspbian). Installing packages..."
  apt-get update && apt-get upgrade
  apt install mutt msmtp msmtp-mta
  REALNAME="Backups Server"
elif command -v pkg &> /dev/null; then
  echo "Detected pkg (OPNSense). Installing packages..."
  pkg update
  pkg install mutt msmtp msmtp-mta
  REALNAME="OPNSense"
elif command -v opkg &> /dev/null; then
  echo "Detected opkg (OpenWRT). Installing packages..."
  opkg update
  opkg install coreutils-realpath curl mutt msmtp msmtp-mta
  REALNAME="OpenWRT"
else
    echo "Package manager not recognized. Please install packages manually."
    exit 1
fi


echo "Configuring MSMTP and Mutt so that this system can send email notifications..."
# SMTP Host URL
echo
read -p "Enter the FQDN for your SMTP server: " SMTP_HOST_URL 

# Email
echo
read -p "Enter your email: " EMAIL_USERNAME

# Password
echo
read -s -p "Enter the password for ${EMAIL_USERNAME}: " EMAIL_PASSWORD


# Copy test config file to final location
MSMTPRC_PATH="/etc/msmtprc"
mkdir -p $(dirname ${MSMTPRC_PATH}) 2>/dev/null
cp ./msmtprc "${MSMTPRC_PATH}"

# Splice the required fields into the final config file
if [ "${REALNAME}" = "OPNSense" ]; then
  # sed works a bit differently on OPNSense
  sed -i "" "s|<email_smtp_url>|${SMTP_HOST_URL}|g" ${MSMTPRC_PATH}
  sed -i "" "s|<email_username>|${EMAIL_USERNAME}|g" ${MSMTPRC_PATH}
  sed -i "" "s|<email_password>|${EMAIL_PASSWORD}|g" ${MSMTPRC_PATH}
else
  sed -i "s|<email_smtp_url>|${SMTP_HOST_URL}|g" ${MSMTPRC_PATH}
  sed -i "s|<email_username>|${EMAIL_USERNAME}|g" ${MSMTPRC_PATH}
  sed -i "s|<email_password>|${EMAIL_PASSWORD}|g" ${MSMTPRC_PATH}
fi

# Set proper permissions
echo
echo "Setting permissions for ${MSMTPRC_PATH}..."
chmod 600 ${MSMTPRC_PATH}

# Send test email
echo
echo "Test msmtp email!" | msmtp "${EMAIL_USERNAME}"

if [ $? -ne 0 ]; then
  echo
  echo "ERROR: MSMTP setup failed, manual intervention required."
  echo "Please check config file at \"${MSMTPRC_PATH}\""
  exit 1
else
  echo
  echo "MSMTP setup was successful!"
fi

# Set up mutt
MUTTRC_PATH="/root/.muttrc"
mkdir -p $(dirname ${MUTTRC_PATH}) 2>/dev/null
cp ./muttrc "${MUTTRC_PATH}"

# Splice the required fields into the final config file
if [ "${REALNAME}" = "OPNSense" ]; then
  # sed works a bit differently on OPNSense
  sed -i "" "s|<realname>|\"${REALNAME}\"|g" ${MUTTRC_PATH}
  sed -i "" "s|<email_username>|${EMAIL_USERNAME}|g" ${MUTTRC_PATH}
else
  sed -i "s|<realname>|\"${REALNAME}\"|g" ${MUTTRC_PATH}
  sed -i "s|<email_username>|${EMAIL_USERNAME}|g" ${MUTTRC_PATH}
fi

echo "Test mutt email!" | mutt -s "Test mutt" -- ${EMAIL_USERNAME}
if [ $? -ne 0 ]; then
  echo
  echo "ERROR: Mutt setup failed, manual intervention required."
  echo "Please check config file at \"${MUTTRC_PATH}\""
  exit 1
else
  echo
  echo "Mutt setup was successful!"
fi
