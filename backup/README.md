# Backup scripts for homelab

1. Fill in all fields in env file
2. Create a file named 'gpgpass' containing the desired encryption password for borg backups
3. Create a file named 'bwpass' containing the encryption password for bitwarden backups
4. For both 'gpgpass' and 'bwpass'
   ```
   chmod 600 <filename>
   chown root:root <filename>
   ```
5. Set up a cron job to execute files.sh, server.sh, music.sh, and misc.sh when desired.
    - Make sure to stagger to prevent backup corruption. For example, I execute music.sh at 2am, misc.sh at 3am, files.sh every 4 hours, and server.sh at 5am.
6. Set up SSMTP to enable email notifications about your backups (/etc/ssmtp/ssmtp.conf)


#### `manual-usbs-misc-backup.sh`
- Create a file named 'backupcodespass' containing the encryption password for backup_codes.txt in misc backup
   ```
   chmod 600 backupcodespass
   chown root:root backupcodespass
   ```

- As part of my 3-2-1 backup system, I have 2x USB sticks in a fireproof safe with the very basics that I would need to restore backups in a worst-case-scenario.



## Resources:
- [Backup with Borg](https://jstaf.github.io/2018/03/12/backups-with-borg-rsync.html)
