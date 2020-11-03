#!/bin/bash


fail() {
  cat <<EOF


# Failed: The build of your Arch cloud image have failed.
# -------------------------------------------------------
# 
EOF
  read -r -p "# Unmount and cleanup? [Y/n] " response
  if [ $interactive = yes ] ;then
    case "$response" in
        [nN][oO]|[nN])
            echo "# Ok."
            echo "#" ; exit 1
            ;;
        *)
            echo "# Ok. Cleaning up..."
            echo "#" ; cleanup ; exit 1
            ;;
    esac
  fi
  echo "# Cleaning up..."
  echo "#" ; cleanup ; exit 1
}

cleanup() {
  cat <<EOF


# Cleaning up now.
# -----------------------
# Umounting /boot and /
# Run FSCK so that resize can work
# Dettach loop device
# Delete temp mount dir
#
EOF
  if [ -n $part_efi ] ;then sudo umount ${mount_dir}/boot ;fi
  sudo umount $mount_dir
  if [ -n $part_root ] ;then sudo tune2fs -j $part_root || true
    sudo fsck.ext4 -f $part_root || true
  fi
  if [ $format == raw ] ;then sudo kpartx -d $vol_name ;fi
  if [ $format == qcow2 ] ;then 
    sudo qemu-nbd --disconnect /dev/nbd0 ; sudo rmmod nbd
  fi
  sudo rmdir $mount_dir
  # $chenv rm /etc/machine-id || true
  # $chenv rm /var/lib/dbus/machine-id || true
}

