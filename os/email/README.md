# Setup Email Notifications

Install and configure email on the host machine.




# Table of Contents

- [Email Group](#Email-Group)
  - [Adding a user to the group](#Adding-a-user-to-the-group)
- [MSMTP SMTP client](#MSMTP-SMTP-client)
  - [Prerequisites](#Prerequisites)
  - [Use](#Use)
- [Mutt E-Mail Client](#Mutt-E-Mail-Client)
  - [Prerequisites](#Prerequisites-1)
  - [Use](#Use-1)
- [Automated Email Setup Script](#Automated-Email-Setup-Script)
  - [Use](#Use-2)




## Email Group

The `msmtp` and `mutt` config files are owned by `root:email` with permissions `640`.
The `msmtp` config contains the SMTP password, so only `root` and members of the `email` group can read it.

**Any non-root user that needs to send email must be a member of the `email` group.**
`root` can always read the config files and does not need to be added.

Every member of the `email` group can read the SMTP password in plain text, so only add users you trust with it.


### Adding a user to the group

Replace `<user>` with the user that will be sending email. Run these as root.

#### Debian-based (Debian, Ubuntu, etc.)
```sh
usermod -aG email <user>
```

#### Arch Linux
```sh
usermod -aG email <user>
```

#### OpenWRT
OpenWRT's BusyBox does not include `usermod` by default, so install it first:
```sh
apk add shadow-usermod
usermod -aG email <user>
```

If you'd rather not install anything, you can edit `/etc/group` directly and add the user to the end of the `email` line.
Separate multiple users with commas:
```
email:x:<gid>:<user>,<other_user>
```

Most OpenWRT setups run everything as `root`, and in that case you don't need to add anyone.

#### OPNSense (FreeBSD)
```sh
pw groupmod email -m <user>
```

OPNSense manages its users and groups from its own config (`System > Access` in the web UI) and may overwrite manual changes to `/etc/group` during upgrades or reboots.
After a reboot, run `id <user>` to make sure the user is still in the group.

#### Verify
The new group membership takes effect the next time the user logs in.
Log out and back in, then check:
```sh
id <user>
```
The output should include `email`.

To pick up the group in your current shell without logging out, run `newgrp email`.




## MSMTP SMTP client
[`msmtprc`](msmtprc)

This is a configuration file for the `msmtp` SMTP client. This is one of two parts which will allow email notifications to be sent automatically via cron jobs and privileged scripts.

### Prerequisites
Before configuring `msmtp`, please install the following:
- `msmtp`
- `msmtp-mta`

The `email` group must also exist. See [Email Group](#Email-Group).

### Use
Two options are available for setup:

1. Manual setup

First, fill in the config file:
  - `<email_smtp_url>` - your SMTP URL
  - `<email_username>` - the email you would like to send mail as
  - `<email_password>` - the password for `<email_username>`
  - `<tls_trust_file>` - path to the TLS certificates file

Then, copy into the proper location + set ownership and permissions:
```sh
cp ./msmtprc /etc/msmtprc
chown root:email /etc/msmtprc
chmod 640 /etc/msmtprc
```

On OPNSense, use `/usr/local/etc/msmtprc` instead of `/etc/msmtprc`.


2. Automated setup using [`setup.sh`](setup.sh)




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
  - `<msmtp_bin_location>` - path to the `msmtp` binary (`/usr/bin/msmtp` on Linux, `/usr/local/bin/msmtp` on OPNSense).

Then, copy into the proper location + set ownership and permissions:
```sh
cp ./muttrc /etc/Muttrc
chown root:email /etc/Muttrc
chmod 640 /etc/Muttrc
```

On OPNSense, use `/usr/local/etc/Muttrc` instead of `/etc/Muttrc`.


2. Automated setup using [`setup.sh`](setup.sh)




## Automated Email Setup Script
[`setup.sh`](setup.sh)

This is a system-agnostic script which installs and configures email on the local machine.
This is a two-part system - `msmtp` as an SMTP client, and `mutt` as an email client.
It will first install both packages and all required dependencies.
Then, it will prompt the user for their SMTP URL, email, and password.
Next, it will create the `email` group. If the group already exists, it will ask whether to reuse it and abort if you say no.
With this information, both `msmtp` and `mutt` will be configured based on the sample configuration files [`msmtprc`](msmtprc) and [`muttrc`](muttrc), owned by `root:email` with permissions `640`.
Finally, it will send a test email with each of them.

The script does **not** add any users to the `email` group. Once it finishes, follow [Adding a user to the group](#Adding-a-user-to-the-group) for each non-root user that should be able to send email.


### Use
Call this script from the command line as root:
```sh
./setup.sh
```
