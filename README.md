fan control daemon for gpd pocket

files go:
gpdfand.service => /etc/systemd/system/gpdfand.service
gpdfand => /lib/systemd/system-sleep/gpdfand
gpdfand.pl => /usr/local/bin/gpdfand

to make work:
chmod +x /lib/systemd/system-sleep/gpdfand /usr/local/bin/gpdfand

apt-get -y install libproc-daemon-perl libproc-pid-file-perl liblog-dispatch-perl

systemctl daemon-reload
systemctl enable gpdfand.service
systemctl start gpdfand.service

no warranty blah blah do whatever with it
