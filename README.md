# Fan control daemon for GPD Pocket

## Installation:
### Using a primitive shell installation script
```
$ sudo sh install.sh
```

### ...or do it manually like a B055!

**Files go to:**
```
gpdfand.service => /etc/systemd/system/gpdfand.service
gpdfand => /lib/systemd/system-sleep/gpdfand
gpdfand.pl => /usr/local/bin/gpdfand
```

**Change executables permissions:**
```
chmod +x /lib/systemd/system-sleep/gpdfand /usr/local/bin/gpdfand
```

**Install dependencies:**
```
apt-get -y install libproc-daemon-perl libproc-pid-file-perl liblog-dispatch-perl
```

**Install Service:**
```
systemctl daemon-reload
systemctl enable gpdfand.service
systemctl start gpdfand.service
```

No warranty blah blah do whatever with it...
