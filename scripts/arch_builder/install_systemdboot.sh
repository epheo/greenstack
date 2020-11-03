#!/bin/bash

cat <<EOF


# Setting-up systemd-boot
# -----------------------
#
EOF

$chenv bootctl install

echo "
default  arch.conf
timeout  1
console-mode max
editor   no
" | sudo tee $mount_dir/boot/loader/loader.conf


echo "
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root="$part_root_id" rw
" | sudo tee $mount_dir/boot/loader/entries/arch.conf

