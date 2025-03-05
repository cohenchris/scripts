#!/bin/bash

if [[ "$(id -u)" -ne 0 ]]; then
    echo "This script must be run as root" 
    exit 1
fi

# Install packages
if command -v apt &> /dev/null; then
  echo "Detected apt (Raspbian). Installing packages..."
  REALNAME="Backups Server"
  apt-get update && apt-get upgrade
  apt install mutt msmtp msmtp-mta
elif command -v pkg &> /dev/null; then
  echo "Detected pkg (OPNSense). Installing packages..."
  REALNAME="OPNSense"
  echo 'FreeBSD: { enabled: yes }' > /usr/local/etc/pkg/repos/FreeBSD.conf
  pkg install git autoconf automake libtool gettext texinfo pkgconf gnutls gmake

  # Install msmtp from source
  git clone https://git.marlam.de/git/msmtp.git
  cd msmtp
  autoreconf -if
  ./configure
  make && make install
  cd ../
  rm -r msmtp

  # Install mutt from source
  git clone https://gitlab.com/muttmua/mutt.git
  cd mutt
  ./prepare --prefix=/usr/local --enable-smtp --with-ssl
  make && make install
  cd ../
  rm -r mutt
elif command -v opkg &> /dev/null; then
  echo "Detected opkg (OpenWRT). Installing packages..."
  REALNAME="OpenWRT"
  opkg update
  opkg install coreutils-realpath curl mutt msmtp msmtp-mta
elif command -v pacman &> /dev/null; then
  echo "Detected pacman (Arch). Installing packages..."
  REALNAME="Phrog"
  pacman -Syu
  pacman -S msmtp msmtp-mta mutt
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

# Send test email with msmtp
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

# Send test email with mutt
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
