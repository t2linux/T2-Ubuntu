#!/bin/bash

# https://itnext.io/how-to-create-a-custom-ubuntu-live-from-scratch-dd3b3f213f81

set -eu -o pipefail

ROOT_PATH=$(pwd)
WORKING_PATH=$(pwd)/build_files

echo >&2 "===]> Info: Build dependencies... ";
export DEBIAN_FRONTEND=noninteractive

apt-get install -y -qq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
    binutils \
    debootstrap \
    squashfs-tools \
    xorriso \
    grub-pc-bin \
    grub-efi-amd64-bin \
    mtools

if [ -d "$WORKING_PATH" ]; then
   rm -rf "$WORKING_PATH"
fi
mkdir -p "$WORKING_PATH"

echo >&2 "===]> Info: Checkout bootstrap... ";
debootstrap \
    --arch=amd64 \
    --variant=minbase \
    focal \
    "$WORKING_PATH/chroot" \
    http://de.archive.ubuntu.com/ubuntu/


echo >&2 "===]> Info: Creating chroot environment... ";
mount --bind /dev "$WORKING_PATH/chroot/dev"
mount --bind /run "$WORKING_PATH/chroot/run"

cp "$ROOT_PATH/files/chroot_build.sh" "$WORKING_PATH/chroot/chroot_build.sh"
chroot "$WORKING_PATH/chroot" ./chroot_build.sh


echo >&2 "===]> Info: Cleanup the chroot environment... ";
umount "$WORKING_PATH/chroot/dev"
umount "$WORKING_PATH/chroot/run"


echo >&2 "===]> Info: Create image directory and populate it... ";
cd "$WORKING_PATH"
if [ -d "$WORKING_PATH/image" ]; then
  rm -rf "$WORKING_PATH/image"
fi
if [ -e "$WORKING_PATH/ubuntu-for-mbp.iso" ]; then
   rm -f "$WORKING_PATH/ubuntu-for-mbp.iso"
fi
mkdir -p image/{casper,isolinux,install}
cp chroot/boot/vmlinuz-**-**-generic image/casper/vmlinuz
cp chroot/boot/initrd.img-**-**-generic image/casper/initrd

cp -r "$ROOT_PATH/files/preseed" image/


echo >&2 "===]> Info: Create manifest... ";
cd "$WORKING_PATH"
# shellcheck disable=SC2016
chroot chroot dpkg-query -W --showformat='${Package} ${Version}\n' | tee image/casper/filesystem.manifest

cp -v image/casper/filesystem.manifest image/casper/filesystem.manifest-desktop
sed -i '/ubiquity/d' image/casper/filesystem.manifest-desktop
sed -i '/casper/d' image/casper/filesystem.manifest-desktop
sed -i '/discover/d' image/casper/filesystem.manifest-desktop
sed -i '/laptop-detect/d' image/casper/filesystem.manifest-desktop
sed -i '/os-prober/d' image/casper/filesystem.manifest-desktop


### Workaround - travis_wait
while true
do
  date
  sleep 30
done &
bgPID=$!

echo >&2 "===]> Info: Compress the chroot... ";
cd "$WORKING_PATH"
mksquashfs chroot image/casper/filesystem.squashfs
printf "%s" "$(du -sx --block-size=1 chroot | cut -f1)" > image/casper/filesystem.size


echo >&2 "===]> Info: Create diskdefines... ";
cat <<EOF > image/README.diskdefines
#define DISKNAME  Ubuntu 20.04 LTS "Focal Fossa" - MacBook Pro Beta amd64
#define TYPE  binary
#define TYPEbinary  1
#define ARCH  amd64
#define ARCHamd64  1
#define DISKNUM  1
#define DISKNUM1  1
#define TOTALNUM  0
#define TOTALNUM0  1
EOF


echo >&2 "===]> Info: Grub configuration... ";
touch image/ubuntu
cp "$ROOT_PATH/files/grub/grub.cfg" image/isolinux/grub.cfg
cp -r "$ROOT_PATH/files/preseed" image/pressed

echo >&2 "===]> Info: Create ISO Image for a LiveCD... ";
cd "$WORKING_PATH/image"

grub-mkstandalone \
   --format=x86_64-efi \
   --output=isolinux/bootx64.efi \
   --locales="" \
   --fonts="" \
   "boot/grub/grub.cfg=isolinux/grub.cfg"

(
   cd isolinux && \
   dd if=/dev/zero of=efiboot.img bs=1M count=10 && \
   sudo mkfs.vfat efiboot.img && \
   LC_CTYPE=C mmd -i efiboot.img efi efi/boot && \
   LC_CTYPE=C mcopy -i efiboot.img ./bootx64.efi ::efi/boot/
)

grub-mkstandalone \
   --format=i386-pc \
   --output=isolinux/core.img \
   --install-modules="linux16 linux normal iso9660 biosdisk memdisk search tar ls" \
   --modules="linux16 linux normal iso9660 biosdisk search" \
   --locales="" \
   --fonts="" \
   "boot/grub/grub.cfg=isolinux/grub.cfg"

cat /usr/lib/grub/i386-pc/cdboot.img isolinux/core.img > isolinux/bios.img

(find . -type f -print0 | xargs -0 md5sum | grep -v "\./md5sum.txt" > md5sum.txt)

xorriso \
   -as mkisofs \
   -iso-level 3 \
   -full-iso9660-filenames \
   -volid "Ubuntu 20.04 beta minimal MacBook Pro" \
   -eltorito-boot boot/grub/bios.img \
   -no-emul-boot \
   -boot-load-size 4 \
   -boot-info-table \
   --eltorito-catalog boot/grub/boot.cat \
   --grub2-boot-info \
   --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
   -eltorito-alt-boot \
   -e EFI/efiboot.img \
   -no-emul-boot \
   -append_partition 2 0xef isolinux/efiboot.img \
   -output "../ubuntu-20.04-beta-minimal-mbp.iso" \
   -graft-points \
      "." \
      /boot/grub/bios.img=isolinux/bios.img \
      /EFI/efiboot.img=isolinux/efiboot.img
livecd_exitcode=$?

### Zip iso and split it into multiple parts - github max size of release attachment is 2GB, where ISO is sometimes bigger than that
cd "$WORKING_PATH"
mkdir -p ./output_zip
zip -s 1500m ./output_zip/livecd.zip ./*.iso

### Calculate sha256 sums of built ISO
sha256sum ./*.iso > ./output_zip/sha256

find ./ | grep ".iso"
find ./ | grep ".zip"
kill "$bgPID"

exit "$livecd_exitcode"
