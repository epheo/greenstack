#!/bin/bash

# This script create an Arch Linux Qcow2 image for KVM.
#
# Dependencies are: 
#    qemu parted gdisk multipath-tools arch-install-scripts
# 
# 

# Import config
. config

if [ $debug = 'yes' ]; then
  set -e
  set -x
fi


passless_sudo() {
  test "$(sudo /usr/bin/id -u)" -eq 0
}
passless_sudo

# Import error handling functions
. cleanup.sh

# Construct volume name
vol_name=$directory/$file_name.$format
rm -f $vol_name ||true

# Create tmp chroot env
mount_dir=$(mktemp -d -t build-img.XXXXXX)
chenv="sudo arch-chroot $mount_dir"


echo "


# Create initial volume and install base system
# ---------------------------------------------
#
"
/usr/bin/qemu-img create -f $format $vol_name ${disk_size}G || fail

if [ $format == qcow2 ] ;then
  sudo modprobe nbd max_part=8
  sudo umount /dev/nbd0p1 ||true
  sudo umount /dev/nbd0p2 ||true
  sudo qemu-nbd --disconnect /dev/nbd0
  sudo qemu-nbd --connect=/dev/nbd0 $vol_name
  vol=/dev/nbd0
fi
if [ $format == raw ] ;then
  vol=$vol_name
fi

if [ $boot_mode == uefi ] ;then . make_gpt.sh ;fi
if [ $boot_mode == bios ] ;then . make_mbr.sh ;fi

if [ $format == raw ] ;then . prepare_raw_vol.sh ;fi

if [ $format == qcow2 ] ;then
  if [ $boot_mode == bios ] ;then
    part_root=/dev/nbd0p1
  fi
  if [ $boot_mode == uefi ] ;then
    part_efi=/dev/nbd0p1
    part_root=/dev/nbd0p2
  fi
fi


echo "


# The following partitions are going to be 
# Formated:
# -----------------------------------------
#
# $part_efi $part_root
# 
"

format_part() {
  if [ -n $part_efi ] ;then
    sudo mkfs.fat -F32 $part_efi || fail
  fi
  sudo mkfs.ext4 $part_root || fail
}

if [ $interactive = yes ] ;then
  read -r -p "# Format ? [Y/n] " response
  case "$response" in
      [nN][oO]|[nN])
          echo "# Ok."
          echo "#" ; fail
          ;;
      *)
          echo "# Ok, formating..." ; format_part
          ;;
  esac
else
  echo "# Formating..." ; format_part
fi


if [ $boot_mode == uefi ] ;then
  part_efi_id=$(sudo blkid $part_efi |cut -d ' ' -f2 |tr -d \")
fi
part_root_id=$(sudo blkid $part_root |cut -d ' ' -f2 |tr -d \")

sudo mount $part_root $mount_dir || fail

if [ ! -d ${mount_dir}/boot ]; then sudo mkdir ${mount_dir}/boot ;fi

sudo mount $part_efi ${mount_dir}/boot || fail

sudo pacstrap -c $mount_dir base ansible git sudo || fail

echo "# Creating user $user"
$chenv sh -c "useradd $user"
$chenv sh -c "mkdir ~$user && chown -R $user.$user ~$user"
$chenv sh -c "echo \"$user ALL=(ALL) NOPASSWD: ALL\" >> /etc/sudoers"
$chenv sh -c "echo $user:$password | chpasswd"
$chenv sh -c "echo root:$root_password | chpasswd"

greenstack=/usr/share/greenstack
$chenv git clone https://github.com/epheo/greenstack $greenstack

ansible_cmd="$chenv sudo -u $user ansible-playbook \
               -i $greenstack/inventory.local"

if [ $rescue = yes ] ;then 
  echo "Launching Ansible Rescue role"
  $ansible_cmd $greenstack/rescue.yaml
fi
if [ $cloud = yes ] ;then 
  echo "Launching Ansible Cloud role"
  $ansible_cmd $greenstack/cloud.yaml
fi
if [ $desktop = yes ] ;then 
  echo "Launching Ansible Desktop role"
  $ansible_cmd $greenstack/desktop.yaml
fi

echo "


# Setting the fstab as follow:
# ----------------------------
#
"
if [ $boot_mode == uefi ] ;then
  echo "# /etc/fstab: static file system information.
  
  # $part_efi 
  $part_efi_id /boot vfat rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=iso8859-1,shortname=mixed,utf8,errors=remount-ro 0 2
  
  # $part_root
  $part_root_id  /  ext4  rw,relatime  0  1
  
  " | sudo tee $mount_dir/etc/fstab
fi

if [ $boot_mode == bios ] ;then
  echo "# /etc/fstab: static file system information.
  
  # $part_root
  $part_root_id  /  ext4  rw,relatime  0  1
  
  " | sudo tee $mount_dir/etc/fstab
fi

echo '# Set cloud-arch as hostname'
echo "cloud-arch" |sudo tee $mount_dir/etc/hostname

echo '# Set timezone to UTC'
$chenv rm /etc/localtime
$chenv ln -s /usr/share/zoneinfo/UTC /etc/localtime

echo '# Enable sshd, dhcpcd, cronie'
$chenv systemctl enable cronie.service
$chenv systemctl enable sshd.service
if [ $cloud = yes ] ;then
  $chenv systemctl enable cloud-init-local.service
  $chenv systemctl enable cloud-init.service
fi

echo '# Setting-up initramfs'
# Growfs is used to autoresize image root disk to flavor root disk

sudo sed -i \
  '/^HOOKS=/c\HOOKS=\"base\ udev\ block\ modconf\ filesystems\ keyboard\ fsck\"' \
  $mount_dir/etc/mkinitcpio.conf
sudo sed -i \
  '/^MODULES=/c\MODULES=\"virtio\ virtio_blk\ virtio_pci\ virtio_net\"' \
  $mount_dir/etc/mkinitcpio.conf

$chenv mkinitcpio -p linux

if [ $boot_mode == uefi ] ;then . install_systemdboot.sh ;fi
if [ $boot_mode == bios ] ;then . install_syslinux.sh ;fi

# Umount and clean directories and loop device
cleanup

echo "


# The creation of your Arch cloud image have completed
# Please keep the following informations.
# ----------------------------------------------------------
#
# User: $user
# User Password : $password
# Root Password : $root_password
# Image path: $directory/$file_name.$format
#
" |tee $directory/$file_name.info

