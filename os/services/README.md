# System Services

Custom services and scripts that are not specific to one OS.




# Table of Contents

- [MSMTP SMTP client](#MSMTP-SMTP-client)
  - [Prerequisites](#Prerequisites)
  - [Use](#Use)
- [Mutt E-Mail Client](#Mutt-E-Mail-Client)
  - [Prerequisites](#Prerequisites-1)
  - [Use](#Use-1)
- [Arch Linux Services](#Arch-Linux-Services)
- [OPNSense Services](#OPNSense-Services)
- [OpenWRT Services](#OpenWRT-Services)




## MSMTP SMTP client
[`msmtprc`](msmtprc)

This is a configuration file for the `msmtp` SMTP client. This is one part of what will allow email notifications to be sent automatically via cron jobs and privileged scripts.

### Prerequisites
Before configuring `msmtp`, please install the following:
- `msmtp`
- `msmtp-mta`

### Use
Two options are available for setup:

1. Manual setup

First, fill in the config file:
  - `<email_smtp_url>` - your SMTP URL
  - `<email_username>` - the email you would like to send mail as
  - `<email_password>` - the password for `<email_username>`
  - `<tls_trust_file>` - path to the TLS certificates file

Then, copy into the proper location + set permissions
```sh
cp ./msmtprc /etc/msmtprc
chown root:root /etc/msmtprc
chmod 600 /etc/msmtprc
```

2. Automated setup using [`setup-email.sh`](setup-email.sh)

This script will prompt you for your SMTP URL, email, and password.
Once provided, it will copy the config file so that it's visible to MSMTP, fill in your details, and set proper permissions.



## Mutt E-Mail Client
[`muttrc`](muttrc)

This is a configuration file for the `mutt` email client.
This is one part of what will allow email notifications to be sent automatically via cron jobs and privileged scripts.

### Prerequisites
Before configuring `mutt`, please install `mutt` and follow above instructions to set up `msmtp`.

### Use
Two options are available for setup:

1. Manual setup

First, fill in the config file:
  - `<email_username>` - the email you would like to send mail as, should match the value configured in `msmtp` above.
  - `<realname>` - the name attached to the email.

Then, copy into the proper location
```sh
cp ./muttrc /root/.muttrc
```

2. Automated setup using [`setup-email.sh`](setup-email.sh)

This script will prompt you for your SMTP URL, email, and password.
Once provided, it will copy the config file so that it's visible to Mutt and fill in your details.




## Arch Linux Services
[`arch/`](arch/)

Custom services and configuration files for a typical Linux machine.
The import script is tailored towards Arch Linux, but these services should work on any systemd-based Linux distribution.




## OPNSense Services
[`opnsense/`](opnsense/)

Custom services and scripts for a FreeBSD-based OPNSense distribution.




## OpenWRT Services
[`openwrt/`](openwrt/)

Custom services and scripts for a Linux-based OpenWRT distribution.
