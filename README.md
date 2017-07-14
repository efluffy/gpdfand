# Fan control daemon for GPD Pocket

### Installations
#### Using a primitive shell installation script

`$ sudo sh install.sh`

#### ...or do it manually like a B055!

**Files go to:**
```
gpdfand.service => /etc/systemd/system/gpdfand.service
gpdfand => /lib/systemd/system-sleep/gpdfand
gpdfand.pl => /usr/local/bin/gpdfand
```

**Change executables permissions:**
`chmod +x /lib/systemd/system-sleep/gpdfand /usr/local/bin/gpdfand`

**Install dependencies:**
`apt-get -y install libproc-daemon-perl libproc-pid-file-perl liblog-dispatch-perl`

**Install Service:**
```
systemctl daemon-reload<br>
systemctl enable gpdfand.service<br>
systemctl start gpdfand.service<br>
```

No warranty blah blah do whatever with it...
