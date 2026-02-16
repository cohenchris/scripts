# Setup Email Notifications

Install and configure email on the host machine.




# Table of Contents

- [MSMTP SMTP client](#MSMTP-SMTP-client)
  - [Prerequisites](#Prerequisites)
  - [Use](#Use)
- [Mutt E-Mail Client](#Mutt-E-Mail-Client)
  - [Prerequisites](#Prerequisites-1)
  - [Use](#Use-1)
- [Automated Email Setup Script](#Automated-Email-Setup-Script)
  - [Use](#Use-2)




## MSMTP SMTP client
[`msmtprc`](msmtprc)

This is a configuration file for the `msmtp` SMTP client. This is one of two parts which will allow email notifications to be sent automatically via cron jobs and privileged scripts.

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

Then, copy into the proper location + set permissions:
```sh
cp ./msmtprc /etc/msmtprc
chown root:root /etc/msmtprc
chmod 600 /etc/msmtprc
```


2. Automated setup using [`email-setup.sh`](email-setup.sh)




## Mutt E-Mail Client
[`muttrc`](muttrc)

This is a configuration file for the `mutt` email client.
This is one of parts which will allow email notifications to be sent automatically via cron jobs and privileged scripts.

### Prerequisites
Before configuring `mutt`, please install `mutt` and configure the [MSMTP SMTP Client](#MSMTP-SMTP-Client) as described above.

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


2. Automated setup using [`email-setup.sh`](email-setup.sh)




## Automated Email Setup Script
[`email-setup.sh`](email-setup.sh)

This is a system-agnostic script which installs and configures email on the local machine.
This is a two-part system - `msmtp` as an SMTP client, and `mutt` as an email client.
It will first install both packages and all required dependencies.
Then, it will prompt the user for their SMTP URL, email, and password.
With this information, both `msmtp` and `mutt` will be configured based on the sample configuration files [`msmtprc`](msmtprc) and [`muttrc`](muttrc).


### Use
Call this script from the command line:
```sh
./email-setup.sh
```
