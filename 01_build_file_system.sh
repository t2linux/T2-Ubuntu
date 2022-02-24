#!/bin/bash
set -eu -o pipefail

echo >&2 "===]> Info: Checkout bootstrap... "
debootstrap \
  --arch=amd64 \
  --variant=minbase \
  focal \
  "${CHROOT_PATH}" \
  http://archive.ubuntu.com/ubuntu/

### Download kernel packages
KERNEL_PACKAGES=()
if [[ -n "${KERNEL_VERSION:-}" ]]; then
  MBP_KERNEL_TAG=${KERNEL_VERSION}
  echo >&2 "===]> Info: Downloading specified kernel: ${MBP_KERNEL_TAG}";
else
  MBP_VERSION=t2
  MBP_KERNEL_TAG=$(curl -Ls https://github.com/t2linux/T2-Ubuntu-Kernel/releases/ | grep deb | grep download | grep "${MBP_VERSION}" | cut -d'/' -f6 | head -n1 | cut -d'v' -f2)
  echo >&2 "===]> Info: Downloading latest ${MBP_VERSION} kernel: ${MBP_KERNEL_TAG}";
fi

while IFS='' read -r line; do KERNEL_PACKAGES+=("$line"); done <  <(curl -sL https://github.com/t2linux/T2-Ubuntu-Kernel/releases/tag/v"${MBP_KERNEL_TAG}" | grep deb | grep span | cut -d'>' -f2 | cut -d'<' -f1)

for i in "${KERNEL_PACKAGES[@]}"; do
  curl -L  https://github.com/t2linux/T2-Ubuntu-Kernel/releases/download/v"${MBP_KERNEL_TAG}"/"${i}" -o "${ROOT_PATH}/files/kernels"
done

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
curl -L https://raw.githubusercontent.com/marcosfad/mbp-ubuntu/master/update_kernel_mbp.sh -o /usr/bin/update_kernel_mbp
chmod +x /usr/bin/update_kernel_mbp

### Copy grub config without finding macos partition
echo >&2 "===]> Info: Patch Grub... "
cp -rfv "${ROOT_PATH}"/files/grub/30_os-prober "${CHROOT_PATH}"/etc/grub.d/30_os-prober
chmod 755 "${CHROOT_PATH}"/etc/grub.d/30_os-prober

### Copy suspend fix
echo >&2 "===]> Info: Fix suspend... "
cp -rfv "${ROOT_PATH}"/files/suspend/rmmod_tb.sh "${CHROOT_PATH}"/lib/systemd/system-sleep/rmmod_tb.sh
chmod +x "${CHROOT_PATH}"/lib/systemd/system-sleep/rmmod_tb.sh
