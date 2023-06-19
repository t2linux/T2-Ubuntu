#!/bin/bash
set -eu -o pipefail

cd "${IMAGE_PATH}"
### Generate md5sum.txt. Generate it two times, to get the own checksum right.
(find . -type f -print0 | xargs -0 md5sum >"${IMAGE_PATH}/md5sum.txt")


echo >&2 "===]> Info: Create Isolinux... "
xorriso -as mkisofs \
  -iso-level 3 \
  -full-iso9660-filenames \
  -volid "KUBUNTU_MBP" \
  -b boot/grub/bios.img \
  -no-emul-boot \
  -boot-load-size 4 \
  -boot-info-table \
  -c boot/grub/boot.cat \
  --grub2-boot-info \
  --grub2-mbr "/usr/lib/grub/i386-pc/boot_hybrid.img" \
  -eltorito-alt-boot \
  -e "EFI/efiboot.img" \
  -no-emul-boot \
  -isohybrid-mbr "${ROOT_PATH}/files/isohdpfx.bin" \
  -isohybrid-gpt-basdat -isohybrid-apm-hfsplus \
  -output "${ROOT_PATH}/Kubuntu-22.04-${KERNEL_VERSION}.iso" \
  -graft-points \
  "." \
  /boot/grub/bios.img=isolinux/bios.img \
  /EFI/efiboot.img=isolinux/efiboot.img
