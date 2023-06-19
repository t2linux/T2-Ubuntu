#!/bin/bash
set -eu -o pipefail

echo >&2 "===]> Info: Create image directory and populate it... "
cd "${WORKING_PATH}"

if [ -d "${IMAGE_PATH}" ]; then
  rm -rf "${IMAGE_PATH}"
fi

mkdir -p "${IMAGE_PATH}"/{casper,install,isolinux}
cp "${CHROOT_PATH}"/boot/vmlinuz-"${KERNEL_VERSION}" "${IMAGE_PATH}"/casper/vmlinuz
cp "${CHROOT_PATH}"/boot/initrd.img-"${KERNEL_VERSION}" "${IMAGE_PATH}"/casper/initrd

echo >&2 "===]> Info: Grub configuration... "
# we add an empty file to use it with the search command in grub later on.
touch "${IMAGE_PATH}"/ubuntu
cp -r "${ROOT_PATH}"/files/preseed "${IMAGE_PATH}"/preseed
cp "${ROOT_PATH}/files/grub/grub.cfg" "${IMAGE_PATH}"/isolinux/grub.cfg


echo >&2 "===]> Info: Compress the chroot... "
cd "${WORKING_PATH}"
mksquashfs "${CHROOT_PATH}" "${IMAGE_PATH}"/casper/filesystem.squashfs
printf "%s" "$(du -sx --block-size=1 "${CHROOT_PATH}" | cut -f1)" >"${IMAGE_PATH}"/casper/filesystem.size

echo >&2 "===]> Info: Create manifest... "
# shellcheck disable=SC2016
chroot "${CHROOT_PATH}" dpkg-query -W --showformat='${Package} ${Version}\n' |
  tee "${IMAGE_PATH}"/casper/filesystem.manifest
cp -v "${IMAGE_PATH}"/casper/filesystem.manifest "${IMAGE_PATH}"/casper/filesystem.manifest-desktop

REMOVE='ubiquity casper lupin-casper user-setup discover discover-data os-prober laptop-detect'
for i in $REMOVE; do
  sed -i "/${i}/d" "${IMAGE_PATH}"/casper/filesystem.manifest-desktop
done

echo >&2 "===]> Info: Create diskdefines... "
cat <<EOF >"${IMAGE_PATH}"/README.diskdefines
#define DISKNAME  Kubuntu MBP 22.04 LTS "Jammy Jellyfish" - Beta amd64
#define TYPE  binary
#define TYPEbinary  1
#define ARCH  amd64
#define ARCHamd64  1
#define DISKNUM  1
#define DISKNUM1  1
#define TOTALNUM  0
#define TOTALNUM0  1
EOF
