#!/bin/bash
set -eu -o pipefail

ROOT_PATH=$(pwd)
WORKING_PATH=/root/work
CHROOT_PATH="${WORKING_PATH}/chroot"
IMAGE_PATH="${WORKING_PATH}/image"
#KERNEL_VERSION=5.4.0-29-generic
KERNEL_VERSION=5.6.14-mbp

if [ -d "$WORKING_PATH" ]; then
  rm -rf "$WORKING_PATH"
fi
mkdir -p "$WORKING_PATH"

echo >&2 "===]> Info: Build dependencies... "
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y -qq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
  binutils \
  debootstrap \
  squashfs-tools \
  xorriso \
  grub-pc-bin \
  grub-efi-amd64-bin \
  mtools \
  dosfstools \
  zip \
  isolinux \
  syslinux

echo >&2 "===]> Info: Build Ubuntu FS... "
/bin/bash -c "
  ROOT_PATH=${ROOT_PATH} \\
  WORKING_PATH=${WORKING_PATH} \\
  CHROOT_PATH=${CHROOT_PATH} \\
  IMAGE_PATH=${IMAGE_PATH} \\
  KERNEL_VERSION=${KERNEL_VERSION} \\
  ${ROOT_PATH}/build_file_system.sh
"

echo >&2 "===]> Info: Build Image FS... "
/bin/bash -c "
  ROOT_PATH=${ROOT_PATH} \\
  WORKING_PATH=${WORKING_PATH} \\
  CHROOT_PATH=${CHROOT_PATH} \\
  IMAGE_PATH=${IMAGE_PATH} \\
  KERNEL_VERSION=${KERNEL_VERSION} \\
  ${ROOT_PATH}/build_image.sh
"

echo >&2 "===]> Info: Prepare Boot for ISO... "
/bin/bash -c "
  IMAGE_PATH=${IMAGE_PATH} \\
  CHROOT_PATH=${CHROOT_PATH} \\
  ${ROOT_PATH}/prepare_iso.sh
"

echo >&2 "===]> Info: Create ISO... "
/bin/bash -c "
  ROOT_PATH=${ROOT_PATH} \\
  IMAGE_PATH=${IMAGE_PATH} \\
  CHROOT_PATH=${CHROOT_PATH} \\
  KERNEL_VERSION=${KERNEL_VERSION} \\
  ${ROOT_PATH}/create_iso.sh
"
livecd_exitcode=$?

### Zip iso and split it into multiple parts - github max size of release attachment is 2GB, where ISO is sometimes bigger than that
cd "${ROOT_PATH}"
if [ -d "${ROOT_PATH}/output" ]; then
  rm -rf "${ROOT_PATH}/output"
fi
mkdir -p "${ROOT_PATH}/output"
zip -s 1500m "${ROOT_PATH}/output/livecd.zip" ./*.iso

### Calculate sha256 sums of built ISO
sha256sum "${ROOT_PATH}"/*.iso >"${ROOT_PATH}/output/sha256"

find ./ | grep ".iso"
find ./ | grep ".zip"

exit "$livecd_exitcode"
