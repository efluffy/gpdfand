#!/usr/bin/sh

if [ "$USER" != "root" ]
then
	echo "You must be root to execute this script"
	exit 1
fi

echo "Copying files to system..."
cp gpdfand.service /etc/systemd/system/gpdfand.service
cp gpdfand /lib/systemd/system-sleep/gpdfand
cp gpdfand.pl /usr/local/bin/gpdfand

echo "Chmod'ing executables..."
chmod +x /lib/systemd/system-sleep/gpdfand /usr/local/bin/gpdfand

echo "Getting neccessary dependencies..."
apt-get -qq -y install libproc-daemon-perl libproc-pid-file-perl liblog-dispatch-perl

echo "Installing gpdfand service..."
systemctl daemon-reload
systemctl enable gpdfand.service
systemctl start gpdfand.service

exit 0
