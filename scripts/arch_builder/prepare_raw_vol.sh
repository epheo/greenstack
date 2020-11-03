#!/bin/bash

if [ $boot_mode == bios ] ;then part_num=1 ;fi
if [ $boot_mode == uefi ] ;then part_num=2 ;fi

cat <<EOF


# Attach Raw image to loop device
# and get second partition device name
# ------------------------------------
#
EOF
sudo modprobe loop

devices=$(sudo kpartx -av $vol_name |grep loop |awk '{print $3}')

if [ $(echo $devices |wc -w) != $part_num ] ;then
  cat <<EOF


# ERROR:
# Kpartx didn't brought back enough loop names.
# Trying to detach and reattach again...
# ---------------------------------------------
#
EOF
  sudo kpartx -d
  devices=$(sudo kpartx -av $vol_name |grep loop |awk '{print $3}')
fi
if [ $(echo $devices |wc -w) != $part_num ] ;then
  cat <<EOF


# FATAL ERROR:
# Kpartx didn't brought back enough loop names.
# Let's give up this time.
# ---------------------------------------------
#
EOF
  fail
fi

if [ $part_num = 1 ] ;then
  part_root=/dev/mapper/$(echo $devices |awk '{print $1}')
fi
if [ $part_num = 2 ] ;then
  part_efi=/dev/mapper/$(echo $devices |awk '{print $1}')
  part_root=/dev/mapper/$(echo $devices |awk '{print $2}')
fi

