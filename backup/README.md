# Backup scripts for homelab

1. Fill in all fields in env file
2. Edit ha-notify path in common.sh
3. Create a file named 'gpgpass' containing the encryption password for backups.
4. Create a file named 'bwpass' containing the encryption password for bw backup
5. For both 'gpgpass' and 'bwpass'
   ```
   chmod 600 <filename>
   chown root:root <filename>
   ```
5. Set up a cron job to execute files.sh, server.sh, music.sh, and misc.sh when desired
6. Set up SMTP for your server (/etc/ssmtp/ssmtp.conf)


## Resources:
- [Backup with Borg](https://jstaf.github.io/2018/03/12/backups-with-borg-rsync.html)
