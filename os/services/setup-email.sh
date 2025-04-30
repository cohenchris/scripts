#!/bin/bash

if [[ "$(id -u)" -ne 0 ]]; then
    echo "This script must be run as root" 
    exit 1
fi

# Install packages
if command -v apt &> /dev/null; then
  echo "Installing packages for Raspbian..."
  REALNAME="Backups Server"
  apt-get update && apt-get upgrade
  apt install mutt msmtp msmtp-mta
elif command -v pkg &> /dev/null; then
  echo "Installing packages for OPNSense..."
  REALNAME="OPNSense"
  pkg install git autoconf automake libtool gettext texinfo pkgconf gnutls gmake lsblk

  # Install msmtp from source
  if ! command -v msmtp &> /dev/null; then
    git clone https://git.marlam.de/git/msmtp.git
    cd msmtp
    autoreconf -if
    ./configure
    make && make install
    cd ../
    rm -r msmtp
  fi

  # Install mutt from source
  if ! command -v mutt &> /dev/null; then
    git clone https://gitlab.com/muttmua/mutt.git
    cd mutt
    ./prepare --prefix=/usr/local --enable-smtp --with-ssl
    make && make install
    cd ../
    rm -r mutt
  fi
elif command -v opkg &> /dev/null; then
  echo "Installing packages for OpenWRT..."
  REALNAME="OpenWRT"
  opkg update
  opkg install coreutils-realpath curl mutt msmtp msmtp-mta
elif command -v pacman &> /dev/null; then
  echo "Installing packages for Arch..."
  REALNAME="Phrog"
  pacman -Syu
  pacman -S msmtp msmtp-mta mutt
else
    echo "Unable to auto-detect system, please install and configure msmtp, msmtp-mta, and mutt packages manually."
    exit 1
fi


echo "Configuring MSMTP and Mutt..."
# SMTP Host URL
echo
read -p "Enter the FQDN for your SMTP server (e.g. smtp.example.com): " SMTP_HOST_URL 

# Email
echo
read -p "Enter the email from which you would like to send notifications: " EMAIL_USERNAME

# Password
echo
read -s -p "Enter the password for user ${EMAIL_USERNAME}: " EMAIL_PASSWORD


if [ "${REALNAME}" = "OPNSense" ]; then
  # FreeBSD
  MSMTPRC_PATH="/usr/local/etc/msmtprc"
  MSMTP_BIN_LOCATION="/usr/local/bin/msmtp"
  TLS_TRUST_FILE="/usr/local/share/certs/ca-root-nss.crt"
else
  # Linux
  MSMTPRC_PATH="/etc/msmtprc"
  MSMTP_BIN_LOCATION="/usr/bin/msmtp"
  TLS_TRUST_FILE="/etc/ssl/certs/ca-certificates.crt"
fi

# Configure msmtp
# Copy template msmtprc config file to final location
mkdir -p $(dirname "${MSMTPRC_PATH}") 2>/dev/null
cp ./msmtprc "${MSMTPRC_PATH}"

# Splice msmtprc fields into the final config file
if [ "${REALNAME}" = "OPNSense" ]; then
  # sed works a bit differently on FreeBSD
  sed -i "" "s|<email_smtp_url>|${SMTP_HOST_URL}|g" "${MSMTPRC_PATH}"
  sed -i "" "s|<email_username>|${EMAIL_USERNAME}|g" "${MSMTPRC_PATH}"
  sed -i "" "s|<email_password>|${EMAIL_PASSWORD}|g" "${MSMTPRC_PATH}"
  sed -i "" "s|<tls_trust_file>|${TLS_TRUST_FILE}|g" "${MSMTPRC_PATH}"
else
  sed -i "s|<email_smtp_url>|${SMTP_HOST_URL}|g" "${MSMTPRC_PATH}"
  sed -i "s|<email_username>|${EMAIL_USERNAME}|g" "${MSMTPRC_PATH}"
  sed -i "s|<email_password>|${EMAIL_PASSWORD}|g" "${MSMTPRC_PATH}"
  sed -i "s|<tls_trust_file>|${TLS_TRUST_FILE}|g" "${MSMTPRC_PATH}"
fi

# Set proper permissions for msmtprc
echo
echo "Setting permissions for "${MSMTPRC_PATH}"..."
chmod 600 "${MSMTPRC_PATH}"

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


# Configure mutt
MUTTRC_PATH="/${USER}/.muttrc"
mkdir -p $(dirname ${MUTTRC_PATH}) 2>/dev/null
cp ./muttrc "${MUTTRC_PATH}"

# Splice muttrc fields into the final config file
if [ "${REALNAME}" = "OPNSense" ]; then
  # sed works a bit differently on OPNSense
  sed -i "" "s|<realname>|\"${REALNAME}\"|g" ${MUTTRC_PATH}
  sed -i "" "s|<email_username>|${EMAIL_USERNAME}|g" ${MUTTRC_PATH}
  sed -i "" "s|<msmtp_bin_location>|${MSMTP_BIN_LOCATION}|g" ${MUTTRC_PATH}
else
  sed -i "s|<realname>|\"${REALNAME}\"|g" ${MUTTRC_PATH}
  sed -i "s|<email_username>|${EMAIL_USERNAME}|g" ${MUTTRC_PATH}
  sed -i "s|<msmtp_bin_location>|${MSMTP_BIN_LOCATION}|g" ${MUTTRC_PATH}
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

echo
echo "Successfully configured MSMTP and Mutt!"
