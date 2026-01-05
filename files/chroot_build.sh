#!/bin/bash

set -eu -o pipefail

CODENAME=noble

echo >&2 "===]> Info: Configure environment... "

mount none -t proc /proc
mount none -t sysfs /sys
mount none -t devpts /dev/pts

export HOME=/root
export LC_ALL=C

echo "ubuntu-${CODENAME}-live" >/etc/hostname

echo >&2 "===]> Info: Configure and update apt... "

cat <<EOF >/etc/apt/sources.list
deb http://archive.ubuntu.com/ubuntu/ ${CODENAME} main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ ${CODENAME} main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ ${CODENAME}-security main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ ${CODENAME}-security main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ ${CODENAME}-updates main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ ${CODENAME}-updates main restricted universe multiverse
EOF
apt-get update

echo >&2 "===]> Info: Install systemd and Ubuntu MBP Repo... "

apt-get install -y systemd-sysv gnupg curl wget

mkdir -p /etc/apt/sources.list.d
curl -s --compressed "https://adityagarg8.github.io/t2-ubuntu-repo/KEY.gpg" | gpg --dearmor | tee /etc/apt/trusted.gpg.d/t2-ubuntu-repo.gpg >/dev/null
curl -s --compressed -o /etc/apt/sources.list.d/t2.list "https://adityagarg8.github.io/t2-ubuntu-repo/t2.list"
echo "deb [signed-by=/etc/apt/trusted.gpg.d/t2-ubuntu-repo.gpg] https://github.com/AdityaGarg8/t2-ubuntu-repo/releases/download/${CODENAME} ./" | tee -a /etc/apt/sources.list.d/t2.list
apt-get update

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
  discover \
  laptop-detect \
  os-prober \
  network-manager \
  resolvconf \
  net-tools \
  wireless-tools \
  locales \
  initramfs-tools \
  binutils \
  linux-generic \
  linux-headers-generic \
  grub-efi-amd64-signed \
  intel-microcode \
  thermald \
  grub2 \
  nautilus-admin

#curl -L https://github.com/t2linux/T2-Ubuntu-Kernel/releases/download/vKVER-PREL/linux-headers-KVER-${ALTERNATIVE}_KVER-PREL_amd64.deb > /tmp/headers.deb
#curl -L https://github.com/t2linux/T2-Ubuntu-Kernel/releases/download/vKVER-PREL/linux-image-KVER-${ALTERNATIVE}_KVER-PREL_amd64.deb > /tmp/image.deb
#file /tmp/*
#apt install /tmp/headers.deb /tmp/image.deb

echo >&2 "===]> Info: Install the T2 kernel... "

apt-get install -y -qq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
  linux-t2=KVER-PREL-${CODENAME}

echo >&2 "===]> Info: Install window manager... "

apt-get install -y -qq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
  plymouth-theme-spinner \
  plymouth-theme-ubuntu-text \
  ubuntu-desktop-minimal \
  ubuntu-gnome-wallpapers \
  snapd

echo >&2 "===]> Info: Install Graphical installer... "

apt-get install -y -qq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
  ubiquity \
  ubiquity-casper \
  ubiquity-frontend-gtk \
  ubiquity-slideshow-ubuntu \
  ubiquity-ubuntu-artwork

echo >&2 "===]> Info: Install useful applications and sound configuration... "

apt-get install -y -qq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
  git \
  curl \
  nano \
  make \
  gcc \
  dkms \
  gdisk \
  apple-t2-audio-config \
  apple-firmware-script

echo >&2 "===]> Info: Change initramfs format (for grub)... "
sed -i "s/COMPRESS=lz4/COMPRESS=gzip/g" "/etc/initramfs-tools/initramfs.conf"

echo >&2 "===]> Info: Configure drivers... "

# thunderbolt is working for me.
#printf '\nblacklist thunderbolt' >>/etc/modprobe.d/blacklist.conf

printf 'apple-bce' >>/etc/modules-load.d/t2.conf
#printf '\n### apple-bce start ###\nsnd\nsnd_pcm\napple-bce\n### apple-bce end ###' >>/etc/initramfs-tools/modules
#printf '\n# display f* key in touchbar\noptions apple-ib-tb fnmode=1\n'  >> /etc/modprobe.d/apple-tb.conf
#printf '\n# delay loading of the touchbar driver\ninstall apple-ib-tb /bin/sleep 7; /sbin/modprobe --ignore-install apple-ib-tb' >> /etc/modprobe.d/delay-tb.conf

echo >&2 "===]> Info: Setup auto-fetch firmware service... "

cat <<'EOF' >/etc/systemd/system/get-apple-firmware.service
[Unit]
Description=Get Apple WiFi and Bluetooth firmware
ConditionPathExists=!/etc/get_apple_firmware_attempted
ConditionPathExists=/lib/firmware/brcm

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=-/usr/libexec/get-apple-firmware -i get_from_macos
ExecStart=touch /etc/get_apple_firmware_attempted

[Install]
WantedBy=multi-user.target
EOF

systemctl enable get-apple-firmware.service

echo >&2 "===]> Info: Update initramfs... "

## Add custom drivers to be loaded at boot
/usr/sbin/depmod -a "${KERNEL_VERSION}"
update-initramfs -u -v -k "${KERNEL_VERSION}"

echo >&2 "===]> Info: Remove unused applications ... "

apt-get purge -y -qq \
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
  linux-headers-6.8.0-31 \
  linux-headers-6.8.0-31-generic \
  linux-headers-generic \
  linux-image-6.8.0-31-generic \
  linux-image-generic \
  linux-modules-6.8.0-31-generic \
  linux-modules-extra-6.8.0-31-generic \

apt-get autoremove -y

echo >&2 "===]> Info: Reconfigure environment ... "

locale-gen --purge en_US.UTF-8 en_US
printf 'LANG="C.UTF-8"\nLANGUAGE="C.UTF-8"\n' >/etc/default/locale

cat <<EOF >/etc/NetworkManager/NetworkManager.conf
[main]
plugins=ifupdown,keyfile

[ifupdown]
managed=false

[device]
wifi.scan-rand-mac-address=no
EOF
dpkg-reconfigure network-manager

echo >&2 "===]> Info: Add udev Rule to stop annoying WiFi popup... "
mkdir -p /etc/NetworkManager/conf.d
cat <<EOF | sudo tee /etc/udev/rules.d/99-network-t2-ncm.rules
SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="ac:de:48:00:11:22", NAME="t2_ncm"
EOF

cat <<EOF | sudo tee /etc/NetworkManager/conf.d/99-network-t2-ncm.conf
[main]
no-auto-default=t2_ncm
EOF

echo >&2 "===]> Info: Add udev Rule for AMD GPU Power Management... "
cat <<EOF > /etc/udev/rules.d/30-amdgpu-pm.rules
KERNEL=="card[012]", SUBSYSTEM=="drm", DRIVERS=="amdgpu", ATTR{device/power_dpm_force_performance_level}="low"
EOF

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
