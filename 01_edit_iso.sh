#!/bin/bash

set -eu -o pipefail
# Prepare the ISO Directories
mkdir -p "$ISO_MOUNT_DIR" "$ISO_WORK_DIR" "$CHROOT_DIR"
if [ "$SUBIQUITY" = "yes" ]; then
    mkdir -p "$CHROOT_DIR_EXTRA"
fi

# Mount the Original ISO and Copy Files
echo "mounting $ISO_IMAGE"
if [ ! -f "$ISO_IMAGE" ]; then
    echo "Error: ISO file $ISO_IMAGE not found."
    exit 1
fi

mount -o loop "$(pwd)/$ISO_IMAGE" "$ISO_MOUNT_DIR"

if [ "$SUBIQUITY" = "yes" ]; then
    rsync -a "$ISO_MOUNT_DIR/" "$ISO_WORK_DIR" --include="casper/initrd" --include="casper/vmlinuz" --include="casper/minimal.standard.live.squashfs" --include="casper/minimal.standard.live.manifest" --include="casper/minimal.standard.live.size" --include="casper/install-sources.yaml" --exclude="casper/*" --exclude="md5sum.txt" --exclude="MD5SUMS" --exclude=".disk/release_notes_url" --exclude="casper/*.gpg"
    unsquashfs -d "$CHROOT_DIR" "$ISO_MOUNT_DIR/casper/minimal.squashfs"
    unsquashfs -d "$CHROOT_DIR_EXTRA" "$ISO_MOUNT_DIR/casper/minimal.standard.squashfs"
    rsync -a "$CHROOT_DIR_EXTRA/" "$CHROOT_DIR/"
    rm -rf "$CHROOT_DIR_EXTRA"
    umount "$ISO_MOUNT_DIR"
else
    rsync -a "$ISO_MOUNT_DIR/" "$ISO_WORK_DIR"
    umount "$ISO_MOUNT_DIR"
    unsquashfs -d "$CHROOT_DIR" "$ISO_WORK_DIR/casper/filesystem.squashfs"
fi

rm "$(pwd)/$ISO_IMAGE"
