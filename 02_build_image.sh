#!/bin/bash
set -eu -o pipefail

echo >&2 "===]> Info: Create image directory and populate it... "
cd "${WORKING_PATH}"

if [ -d "${IMAGE_PATH}" ]; then
  rm -rf "${IMAGE_PATH}"
fi

mkdir -p "${IMAGE_PATH}"/{casper,install,isolinux}

echo >&2 "===]> Info: Grub configuration... "
# we add an empty file to use it with the search command in grub later on.
touch "${IMAGE_PATH}"/ubuntu
cp -r "${ROOT_PATH}"/files/preseed "${IMAGE_PATH}"/preseed

cat <<EOF > "${IMAGE_PATH}"/isolinux/grub.cfg
search --set=root --file /ubuntu
insmod all_video
EOF

find "${CHROOT_PATH}"/boot -maxdepth 1 -type f -name 'vmlinuz-*'
find "${CHROOT_PATH}"/boot -maxdepth 1 -type f -name 'initrd*'

for file in $(find "${CHROOT_PATH}"/boot -maxdepth 1 -type f -name 'vmlinuz-*' | grep t2 | cut -d'/' -f 6 | cut -d'-' -f2-10 | sort); do
  echo "==> Adding $file"
  cp "${CHROOT_PATH}/boot/vmlinuz-${file}" "${IMAGE_PATH}/casper/vmlinuz-${file}"
  cp "${CHROOT_PATH}/boot/initrd.img-${file}" "${IMAGE_PATH}/casper/initrd-${file}"
  cat <<EOF >> "${IMAGE_PATH}"/isolinux/grub.cfg
submenu "Ubuntu, with Linux $file" {

  menuentry "Try Ubuntu FS without installing" {
     linux /casper/vmlinuz-$file file=/cdrom/preseed/mbp.seed boot=casper ro efi=noruntime pcie_ports=compat ---
     initrd /casper/initrd-$file
  }
  menuentry "Try Ubuntu FS without installing (blacklist=thunderbolt)" {
     linux /casper/vmlinuz-$file file=/cdrom/preseed/mbp.seed boot=casper ro efi=noruntime pcie_ports=compat --- modprobe.blacklist=thunderbolt
     initrd /casper/initrd-$file
  }
  menuentry "Install Ubuntu FS" {
     linux /casper/vmlinuz-$file preseed/file=/cdrom/preseed/mbp.seed boot=casper only-ubiquity efi=noruntime pcie_ports=compat ---
     initrd /casper/initrd-$file
  }
  menuentry "Install Ubuntu FS (blacklist=thunderbolt)" {
     linux /casper/vmlinuz-$file preseed/file=/cdrom/preseed/mbp.seed boot=casper only-ubiquity efi=noruntime pcie_ports=compat --- modprobe.blacklist=thunderbolt
     initrd /casper/initrd-$file
  }
  menuentry "Check disc for defects" {
     linux /casper/vmlinuz-$file boot=casper integrity-check efi=noruntime enforcing=0 efi=noruntime pcie_ports=compat ---
     initrd /casper/initrd-$file
  }
  menuentry "Check disc for defects (blacklist=thunderbolt)" {
     linux /casper/vmlinuz-$file boot=casper integrity-check efi=noruntime enforcing=0 efi=noruntime pcie_ports=compat --- modprobe.blacklist=thunderbolt
     initrd /casper/initrd-$file
  }
}
EOF
done

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
#define DISKNAME  Ubuntu MBP 20.04 LTS "Focal Fossa" - Beta amd64
#define TYPE  binary
#define TYPEbinary  1
#define ARCH  amd64
#define ARCHamd64  1
#define DISKNUM  1
#define DISKNUM1  1
#define TOTALNUM  0
#define TOTALNUM0  1
EOF
