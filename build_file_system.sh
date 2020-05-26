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
chroot "${CHROOT_PATH}" /bin/bash -c "KERNEL_VERSION=${KERNEL_VERSION} /tmp/setup_files/chroot_build.sh"

echo >&2 "===]> Info: Cleanup the chroot environment... "
# In docker there is no run?
#umount "${CHROOT_PATH}/run"
umount "${CHROOT_PATH}/dev"


## Copy audio config files
#echo >&2 "===]> Info: Copy audio config files... "
#mkdir -p "${CHROOT_PATH}"/usr/share/alsa/cards/
#cp -fv "${ROOT_PATH}"/files/audio/AppleT2.conf "${CHROOT_PATH}"/usr/share/alsa/cards/AppleT2.conf
#cp -fv "${ROOT_PATH}"/files/audio/apple-t2.conf "${CHROOT_PATH}"/usr/share/pulseaudio/alsa-mixer/profile-sets/apple-t2.conf
#cp -fv "${ROOT_PATH}"/files/audio/91-pulseaudio-custom.rules "${CHROOT_PATH}"/usr/lib/udev/rules.d/91-pulseaudio-custom.rules
#printf "\n load-module module-combine-sink channels=6 channel_map=front-left,front-right,rear-left,rear-right,front-center,lfe" >> /etc/pulse/default.pa
#printf "\ndefault-sample-channels = 6\nremixing-produce-lfe = yes\nremixing-consume-lfe = yes" >> /etc/pulse/daemon.conf

### Copy grub config without finding macos partition
echo >&2 "===]> Info: Patch Grub... "
cp -rfv "${ROOT_PATH}"/files/grub/30_os-prober "${CHROOT_PATH}"/etc/grub.d/30_os-prober
chmod 755 "${CHROOT_PATH}"/etc/grub.d/30_os-prober

### Copy suspend fix
echo >&2 "===]> Info: Fix suspend... "
cp -rfv "${ROOT_PATH}"/files/suspend/rmmod_tb.sh "${CHROOT_PATH}"/lib/systemd/system-sleep/rmmod_tb.sh
chmod +x "${CHROOT_PATH}"/lib/systemd/system-sleep/rmmod_tb.sh
