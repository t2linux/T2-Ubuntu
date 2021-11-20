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

mkdir -p /etc/apt/sources.list.d
echo "deb https://mbp-ubuntu-kernel.herokuapp.com/ /" >/etc/apt/sources.list.d/mbp-ubuntu-kernel.list
curl -L https://mbp-ubuntu-kernel.herokuapp.com/KEY.gpg | apt-key add -
apt-get update

echo >&2 "===]> Info: Configure machine-id and divert... "

dbus-uuidgen >/etc/machine-id
ln -fs /etc/machine-id /var/lib/dbus/machine-id
dpkg-divert --local --rename --add /sbin/initctl
ln -s /bin/true /sbin/initctl

echo >&2 "===]> Info: Install packages needed for Live System... "

# todo: Install the latest kernel automatically
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
  linux-headers-5.11.22-t2-hwe-bigsur \
  linux-headers-5.11.22-t2-hwe-mojave \
  linux-headers-5.12.19-t2-a-bigsur \
  linux-headers-5.12.19-t2-a-mojave \
  linux-headers-5.13.15-t2-j-bigsur \
  linux-headers-5.13.15-t2-j-mojave \
  linux-image-5.11.22-t2-hwe-bigsur \
  linux-image-5.11.22-t2-hwe-mojave \
  linux-image-5.12.19-t2-a-bigsur \
  linux-image-5.12.19-t2-a-mojave \
  linux-image-5.13.15-t2-j-bigsur \
  linux-image-5.13.15-t2-j-mojave \
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
  dkms \
  iwd

echo >&2 "===]> Info: Change initramfs format (for grub)... "
sed -i "s/COMPRESS=lz4/COMPRESS=gzip/g" "/etc/initramfs-tools/initramfs.conf"

echo >&2 "===]> Info: Add drivers... "

APPLE_BCE_DRIVER_GIT_URL=https://github.com/t2linux/apple-bce-drv.git
APPLE_BCE_DRIVER_BRANCH_NAME=aur
APPLE_BCE_DRIVER_COMMIT_HASH=f93c6566f98b3c95677de8010f7445fa19f75091
APPLE_BCE_DRIVER_MODULE_NAME=apple-bce
APPLE_BCE_DRIVER_MODULE_VERSION=0.2

git clone --single-branch --branch ${APPLE_BCE_DRIVER_BRANCH_NAME} ${APPLE_BCE_DRIVER_GIT_URL} \
  /usr/src/"${APPLE_BCE_DRIVER_MODULE_NAME}-${APPLE_BCE_DRIVER_MODULE_VERSION}"
git -C /usr/src/"${APPLE_BCE_DRIVER_MODULE_NAME}-${APPLE_BCE_DRIVER_MODULE_VERSION}" checkout "${APPLE_BCE_DRIVER_COMMIT_HASH}"

cat << EOF > /usr/src/${APPLE_BCE_DRIVER_MODULE_NAME}-${APPLE_BCE_DRIVER_MODULE_VERSION}/dkms.conf
PACKAGE_NAME="${APPLE_BCE_DRIVER_MODULE_NAME}"
PACKAGE_VERSION="${APPLE_BCE_DRIVER_MODULE_VERSION}"
MAKE[0]="make KVERSION=\$kernelver"
CLEAN="make clean"
BUILT_MODULE_NAME[0]="${APPLE_BCE_DRIVER_MODULE_NAME}"
DEST_MODULE_LOCATION[0]="/kernel/drivers/misc"
AUTOINSTALL="yes"
EOF

while IFS= read -r kernel; do
  echo "==> Debug: Adding $kernel"
  rm -rf "/lib/modules/$kernel/build"
  ln -sf "/usr/src/linux-headers-$kernel"  "/lib/modules/$kernel/build"
  dkms --verbose install -m "${APPLE_BCE_DRIVER_MODULE_NAME}" -v "${APPLE_BCE_DRIVER_MODULE_VERSION}" -k "$kernel"
  if [ -f "/var/lib/dkms/${APPLE_BCE_DRIVER_MODULE_NAME}/${APPLE_BCE_DRIVER_MODULE_VERSION}/build/make.log" ]; then
    cat "/var/lib/dkms/${APPLE_BCE_DRIVER_MODULE_NAME}/${APPLE_BCE_DRIVER_MODULE_VERSION}/build/make.log"
  fi
done < <(dpkg -l | grep linux-image | grep t2 | grep ii | grep t2 | cut -d' ' -f3|cut -d'-' -f3-10)

printf '\n### apple-bce start ###\napple-bce\n### apple-bce end ###' >>/etc/modules-load.d/apple-bce.conf
printf '\n### apple-bce start ###\nhapple-bce\n### apple-bce end ###' >>/etc/initramfs-tools/modules

APPLE_IB_DRIVER_GIT_URL=https://github.com/t2linux/apple-ib-drv
APPLE_IB_DRIVER_BRANCH_NAME=mbp15
APPLE_IB_DRIVER_COMMIT_HASH=fc9aefa5a564e6f2f2bb0326bffb0cef0446dc05
APPLE_IB_DRIVER_MODULE_NAME=apple-ibridge
APPLE_IB_DRIVER_MODULE_VERSION=0.1

git clone --single-branch --branch ${APPLE_IB_DRIVER_BRANCH_NAME} ${APPLE_IB_DRIVER_GIT_URL} \
    /usr/src/"${APPLE_IB_DRIVER_MODULE_NAME}-${APPLE_IB_DRIVER_MODULE_VERSION}"
git -C /usr/src/"${APPLE_IB_DRIVER_MODULE_NAME}-${APPLE_IB_DRIVER_MODULE_VERSION}" checkout "${APPLE_IB_DRIVER_COMMIT_HASH}"

echo >&2 "===]> Debug: Add apple-ib-drv ... "
cat /usr/src/"${APPLE_IB_DRIVER_MODULE_NAME}-${APPLE_IB_DRIVER_MODULE_VERSION}"/dkms.conf
while IFS= read -r kernel; do
  echo "==> Debug: Adding $kernel"
  rm -rf "/lib/modules/$kernel/build"
  ln -sf "/usr/src/linux-headers-$kernel"  "/lib/modules/$kernel/build"
  dkms --verbose install -m "${APPLE_IB_DRIVER_MODULE_NAME}" -v "${APPLE_IB_DRIVER_MODULE_VERSION}" -k "$kernel"
  if [ -f "/var/lib/dkms/${APPLE_IB_DRIVER_MODULE_NAME}/${APPLE_IB_DRIVER_MODULE_VERSION}/build/make.log" ]; then
    cat "/var/lib/dkms/${APPLE_IB_DRIVER_MODULE_NAME}/${APPLE_IB_DRIVER_MODULE_VERSION}/build/make.log"
  fi
done < <(dpkg -l | grep linux-image | grep t2 | grep ii | grep t2 | cut -d' ' -f3|cut -d'-' -f3-10)


printf '\n### applespi start ###\napple_ib_tb\napple_ib_als\n### applespi end ###' >> /etc/modules-load.d/applespi.conf
printf '\n# display f* key in touchbar\noptions apple-ib-tb fnmode=2\n'  >> /etc/modprobe.d/apple-touchbar.conf

## Add optional dkms for brcm80211-mbp16x
#cd /tmp
#wget https://gist.github.com/hexchain/22932a13a892e240d71cb98fad62a6a0/archive/50ce4513d2865b1081a972bc09e8da639f94a755.zip
#unzip *55.zip
#cd 22*
#cp -r /usr/src/linux-headers-*-generic/drivers/net/wireless/broadcom/brcm80211 .
#cd brcm80211
#patch -Np6 -i "../8001-corellium-wifi-bigsur.patch"
#patch -Np6 -i "../8002-brcmfmac-4377-mod.patch"
#patch -Np6 -i "../8003-brcmfmac-4377-64bit-regs.patch"
#patch -Np6 -i "../8004-brcmfmac-4377-chip-ids.patch"
#patch -Np1 -i "../out-of-tree.patch"
#mv Makefile Kbuild
#cp ../Makefile .
#sed -e "s,@PACKAGE_NAME@,brcm80211-mbp16x," -e "s,@PACKAGE_VERSION@,2.0," ../dkms.conf.in > dkms.conf
#cp ./brcm80211 /usr/src/brcm80211-mbp16x-2.0
#cd /tmp
#rm -rf *55.zip 22*

echo >&2 "===]> Debug dkms status"
dkms status

echo >&2 "===]> Configure amdgpu"
cat << EOF > /etc/udev/rules.d/30-amdgpu-pm.rules
KERNEL=="card0", SUBSYSTEM=="drm", DRIVERS=="amdgpu", ATTR{device/power_dpm_force_performance_level}="high"
EOF

echo >&2 "===]> Info: Update initramfs... "

## Add custom drivers to be loaded at boot
for kernel in $(dpkg -l | grep linux-image | grep ii | grep t2 | cut -d' ' -f3|cut -d'-' -f3-10); do
  echo "==> Adding $kernel"
  /usr/sbin/depmod -a "$kernel"
  update-initramfs -u -v -k "$kernel"
done

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
