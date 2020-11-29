#!/bin/bash

virsh nodedev-reattach pci_0000_0a_00_0 > /dev/null 2>&1
virsh nodedev-reattach pci_0000_0a_00_1 > /dev/null 2>&1
virsh nodedev-reattach pci_0000_0c_00_3 > /dev/null 2>&1

sleep 2 # To avoid race condition

## Reload the framebuffer and console
echo 1 > /sys/class/vtconsole/vtcon0/bind
echo 1 > /sys/class/vtconsole/vtcon1/bind || true

echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/bind
