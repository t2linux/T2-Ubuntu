#!/bin/bash
set -eu -o pipefail

echo >&2 "===]> Info: Checkout bootstrap... "
debootstrap \
  --arch=amd64 \
  --variant=minbase \
  focal \
  "${CHROOT_PATH}" \
  http://archive.ubuntu.com/ubuntu/

echo >&2 "===]> Info: Creating chroot environment... "
mount --bind /dev "${CHROOT_PATH}/dev"
mount --bind /run "${CHROOT_PATH}/run"

cp -r "${ROOT_PATH}/files" "${CHROOT_PATH}/tmp/setup_files"
chroot "${CHROOT_PATH}" /bin/bash -c "/tmp/setup_files/chroot_build.sh"

echo >&2 "===]> Info: Cleanup the chroot environment... "
# In docker there is no run?
#umount "${CHROOT_PATH}/run"
umount "${CHROOT_PATH}/dev"

### Add update_kernel_mbp script
echo >&2 "===]> Info: Add update_kernel_mbp script... "
cp -r "${ROOT_PATH}/files/update_kernel_mbp.sh" /usr/bin/update_kernel_mbp
chmod +x "${CHROOT_PATH}"/usr/bin/update_kernel_mbp

### Add wifi firmware script
echo >&2 "===]> Info: Add wifi firmware... "
cp -r "${ROOT_PATH}/files/wifi/iso-firmware.deb" "${CHROOT_PATH}"/usr/src/iso-firmware.deb

### Add example to fix amdgpu power manager
echo >&2 "===]> Configure amdgpu"
cat << EOF > "${CHROOT_PATH}"/usr/src/udev_rules_d_30-amdgpu-pm.rules
KERNEL=="card0", SUBSYSTEM=="drm", DRIVERS=="amdgpu", ATTR{device/power_dpm_force_performance_level}="high"
EOF

### Copy grub config without finding macos partition
echo >&2 "===]> Info: Patch Grub... "
cp -rfv "${ROOT_PATH}"/files/grub/30_os-prober "${CHROOT_PATH}"/etc/grub.d/30_os-prober
chmod 755 "${CHROOT_PATH}"/etc/grub.d/30_os-prober

### Copy suspend fix
echo >&2 "===]> Info: Fix suspend... "
cp -rfv "${ROOT_PATH}"/files/suspend/rmmod_tb.sh "${CHROOT_PATH}"/lib/systemd/system-sleep/rmmod_tb.sh
chmod +x "${CHROOT_PATH}"/lib/systemd/system-sleep/rmmod_tb.sh
