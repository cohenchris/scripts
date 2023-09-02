# Backup scripts for homelab

1. Fill in all fields in env file
2. Create a file named 'gpgpass' containing the encryption password for backups
3. Create a file named 'bwpass' containing the encryption password for bw backup
4. Set up a cron job to execute files.sh, server.sh, and music.sh
5. Set up SMTP for your server (/etc/ssmtp/ssmtp.conf)


## Resources:
- [Nextcloud Export-data](https://github.com/nextcloud/nextcloud-snap/blob/master/src/import-export/bin/export-data)
- [Nextcloud Tools](https://github.com/syseleven/nextcloud-tools)
- [Backup with Borg](https://jstaf.github.io/2018/03/12/backups-with-borg-rsync.html)
