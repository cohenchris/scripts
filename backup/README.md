# Backups

## Setup
1. Fill in all fields in env file
2. Add the following entries to `pass`
    - `backup/backupcodes`
        - password for vimcrypt backup_codes.txt
    - `backup/borg`
        - borg archive encryption password
    - `backup/bw`
        - Bitwarden login password
5. Set up a cron job to execute files.sh, server.sh, music.sh, and critical-data.sh when desired.
    - Make sure to stagger to prevent backup corruption. For example, I execute critical-data.sh and music.sh at 3am, files.sh at 4am, and server.sh at 5am daily.
6. On the local backup server, set up a cron job to execute batocera.sh when desired
    - Batocera is a firmware image and cannot be modified (no installing new packages). Therefore, the backup must be triggered by the backup server, rather than Batocera itself.
7. Set up SSMTP and neofetch to enable email notifications about your backups (/etc/ssmtp/ssmtp.conf)
    - Install `ssmtp` and `neomutt`
    - `echo 'set sendmail="/usr/sbin/ssmtp"' > ~/.config/neomutt/neomuttrc`


## Manual Double USB Cold Backups
- As part of my 3-2-1 backup system, I have 2x USB sticks in a fireproof safe with the very basics that I would need to restore backups in a worst-case-scenario.


## Interacting with borg backups
To list the backups present in a borg archive store, run the following:

`sudo borg mount /path/to/borg/repository::<backup_name> /path/to/mountpoint`


To extract a given borg backup into the current directory, run the following:

`sudo borg extract /path/to/borg/repository::<backup_name>`


To mount a given borg backup to a specified mount point and view the backup without fully extracting, run the following:

`sudo borg mount /path/to/borg/repository::<backup_name> /path/to/mountpoint`


## Resources:
- [Backup with Borg](https://jstaf.github.io/2018/03/12/backups-with-borg-rsync.html)
