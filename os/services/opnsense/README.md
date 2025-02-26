# System Scripts

## Backup OPNSense + AdGuardHome
`backup_router.sh`

- Script that backs up OPNSense and AdGuardHome config files to a remote backup server

1. Highly suggest placing in /root
2. `chmod +x ./backup_router.sh`

## Backup Cron Jon Option in OPNSense
`actions_backuprouter.conf`

- Allows user to make backup on a cron job from the opnsense GUI

1. Place in `/usr/local/opnsense/service/conf/actions.d`
2.  `service configd restart`
3. To test - `configctl backuprouter backup`

## Restart Glances Service If Crashed
`restart_glances.sh`

- Script that restart the glances system service if it has crashed. This is a known issue in FreeBSD with glances and sensor monitoring.

1. Highly suggest placing in /root
2. `chmod +x ./restart_glances.sh`

## Glances Restart Cron Jon Option in OPNSense
`actions_restartglances.conf`

- Allows user to restart the glances system service if crashed

1. Place in `/usr/local/opnsense/service/conf/actions.d`
2.  `service configd restart`
3. To test - `configctl restartglances restart`

## Glances System Monitoring Startup Service
`glances`

- FreeBSD service which runs glances in webserver mode

1. Place in `/usr/local/etc/rc.d`
2. Make executable - `chmod +x ./glances`
3. Ensure the service is started on boot
- `echo 'glances_enable="YES"' >> /etc/rc.conf`
- `service glances enable`
- `service glances start`
