#!/bin/sh
# vim: sw=4 ts=4 et :
set -e
#set -x

partition_name() {
    local DISK=$1
    local PARTNUM=$2
    local a=$((PARTNUM+1))
    echo "/dev/$(lsblk -n -l $DISK -o NAME | tail -n +${a} | head -n 1)"
}

DISK=$1

if [ -z "$DISK" ];  then
    echo >&2 "Please specify path to USB device."
    exit 1
fi

DEVICE_NAME=$(basename $DISK)

# Check to see if filesystem is mounted anywhere currently so we do not
# accidentally blow away an important mass storage device.
MOUNTS=$(lsblk $DISK -o MOUNTPOINT | tail -n +2 | sed '/^$/d' | wc -l)
if [ $MOUNTS -ne 0 ]; then
    echo >&2 "$DISK has active mounts? Please unmount and run again."
    exit 1
fi

wipefs -a $DISK

# Create BIOS BOOT partition
parted --script $DISK mklabel gpt \
    mkpart primary 1M 2M \
    set 1 bios_grub on \
    name 1 '"BIOS BOOT"'

# Create EFI partition
parted --script $DISK mkpart primary 2M 100M \
    set 2 esp on \
    name 2 '"EFI"'

# Create main linux partition
parted --script $DISK mkpart primary 100M 500M \
    name 3 '"Linux"'

udevadm settle --timeout=15

EFI_PARTITION=$(partition_name $DISK 2)
LINUX_PARTITION=$(partition_name $DISK 3)
mkfs.vfat $EFI_PARTITION
mkfs.ext4 -F $LINUX_PARTITION

# Now install grub
TEMP_DIR=$(mktemp -d)

# Install an exit trap to make sure to unmount the folders on exit of this
# script
cleanup() {
    set +e
    for dir in $(ls $TEMP_DIR); do umount ${TEMP_DIR}/${dir}; done
    rm -fr $TEMP_DIR
}
trap 'cleanup' EXIT

mkdir $TEMP_DIR/efi
mkdir $TEMP_DIR/linux
mount $EFI_PARTITION $TEMP_DIR/efi
mount $LINUX_PARTITION $TEMP_DIR/linux

mkdir ${TEMP_DIR}/linux/boot

# We want to install this twice so that we have the modules for both UEFI and
# BIOS boot.
grub-install --target=i386-pc \
    --efi-directory=${TEMP_DIR}/efi \
    --boot-directory=${TEMP_DIR}/linux/boot \
    --removable \
    $DISK
grub-install --target=x86_64-efi \
    --efi-directory=${TEMP_DIR}/efi \
    --boot-directory=${TEMP_DIR}/linux/boot \
    --removable \
    --bootloader-id=Star-Lab-Xen-Debian-Install \
    $DISK

#SOURCE=$(pwd)
SOURCE=/source
cp $SOURCE/mini.iso $TEMP_DIR/linux/boot/
cp /boot/xen-4.11-amd64.gz $TEMP_DIR/linux/boot/xen.gz
#cp $SOURCE/xen.gz $TEMP_DIR/linux/boot/xen.gz
cp $SOURCE/grub.cfg $TEMP_DIR/linux/boot/grub/
