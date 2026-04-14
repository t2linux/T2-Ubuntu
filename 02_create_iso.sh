#!/bin/bash

set -eu -o pipefail
echo >&2 "===]> Info: Getting Kernel version ... "
echo $T2_KERNEL

if [ "$SUBIQUITY" = "no" ]; then
    echo >&2 "===]> Info: Copying Linux vmlinuz and initrd ... "
    cp "$CHROOT_DIR/boot/vmlinuz-$T2_KERNEL" "$ISO_WORK_DIR/casper/vmlinuz"
    cp "$CHROOT_DIR/boot/initrd.img-$T2_KERNEL" "$ISO_WORK_DIR/casper/initrd"
fi

# Update GRUB Configuration in ISO
echo >&2 "===]> Info: Modify existing grub.cfg ..."
if [ "$SUBIQUITY" = "yes" ]; then
    sed -i 's/--- quiet splash/--- quiet splash intel_iommu=on iommu=pt pm_async=off/g' "$ISO_WORK_DIR/boot/grub/grub.cfg"
else
    sed -i 's/--- quiet splash/boot=casper quiet splash intel_iommu=on iommu=pt pm_async=off ---/g' "$ISO_WORK_DIR/boot/grub/grub.cfg"
fi

echo >&2 "===]> Info: Creating EFI image ... "
dd if=/dev/zero of="$ISO_WORK_DIR/EFI/efiboot.img" bs=1M count=10
mkfs.vfat "$ISO_WORK_DIR/EFI/efiboot.img"

mkdir -p /mnt/efiboot
mount "$ISO_WORK_DIR/EFI/efiboot.img" /mnt/efiboot
# Create the EFI/boot directory
mkdir -p /mnt/efiboot/EFI/boot
cp "$ISO_WORK_DIR/EFI/boot/grubx64.efi" /mnt/efiboot/EFI/boot/bootx64.efi
# Clean up EFI temp folders
umount /mnt/efiboot
rmdir /mnt/efiboot
echo >&2 "===]> Info: Generating final ISO ... "
(cd "$ISO_WORK_DIR" && find . -type f -print0 | xargs -0 md5sum > md5sum.txt)

# Ensure the output directory exists
mkdir -p "$(dirname "$ISO_IMAGE_OUTPUT")"

xorriso -as mkisofs \
  -iso-level 3 \
  -full-iso9660-filenames \
  -volid "T2-$(echo ${FLAVOUR} | tr '[a-z]' '[A-Z]')" \
  -eltorito-boot boot/grub/i386-pc/eltorito.img \
  -no-emul-boot \
  -boot-load-size 4 \
  -boot-info-table \
  -eltorito-alt-boot \
  -eltorito-platform efi \
  -eltorito-boot EFI/efiboot.img \
  -no-emul-boot \
  -isohybrid-gpt-basdat \
  -isohybrid-apm-hfsplus \
  -output ${ISO_IMAGE_OUTPUT} \
  ${ISO_WORK_DIR}

echo >&2 "===]> Info: Custom ISO creation process complete. Find the ISO at ${ISO_IMAGE_OUTPUT} ..."


