# Setup Email Notifications

Install and configure a system which allows the host machine to send email notifications.




# Table of Contents

- [MSMTP SMTP client](#MSMTP-SMTP-client)
  - [Prerequisites](#Prerequisites)
  - [Use](#Use)
- [Mutt E-Mail Client](#Mutt-E-Mail-Client)
  - [Prerequisites](#Prerequisites-1)
  - [Use](#Use-1)




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

2. Automated setup using [`setup.sh`](setup.sh)

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

2. Automated setup using [`setup.sh`](setup.sh)

This script will prompt you for your SMTP URL, email, and password.
Once provided, it will copy the config file so that it's visible to Mutt and fill in your details.
