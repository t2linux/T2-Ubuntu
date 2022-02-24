#!/bin/bash

set -eu -o pipefail

KERNEL_PATCH_PATH=/tmp/kernel_patch
BINARY_INSTALL_PATH=${BINARY_INSTALL_PATH:-/usr/bin/}
UPDATE_SCRIPT_BRANCH=${UPDATE_SCRIPT_BRANCH:-master}

#if [ "$EUID" -ne 0 ]; then
#  echo >&2 "===]> Please run as root --> sudo -i; update_kernel_mbp"
#  exit
#fi

rm -rf ${KERNEL_PATCH_PATH}
mkdir -p ${KERNEL_PATCH_PATH}
cd ${KERNEL_PATCH_PATH} || exit

### Downloading update_kernel_mbp script
echo >&2 "===]> Info: Downloading update_kernel_mbp ${UPDATE_SCRIPT_BRANCH} script... ";
rm -rf /usr/local/bin/update_kernel_mbp
if [ -f "${BINARY_INSTALL_PATH}"update_kernel_mbp ]; then
  cp -rf "${BINARY_INSTALL_PATH}"update_kernel_mbp ${KERNEL_PATCH_PATH}/
  ORG_SCRIPT_SHA=$(sha256sum ${KERNEL_PATCH_PATH}/update_kernel_mbp | awk '{print $1}')
fi
curl -L https://raw.githubusercontent.com/marcosfad/mbp-ubuntu/"${UPDATE_SCRIPT_BRANCH}"/files/update_kernel_mbp.sh -o "${BINARY_INSTALL_PATH}"update_kernel_mbp
chmod +x "${BINARY_INSTALL_PATH}"update_kernel_mbp
if [ -f "${BINARY_INSTALL_PATH}"update_kernel_mbp ]; then
  NEW_SCRIPT_SHA=$(sha256sum "${BINARY_INSTALL_PATH}"update_kernel_mbp | awk '{print $1}')
  if [[ "$ORG_SCRIPT_SHA" != "$NEW_SCRIPT_SHA" ]]; then
    echo >&2 "===]> Info: update_kernel_mbp script was updated please rerun!" && exit
  else
    echo >&2 "===]> Info: update_kernel_mbp script is in the latest version proceeding..."
  fi
else
   echo >&2 "===]> Info: update_kernel_mbp script was installed..."
fi

### Download kernel packages
KERNEL_PACKAGES=()

CURRENT_KERNEL_VERSION=$(uname -r)
echo >&2 "===]> Info: Current kernel version: ${CURRENT_KERNEL_VERSION}";

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
  curl -LO  https://github.com/t2linux/T2-Ubuntu-Kernel/releases/download/v"${MBP_KERNEL_TAG}"/"${i}"
done

echo >&2 "===]> Info: Installing kernel version: ${MBP_KERNEL_TAG}";
dpkg -i ./*.deb

### Suspend fix
echo >&2 "===]> Info: Adding suspend fix... ";
curl -L https://raw.githubusercontent.com/marcosfad/mbp-ubuntu/${MBP_UBUNTU_BRANCH}/files/suspend/rmmod_tb.sh -o /lib/systemd/system-sleep/rmmod_tb.sh
chmod +x /lib/systemd/system-sleep/rmmod_tb.sh

### Grub
echo >&2 "===]> Info: Rebuilding GRUB config... ";
curl -L https://raw.githubusercontent.com/marcosfad/mbp-ubuntu/${MBP_UBUNTU_BRANCH}/files/grub/30_os-prober -o /etc/grub.d/30_os-prober
chmod 755 /etc/grub.d/30_os-prober
grub2-mkconfig -o /boot/grub2/grub.cfg

### Cleanup
echo >&2 "===]> Info: Cleaning old kernel pkgs (leaving 3 latest versions)... ";
rm -rf ${KERNEL_PATCH_PATH}
dnf autoremove -y
dnf remove -y "$(dnf repoquery --installonly --latest-limit=-3 -q)"

echo >&2 "===]> Info: Kernel update to ${MBP_KERNEL_TAG} finished successfully! ";
