#!/bin/bash

set -eu -o pipefail

echo >&2 "===]> Info: Configure and update apt... "

apt update
apt install -y curl
# Add T2 Repository and Install Packages
CODENAME=$(lsb_release -cs)
curl -s --compressed "https://adityagarg8.github.io/t2-ubuntu-repo/KEY.gpg" | gpg --dearmor | tee /etc/apt/trusted.gpg.d/t2-ubuntu-repo.gpg >/dev/null
curl -s --compressed -o /etc/apt/sources.list.d/t2.list "https://adityagarg8.github.io/t2-ubuntu-repo/t2.list"
echo "deb [signed-by=/etc/apt/trusted.gpg.d/t2-ubuntu-repo.gpg] https://github.com/AdityaGarg8/t2-ubuntu-repo/releases/download/${CODENAME} ./" | tee -a /etc/apt/sources.list.d/t2.list

apt update

echo >&2 "===]> Info: Update grub... "
# Add Kernel Parameters to GRUB for Installed System
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash intel_iommu=on iommu=pt pm_async=off"/' /etc/default/grub
update-grub

echo >&2 "===]> Info: Install audio and wifi firmware script... "
apt install -y apple-t2-audio-config apple-firmware-script

echo >&2 "===]> Info: Install the T2 kernel... "
if [ "$SUBIQUITY" = "yes" ]; then
# Create a fake linux-t2 package with version 0.1 that ships dkms modules instead of the kernel
apt install -y git

conf=$RANDOM
mkdir t2
cd t2
mkdir ./DEBIAN
mkdir -p ./etc/modprobe.d/
mkdir -p ./usr/src

cat <<EOF > ./etc/modprobe.d/${conf}.conf
install usbhid /sbin/modprobe bcm5974; /sbin/modprobe --ignore-install usbhid
EOF

cat <<EOF > ./DEBIAN/control
Package: linux-t2
Version: 0.1
Maintainer: Aditya Garg
Architecture: amd64
Description: Kernel to support T2 Macs
Depends: dkms
EOF

cat <<EOF > ./DEBIAN/postinst
dkms add -m apple-bce -v 0.2
dkms build -m apple-bce -v 0.2 && dkms install -m apple-bce -v 0.2 --force || true
dkms add -m bcm5974-t2 -v 0.1
dkms build -m bcm5974-t2 -v 0.1 && dkms install -m bcm5974-t2 -v 0.1 --force || true
dkms add -m applesmc-t2 -v 0.1
dkms build -m applesmc-t2 -v 0.1 && dkms install -m applesmc-t2 -v 0.1 --force || true
dkms add -m linux-apfs-rw -v 0.1
dkms build -m linux-apfs-rw -v 0.1 && dkms install -m linux-apfs-rw -v 0.1 --force || true
EOF
chmod a+x ./DEBIAN/postinst

cat <<EOF > ./DEBIAN/prerm
dkms remove -m apple-bce -v 0.2 --all || true
dkms remove -m bcm5974-t2 -v 0.1 --all || true
dkms remove -m applesmc-t2 -v 0.1 --all || true
dkms remove -m linux-apfs-rw -v 0.1 --all || true
EOF
chmod a+x ./DEBIAN/prerm

cd ./usr/src

git clone --depth 1 https://github.com/t2linux/apple-bce-drv.git ./apple-bce-0.2
cat << 'EOF' > ./apple-bce-0.2/dkms.conf
PACKAGE_NAME="apple-bce"
PACKAGE_VERSION="0.2"
MAKE[0]="make KVERSION=$kernelver"
CLEAN="make clean"
BUILT_MODULE_NAME[0]="apple-bce"
DEST_MODULE_LOCATION[0]="/kernel/drivers/misc"
AUTOINSTALL="yes"
EOF

git clone --depth 1 https://github.com/AdityaGarg8/bcm5974-t2.git ./bcm5974-t2-0.1

git clone --depth 1 https://github.com/AdityaGarg8/applesmc-t2 ./applesmc-t2-0.1

git clone --depth 1 https://github.com/linux-apfs/linux-apfs-rw.git ./linux-apfs-rw-0.1
sed -i 's/PACKAGE_VERSION=.*/PACKAGE_VERSION="0.1"/g' ./linux-apfs-rw-0.1/dkms.conf

cd ..
cd ..
cd ..
dpkg-deb --build --root-owner-group t2

rm -rf t2
apt install -y ./t2.deb
rm ./t2.deb

KVER=$(ls /boot | grep generic | grep vmlinuz | cut -d '-' -f 2-)
dkms install -m apple-bce -v 0.2 -k ${KVER} --force || true
dkms install -m bcm5974-t2 -v 0.1 -k ${KVER} --force || true
dkms install -m applesmc-t2 -v 0.1 -k ${KVER} --force || true
dkms install -m linux-apfs-rw -v 0.1 -k ${KVER} --force || true
else
apt install -y linux-t2=${KERNEL_VERSION}-${PKGREL}-${CODENAME}
fi

echo >&2 "===]> Info: Add udev Rule to stop annoying WiFi popup... "
mkdir -p /etc/NetworkManager/conf.d
cat <<EOF | tee /etc/udev/rules.d/99-network-t2-ncm.rules
SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="ac:de:48:00:11:22", NAME="t2_ncm"
EOF

cat <<EOF | tee /etc/NetworkManager/conf.d/99-network-t2-ncm.conf
[main]
no-auto-default=t2_ncm
EOF

echo >&2 "===]> Info: Add udev Rule for AMD GPU Power Management... "
cat <<EOF > /etc/udev/rules.d/30-amdgpu-pm.rules
KERNEL=="card[012]", SUBSYSTEM=="drm", DRIVERS=="amdgpu", ATTR{device/power_dpm_force_performance_level}="low"
EOF

echo >&2 "===]> Info: Setup auto-fetch firmware service... "

curl -s https://raw.githubusercontent.com/t2linux/wiki/refs/heads/master/docs/tools/get-apple-firmware.service -o /etc/systemd/system/get-apple-firmware.service

systemctl enable get-apple-firmware.service

KERNEL_VERSION=$(dpkg -l | grep -E "^ii  linux-image-[0-9]+\.[0-9]+\.[0-9\.\-]+-generic" | awk '{print $2}' | sed 's/linux-image-\(.*\)-generic/\1/')
#apt purge -y -qq \
#    linux-generic \
#    linux-headers-${KERNEL_VERSION} \
#    linux-headers-${KERNEL_VERSION}-generic \
#    linux-headers-generic \
#    linux-image-${KERNEL_VERSION}-generic \
#    linux-image-generic \
#    linux-modules-${KERNEL_VERSION}-generic \
#    linux-modules-extra-${KERNEL_VERSION}-generic

# Clean up
#apt-get autoremove -y
apt clean
rm -rf /var/cache/apt/archives/*
rm -rf /tmp/* ~/.bash_history
rm -rf /tmp/setup_files




