# OpenWRT Services

Custom services and scripts for OpenWRT.

---

## MSMTP SMTP client
[`msmtprc`](msmtprc)

This is a configuration file for the `msmtp` SMTP client. This is what will allow email notifications to be sent automatically via cron jobs and privileged scripts.

### Prerequisites
Before configuring `msmtp`, please install the following:
- `msmtp`
- `msmtp-mta`

### Use
Two options are available for setup:

1. Manual setup

First, fill in the config file:
  - `<msmtp_host>` will be your SMTP URL
  - `<msmtp_user>` will be the email you would like to send mail as
  - `<msmtp_password>` will be the password for `<msmtp_user>`

Then, copy into the proper location + set permissions
```sh
cp ./msmtprc /etc/msmtprc
chown root:root /etc/msmtprc
chmod 600 /etc/msmtprc
```

2. Automated setup using [`IMPORT.sh`](IMPORT.sh)

This script will prompt you for your SMTP URL, email, and password.
Once provided, it will copy the config file so that it's visible to MSMTP, fill in your details, and set proper permissions.
