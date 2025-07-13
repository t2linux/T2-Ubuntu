#!/bin/bash

set -eu -o pipefail
ROOT_PATH=$(pwd)/work
OUTPUT_PATH=$(pwd)/output
FLAVOUR=$1
ISO_MOUNT_DIR="$ROOT_PATH/${FLAVOUR}-original"    # Temporary mount point for the original ISO
VER=24.04
CODENAME=noble
KERNEL_VERSION=6.15.6
PKGREL=1

ISO_IMAGE=${FLAVOUR}-24.04.2-desktop-amd64.iso
ISO_IMAGE_OUTPUT="${OUTPUT_PATH}/${FLAVOUR}-${VER}-${KERNEL_VERSION}-t2-${CODENAME}.iso"

ISO_WORK_DIR="$ROOT_PATH/${FLAVOUR}-iso"
CHROOT_DIR="$ROOT_PATH/${FLAVOUR}-edit"

echo "ROOT_PATH=$ROOT_PATH"
echo "ISO_MOUNT_DIR=$ISO_MOUNT_DIR"  
echo "ISO_WORK_DIR=$ISO_WORK_DIR"  
echo "CHROOT_DIR=$CHROOT_DIR"

mkdir -p "$ROOT_PATH"
mkdir -p "$ISO_WORK_DIR"
mkdir -p "$CHROOT_DIR"
mkdir -p "$(dirname "$ISO_IMAGE_OUTPUT")"
touch "$ISO_IMAGE_OUTPUT"

echo >&2 "===]> Info: Installing required packages..."     
apt update && apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y tzdata \
	&& apt install -y util-linux rsync squashfs-tools grub-pc-bin grub-common \
	xorriso isolinux grub-efi-amd64-bin mtools dosfstools curl

echo >&2 "===]> Info: Download ISO..."

curl -L -o "$(pwd)/${ISO_IMAGE}" "https://cdimage.ubuntu.com/${FLAVOUR}/releases/${VER}/release/${ISO_IMAGE}"
 
# Run entrypoint.sh to extract and customize the ISO
echo >&2 "===]> Info: Starting extraction and customization..."
/bin/bash -c "
    ISO_IMAGE=${ISO_IMAGE} \\
    ISO_MOUNT_DIR=${ISO_MOUNT_DIR} \\
    ISO_WORK_DIR=${ISO_WORK_DIR} \\
    CHROOT_DIR=${CHROOT_DIR} \\
    ROOT_PATH=${ROOT_PATH} \\
    KERNEL_VERSION=${KERNEL_VERSION} \\
    FLAVOUR=${FLAVOUR} \\
    $(pwd)/01_edit_iso.sh"

# Enter the Chroot Environment and Apply Customizations
echo >&2 "===]> Info: Creating chroot environment... "
# Mount Required Filesystems for Chroot
mount --bind /dev "${CHROOT_DIR}/dev"
mount --bind /dev/pts "${CHROOT_DIR}/dev/pts"
mount --bind /proc "${CHROOT_DIR}/proc"
mount --bind /sys "${CHROOT_DIR}/sys"

mkdir -p "${CHROOT_DIR}/tmp/setup_files"
#rm -f "${CHROOT_DIR}/etc/resolv.conf"
#make a back up
cp -p "${CHROOT_DIR}/etc/resolv.conf" "${CHROOT_DIR}/etc/resolv.conf.backup"
cp -p /etc/resolv.conf "${CHROOT_DIR}/etc/resolv.conf"
cp "$(pwd)/chroot_iso.sh" "${CHROOT_DIR}/tmp/setup_files"
ls "${CHROOT_DIR}/tmp/setup_files"
echo >&2 "===]> Info: Running chroot environment... "
chroot "${CHROOT_DIR}" /bin/bash -c "KERNEL_VERSION=${KERNEL_VERSION} PKGREL=${PKGREL} /tmp/setup_files/chroot_iso.sh"
echo >&2 "===]> Info: Getting Kernel environment... "
T2_KERNEL=${KERNEL_VERSION}-${PKGREL}-t2-${CODENAME}

echo >&2 "===]> Info: Cleanup the chroot environment... "
# restore backup
cp -p "${CHROOT_DIR}/etc/resolv.conf.backup" "${CHROOT_DIR}/etc/resolv.conf"
umount "${CHROOT_DIR}/dev/pts"
umount "${CHROOT_DIR}/dev"
umount "${CHROOT_DIR}/proc"
umount "${CHROOT_DIR}/sys"

echo >&2 "===]> Info: Squashing $(echo ${FLAVOUR} | cut -c1 | tr '[a-z]' '[A-Z]')$(echo ${FLAVOUR} | cut -c2-) file system ... "
mksquashfs "$CHROOT_DIR" "$ISO_WORK_DIR/casper/filesystem.squashfs" -comp xz -noappend

# Run create_iso.sh to generate the new ISO
# echo "Creating the custom ISO..."
echo >&2 "===]> Info: Creating iso ... "
/bin/bash -c "
    ISO_WORK_DIR=${ISO_WORK_DIR} \\
    CHROOT_DIR=${CHROOT_DIR} \\
    ISO_IMAGE_OUTPUT=${ISO_IMAGE_OUTPUT} \\
    ROOT_PATH=${ROOT_PATH} \\
    T2_KERNEL=${T2_KERNEL} \\
    FLAVOUR=${FLAVOUR} \\
	$(pwd)/02_create_iso.sh"
# split iso

split -b 1500M -x "${OUTPUT_PATH}/${FLAVOUR}-${VER}-${KERNEL_VERSION}-t2-${CODENAME}.iso" "${OUTPUT_PATH}/${FLAVOUR}-${VER}-${KERNEL_VERSION}-t2-${CODENAME}.iso."
sha256sum "${OUTPUT_PATH}"/*.iso > "${OUTPUT_PATH}/sha256-${FLAVOUR}-${VER}"
