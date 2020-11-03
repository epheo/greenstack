#!/bin/bash

cat <<__EOF__
# Setting-up syslinux
# -------------------
__EOF__

$chenv mkdir -p /boot/syslinux
$chenv cp /usr/lib/syslinux/bios/*.c32 /boot/syslinux/
kernel=$($chenv find boot -name 'vmlinuz-linux')
ramdisk=$($chenv find boot -name 'initramfs-linux.img')
echo "PROMPT 1
TIMEOUT 50
DEFAULT arch
LABEL arch
    LINUX /$kernel
    APPEND root=$part_root_id rw net.ifnames=0
    INITRD /$ramdisk" \
  |sudo tee $mount_dir/boot/syslinux/syslinux.cfg
$chenv extlinux --install /boot/syslinux/
sudo dd bs=440 count=1 conv=notrunc \
        if=$mount_dir/usr/lib/syslinux/bios/mbr.bin \
        of=$vol_name

