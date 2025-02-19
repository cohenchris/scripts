Move these files into /etc/nut and set proper permissions.

```sh
cd /etc/nut
sudo chown -R root:nut ./*
sudo chmod 640 ./*
sudo systemctl enable nut.service
sudo systemctl start nut.service
```

Default user/pass is:
```
upsmon
password
```
