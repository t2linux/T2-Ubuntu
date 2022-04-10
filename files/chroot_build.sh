#!/bin/bash

set -eu -o pipefail

echo >&2 "===]> Info: Configure environment... "

mount none -t proc /proc
mount none -t sysfs /sys
mount none -t devpts /dev/pts

export HOME=/root
export LC_ALL=C

echo "ubuntu-fs-live" >/etc/hostname

echo >&2 "===]> Info: Configure and update apt... "

cat <<EOF >/etc/apt/sources.list
deb http://archive.ubuntu.com/ubuntu/ focal main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ focal main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ focal-security main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ focal-security main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ focal-updates main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ focal-updates main restricted universe multiverse
EOF
apt-get update

echo >&2 "===]> Info: Install systemd and Ubuntu MBP Repo... "

apt-get install -y systemd-sysv gnupg curl wget

echo >&2 "===]> Info: Configure machine-id and divert... "

dbus-uuidgen >/etc/machine-id
ln -fs /etc/machine-id /var/lib/dbus/machine-id
dpkg-divert --local --rename --add /sbin/initctl
ln -s /bin/true /sbin/initctl

echo >&2 "===]> Info: Install packages needed for Live System... "

export DEBIAN_FRONTEND=noninteractive
apt-get install -y -qq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
  ubuntu-standard \
  sudo \
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
  initramfs-tools \
  binutils \
  linux-firmware \
  grub-efi-amd64-signed \
  intel-microcode \
  thermald

echo >&2 "===]> Info: Add firmwares"
for file in skl_guc_49.0.1.bin bxt_guc_49.0.1.bin kbl_guc_49.0.1.bin glk_guc_49.0.1.bin kbl_guc_49.0.1.bin kbl_guc_49.0.1.bin cml_guc_49.0.1.bin icl_guc_49.0.1.bin ehl_guc_49.0.1.bin ehl_guc_49.0.1.bin tgl_huc_7.5.0.bin tgl_guc_49.0.1.bin tgl_huc_7.5.0.bin tgl_guc_49.0.1.bin tgl_huc_7.5.0.bin tgl_guc_49.0.1.bin dg1_dmc_ver2_02.bin
do
curl -L https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/i915/$file \
  --output /lib/firmware/i915/$file
done

if [ -d /tmp/setup_files/kernels ]; then
  echo >&2 "===]> Info: Install patched kernels... "
  dpkg -i /tmp/setup_files/kernels/*.deb
fi

echo >&2 "===]> Info: Install window manager... "

apt-get install -y -qq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
  plymouth-theme-ubuntu-logo \
  ubuntu-desktop-minimal \
  ubuntu-gnome-wallpapers \
  netplan.io \
  snapd

echo >&2 "===]> Info: Install Graphical installer... "

apt-get install -y -qq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
  ubiquity \
  ubiquity-casper \
  ubiquity-frontend-gtk \
  ubiquity-slideshow-ubuntu \
  ubiquity-ubuntu-artwork

echo >&2 "===]> Info: Install useful applications... "

apt-get install -y -qq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
  git \
  curl \
  nano \
  make \
  gcc \
  iwd

echo >&2 "===]> Info: Change initramfs format (for grub)... "
sed -i "s/COMPRESS=lz4/COMPRESS=gzip/g" "/etc/initramfs-tools/initramfs.conf"

printf '\n# display f* key in touchbar\noptions apple-ib-tb fnmode=2\n'  >> /etc/modprobe.d/apple-touchbar.conf

#if [ -d /tmp/setup_files/wifi/iso-firmware.deb ]; then
#  echo >&2 "===]> Info: Install wifi firmware... "
#  dpkg -i /tmp/setup_files/wifi/iso-firmware.deb
#fi

#echo >&2 "===]> Info: install mpbfan ... "
#git clone https://github.com/networkException/mbpfan /tmp/mbpfan
#cd /tmp/mbpfan
#make install
#cp mbpfan.service /etc/systemd/system/
#systemctl enable mbpfan.service

echo >&2 "===]> Info: Remove unused applications ... "

apt-get purge -y \
  transmission-gtk \
  transmission-common \
  gnome-mahjongg \
  gnome-mines \
  gnome-sudoku \
  aisleriot \
  hitori \
  xiterm+thai \
  vim \
  linux-generic \
  linux-headers-azure \
  '^linux-headers-5\.4\..*' \
  linux-headers-generic \
  '^linux-image-5\.4\..*' \
  linux-image-generic \
  '^linux-modules-5\.4\..*' \
  '^linux-modules-extra-5\.4\..*'

apt-get autoremove -y

echo >&2 "===]> Info: Reconfigure environment ... "

locale-gen --purge en_US.UTF-8 en_US
printf 'LANG="C.UTF-8"\nLANGUAGE="C.UTF-8"\n' >/etc/default/locale

dpkg-reconfigure -f readline resolvconf

cat <<EOF >/etc/NetworkManager/NetworkManager.conf
[main]
rc-manager=resolvconf
plugins=ifupdown,keyfile
dns=dnsmasq
[ifupdown]
managed=false
EOF
dpkg-reconfigure network-manager

echo >&2 "===]> Info: Configure Network Manager to use iwd... "
mkdir -p /etc/NetworkManager/conf.d
printf '[device]\nwifi.backend=iwd\n' > /etc/NetworkManager/conf.d/wifi_backend.conf
#systemctl enable iwd.service

echo >&2 "===]> Info: Cleanup the chroot environment... "

truncate -s 0 /etc/machine-id
rm /sbin/initctl
dpkg-divert --rename --remove /sbin/initctl
apt-get clean
rm -rf /tmp/* ~/.bash_history
rm -rf /tmp/setup_files

umount -lf /dev/pts
umount -lf /sys
umount -lf /proc

export HISTSIZE=0
