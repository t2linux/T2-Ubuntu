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
deb http://de.archive.ubuntu.com/ubuntu/ focal main restricted universe multiverse 
deb-src http://de.archive.ubuntu.com/ubuntu/ focal main restricted universe multiverse
deb http://de.archive.ubuntu.com/ubuntu/ focal-security main restricted universe multiverse 
deb-src http://de.archive.ubuntu.com/ubuntu/ focal-security main restricted universe multiverse
deb http://de.archive.ubuntu.com/ubuntu/ focal-updates main restricted universe multiverse 
deb-src http://de.archive.ubuntu.com/ubuntu/ focal-updates main restricted universe multiverse    
EOF
apt-get update


echo >&2 "===]> Info: Install systemd and Ubuntu MBP Repo... ";

apt-get install -y systemd-sysv gnupg curl wget

mkdir -p /etc/apt/sources.list.d
echo "deb https://mbp-ubuntu-kernel.herokuapp.com/ /" > /etc/apt/sources.list.d/mbp-ubuntu-kernel.list
curl -L https://mbp-ubuntu-kernel.herokuapp.com/KEY.gpg | apt-key add -
apt-get update

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
    linux-image-5.6.4-mbp \
    linux-headers-5.6.4-mbp


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
    make \
    dracut

echo >&2 "===]> Info: Add custom drivers... ";

KERNEL_VERSION=5.6.4-mbp
BCE_DRIVER_GIT_URL=https://github.com/MCMrARM/mbp2018-bridge-drv.git
BCE_DRIVER_BRANCH_NAME=master
BCE_DRIVER_COMMIT_HASH=b43fcc069da73e051072fde24af4014c9c487286
APPLE_IB_DRIVER_GIT_URL=https://github.com/roadrunner2/macbook12-spi-driver.git
APPLE_IB_DRIVER_BRANCH_NAME=mbp15
APPLE_IB_DRIVER_COMMIT_HASH=90cea3e8e32db60147df8d39836bd1d2a5161871

mkdir -p /opt/drivers
mkdir -p "/lib/modules/${KERNEL_VERSION}/extra"

git clone --single-branch --branch ${BCE_DRIVER_BRANCH_NAME} ${BCE_DRIVER_GIT_URL} /opt/drivers/bce
git -C /opt/drivers/bce/ checkout ${BCE_DRIVER_COMMIT_HASH}
PATH=/usr/share/Modules/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/bin make -C /lib/modules/${KERNEL_VERSION}/build/ M=/opt/drivers/bce modules

git clone --single-branch --branch ${APPLE_IB_DRIVER_BRANCH_NAME} ${APPLE_IB_DRIVER_GIT_URL} /opt/drivers/touchbar
git -C /opt/drivers/touchbar/ checkout ${APPLE_IB_DRIVER_COMMIT_HASH}
PATH=/usr/share/Modules/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/bin make -C /lib/modules/${KERNEL_VERSION}/build/ M=/opt/drivers/touchbar modules

cp -rf /opt/drivers/bce/*.ko /lib/modules/${KERNEL_VERSION}/extra/
cp -rf /opt/drivers/touchbar/*.ko /lib/modules/${KERNEL_VERSION}/extra/

### Add custom drivers to be loaded at boot
echo -e 'hid-apple\nbcm5974\nsnd-seq\nbce\napple_ibridge\napple_ib_tb' > /etc/modules-load.d/bce.conf
echo -e 'blacklist thunderbolt' > /etc/modprobe.d/blacklist.conf
echo -e 'add_drivers+="hid_apple snd-seq bce"\nforce_drivers+="hid_apple snd-seq bce"' > /etc/dracut.conf
/usr/sbin/depmod -a ${KERNEL_VERSION}
dracut -f /boot/initramfs-$KERNEL_VERSION.img $KERNEL_VERSION

### Copy audio config files
mkdir -p /usr/share/alsa/cards/
mv -fv /tmp/setup_files/audio/AppleT2.conf /usr/share/alsa/cards/AppleT2.conf
mv -fv /tmp/setup_files/audio/apple-t2.conf /usr/share/pulseaudio/alsa-mixer/profile-sets/apple-t2.conf
mv -fv /tmp/setup_files/audio/91-pulseaudio-custom.rules /usr/lib/udev/rules.d/91-pulseaudio-custom.rules

echo >&2 "===]> Info: Remove unused applications ... ";

apt-get purge -y -qq \
     transmission-gtk \
     transmission-common \
     gnome-mahjongg \
     gnome-mines \
     gnome-sudoku \
     aisleriot \
     hitori\
     linux-headers-5.6.4-mbp \
     dracut

apt-get autoremove -y

echo >&2 "===]> Info: Reconfigure environment ... ";

locale-gen --purge en_US.UTF-8 en_US
echo -e 'LANG="C.UTF-8"\nLANGUAGE="C.UTF-8"\n' > /etc/default/locale

dpkg-reconfigure -f readline resolvconf

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
rm -rf /tmp/setup_files
rm -rf /opt/drivers

umount -lf /dev/pts
umount -lf /sys
umount -lf /proc

export HISTSIZE=0
