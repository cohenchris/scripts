# Backup script for mediaserver and nextcloud

1. Copy sample.env -> env
2. Fill in all fields in env file
3. Create a file named 'gpgpass' containing the encryption password
4. Set up a cron job to execute backup.sh
5. Set up SMTP for your server (/etc/ssmtp/ssmtp.conf)


## Resources:
- [Nextcloud Export-data](https://github.com/nextcloud/nextcloud-snap/blob/master/src/import-export/bin/export-data)
- [Nextcloud Tools](https://github.com/syseleven/nextcloud-tools)
