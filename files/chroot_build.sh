#!/bin/bash

set -eu -o pipefail


echo >&2 "===]> Info: Configure environment... ";

mount none -t proc /proc
mount none -t sysfs /sys
mount none -t devpts /dev/pts
export HOME=/root
export LC_ALL=C

echo "ubuntu-fs-live" > /etc/hostname


echo >&2 "===]> Info: Configure and update apt... ";

cat <<EOF > /etc/apt/sources.list
deb http://us.archive.ubuntu.com/ubuntu/ focal main restricted universe multiverse 
deb-src http://us.archive.ubuntu.com/ubuntu/ focal main restricted universe multiverse
deb http://us.archive.ubuntu.com/ubuntu/ focal-security main restricted universe multiverse 
deb-src http://us.archive.ubuntu.com/ubuntu/ focal-security main restricted universe multiverse
deb http://us.archive.ubuntu.com/ubuntu/ focal-updates main restricted universe multiverse 
deb-src http://us.archive.ubuntu.com/ubuntu/ focal-updates main restricted universe multiverse    
EOF

# echo "deb https://mbp-ubuntu-kernel.herokuapp.com/ /" > /etc/apt/sources.list.d/mbp-ubuntu-kernel.list
# wget -q -O - https://mbp-ubuntu-kernel.herokuapp.com/KEY.gpg | apt-key add -

apt-get update


echo >&2 "===]> Info: Install systemd... ";

apt-get install -y systemd-sysv


echo >&2 "===]> Info: Configure machine-id and divert... ";

dbus-uuidgen > /etc/machine-id
ln -fs /etc/machine-id /var/lib/dbus/machine-id
dpkg-divert --local --rename --add /sbin/initctl
ln -s /bin/true /sbin/initctl


echo >&2 "===]> Info: Install packages needed for Live System... ";

export DEBIAN_FRONTEND=noninteractive
apt-get install -y -qq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
    ubuntu-standard \
    casper \
    lupin-casper \
    discover \
    laptop-detect \
    os-prober \
    network-manager \
    resolvconf \
    net-tools \
    wireless-tools \
    wpagui \
    locales \
    linux-generic


echo >&2 "===]> Info: Install Graphical installer... ";

apt-get install -y -qq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
    ubiquity \
    ubiquity-casper \
    ubiquity-frontend-gtk \
    ubiquity-slideshow-ubuntu \
    ubiquity-ubuntu-artwork


echo >&2 "===]> Info: Install window manager... ";

apt-get install -y -qq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
    plymouth-theme-ubuntu-logo \
    ubuntu-desktop-minimal \
    ubuntu-gnome-wallpapers


echo >&2 "===]> Info: Install useful applications... ";

apt-get install -y -qq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
    git \
    curl \
    nano \
    gcc \
    expect \
    make


echo >&2 "===]> Info: Remove unused applications ... ";

apt-get purge -y -qq \
     transmission-gtk \
     transmission-common \
     gnome-mahjongg \
     gnome-mines \
     gnome-sudoku \
     aisleriot \
     hitori

apt-get autoremove -y


echo >&2 "===]> Info: Reconfigure environment ... ";

locale-gen --purge en_US.UTF-8 en_US
echo -e 'LANG="C.UTF-8"\nLANGUAGE="C.UTF-8"\n' > /etc/default/locale

dpkg-reconfigure -f readline resolvconf

# /usr/bin/expect<<EOF
# spawn dpkg-reconfigure -f readline resolvconf
# expect "updates?" { send "Yes\r" }
# expect "dynamic files?" { send "Yes\r" }
# EOF

cat <<EOF > /etc/NetworkManager/NetworkManager.conf
[main]
rc-manager=resolvconf
plugins=ifupdown,keyfile
dns=dnsmasq
[ifupdown]
managed=false
EOF
dpkg-reconfigure network-manager


echo >&2 "===]> Info: Cleanup the chroot environment... ";

truncate -s 0 /etc/machine-id
rm /sbin/initctl
dpkg-divert --rename --remove /sbin/initctl
apt-get clean
rm -rf /tmp/* ~/.bash_history

umount -lf /dev/pts
umount -lf /sys
umount -lf /proc

export HISTSIZE=0
