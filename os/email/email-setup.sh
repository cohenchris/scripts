#!/usr/bin/env bash

# Bail if attempting to substitute an unset variable
set -u


if [[ "$(id -u)" -ne 0 ]]; then
    echo "This script must be run as root" 
    exit 1
fi


# Determine which client is running this script
# Raspbian Backup Server
if command -v apt &> /dev/null; then
  REALNAME="Backup Server"
# OpenWRT
elif command -v opkg &> /dev/null; then
  REALNAME="OpenWRT"
# Arch Linux Lab
elif command -v pacman &> /dev/null; then
  REALNAME="Phrog"
# OPNSense (FreeBSD)
elif command -v pkg &> /dev/null; then
  REALNAME="OPNSense"
# Unknown system
else
    echo "Unable to auto-detect system"
    exit 1
fi


# URL to an SMTP server
SMTP_HOST_URL=""
# Username from which email notifications will be sent
EMAIL_USERNAME=""
# Password for EMAIL_USERNAME
EMAIL_PASWORD=""

if [ "${REALNAME}" = "OPNSense" ]; then
  # FreeBSD paths
  MSMTPRC_PATH="/usr/local/etc/msmtprc"
  MSMTP_BIN="/usr/local/bin/msmtp"
  MUTTRC_PATH="/usr/local/etc/Muttrc"
  TLS_TRUST_FILE="/usr/local/share/certs/ca-root-nss.crt"
else
  # Linux paths
  MSMTPRC_PATH="/etc/msmtprc"
  MSMTP_BIN="/usr/bin/msmtp"
  MUTTRC_PATH="/etc/Muttrc"
  TLS_TRUST_FILE="/etc/ssl/certs/ca-certificates.crt"
fi


# Install packages which are required for email to be sent
# 1. mutt  - mail user agent
# 2. msmtp - SMTP client
# and any other packages which the first two depend on
function install_dependencies()
{
  # Exit immediately if a command exits with a non-zero status
  set -e

  # Raspbian Backup Server
  if [[ "${REALNAME}" = "Backup Server" ]]; then
    echo "Installing packages for Raspbian backup server..."
    apt-get update && apt-get upgrade
    apt install mutt msmtp msmtp-mta

  # OpenWRT
  elif [[ "${REALNAME}" = "OpenWRT" ]]; then
    echo "Installing packages for OpenWRT..."
    opkg update
    opkg install coreutils-realpath curl mutt msmtp msmtp-mta

  # Arch Linux Lab
  elif [[ "${REALNAME}" = "Phrog" ]]; then
    echo "Installing packages for lab..."
    pacman -Syu
    pacman -S msmtp msmtp-mta mutt

  # OPNSense (FreeBSD)
  elif [[ "${REALNAME}" = "OPNSense" ]]; then
    echo "Installing packages for OPNSense..."
    pkg install git autoconf automake libtool gettext texinfo pkgconf gnutls gmake

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

  # Unknown system
  else
      echo "Unable to auto-detect system, please install and configure msmtp, msmtp-mta, and mutt packages manually."
      exit 1
  fi

  # Reset setting which exits immediately if a command exits with a non-zero status
  set +e
}


# Ask user for credentials to an SMTP server
function get_email_credentials()
{
  # SMTP Host URL
  echo
  read -p "Enter the FQDN for your SMTP server (e.g. smtp.example.com): " SMTP_HOST_URL 

  # Email
  echo
  read -p "Enter the email from which you would like to send notifications: " EMAIL_USERNAME

  # Password
  echo
  read -s -p "Enter the password for user ${EMAIL_USERNAME}: " EMAIL_PASSWORD
}


# Configure the SMTP client 'msmtp'
function configure_msmtp()
{
  # Configure system-wide msmtprc
  echo "Configuring system-wide msmtprc..."
  mkdir -p $(dirname "${MSMTPRC_PATH}") 2>/dev/null
  cp ./msmtprc "${MSMTPRC_PATH}"
  chmod 600 "${MSMTPRC_PATH}"

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

  # Send test email with msmtp
  echo "Test msmtp email!" | msmtp "${EMAIL_USERNAME}"

  if [[ $? -ne 0 ]]; then
    echo "ERROR: MSMTP setup failed, manual intervention required."
    echo "Please check config file at \"${MSMTPRC_PATH}\""
    exit 1
  else
    echo "MSMTP setup was successful!"
  fi
}


# Configure the mail user agent 'mutt'
function configure_mutt()
{
  # Configure system-wide muttrc
  echo "Configuring system-wide muttrc..."
  mkdir -p $(dirname "${MUTTRC_PATH}") 2>/dev/null
  cp ./muttrc "${MUTTRC_PATH}"
  chmod 644 "${MUTTRC_PATH}"

  # Splice muttrc fields into the final config file
  if [ "${REALNAME}" = "OPNSense" ]; then
    # sed works a bit differently on OPNSense
    sed -i "" "s|<realname>|\"${REALNAME}\"|g" "${MUTTRC_PATH}"
    sed -i "" "s|<email_username>|${EMAIL_USERNAME}|g" "${MUTTRC_PATH}"
    sed -i "" "s|<msmtp_bin_location>|${MSMTP_BIN}|g" "${MUTTRC_PATH}"
  else
    sed -i "s|<realname>|\"${REALNAME}\"|g" "${MUTTRC_PATH}"
    sed -i "s|<email_username>|${EMAIL_USERNAME}|g" "${MUTTRC_PATH}"
    sed -i "s|<msmtp_bin_location>|${MSMTP_BIN}|g" "${MUTTRC_PATH}"
  fi

  # Send test email with mutt
  echo "Test mutt email!" | mutt -s "Test mutt" -- "${EMAIL_USERNAME}"

  if [[ $? -ne 0 ]]; then
    echo "ERROR: Mutt setup failed, manual intervention required."
    echo "Please check config file at \"${MUTTRC_PATH}\""
    exit 1
  else
    echo "Mutt setup was successful!"
  fi
}


install_dependencies
get_email_credentials
configure_msmtp
configure_mutt


echo
echo "Successfully configured email!"
