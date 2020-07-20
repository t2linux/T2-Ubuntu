#!/bin/bash
set -eu -o pipefail

echo >&2 "===]> Info: Create ISO Image for a LiveCD... "
cd "${IMAGE_PATH}"

### Create a grub UEFI image
grub-mkstandalone \
  --format=x86_64-efi \
  --output=isolinux/BOOTx64.EFI \
  --locales="" \
  --fonts="" \
  "boot/grub/grub.cfg=isolinux/grub.cfg"

### Create a FAT16 UEFI boot disk image containing the EFI bootloader
(
  cd isolinux &&
    dd if=/dev/zero of=efiboot.img bs=1M count=10 &&
    mkfs.vfat efiboot.img &&
    LC_CTYPE=C mmd -i efiboot.img EFI EFI/BOOT &&
    LC_CTYPE=C mcopy -i efiboot.img ./BOOTx64.EFI ::EFI/BOOT/
)

### Create a grub BIOS image
grub-mkstandalone \
  --format=i386-pc \
  --output=isolinux/core.img \
  --install-modules="linux16 linux normal iso9660 biosdisk memdisk search tar ls" \
  --modules="linux16 linux normal iso9660 biosdisk search" \
  --locales="" \
  --fonts="" \
  "boot/grub/grub.cfg=isolinux/grub.cfg"

### Combine a bootable grub cdboot.img
cat "/usr/lib/grub/i386-pc/cdboot.img" "${IMAGE_PATH}/isolinux/core.img" \
  >"${IMAGE_PATH}/isolinux/bios.img"
