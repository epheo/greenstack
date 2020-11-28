#!/bin/bash

## Kill the console
echo 0 > /sys/class/vtconsole/vtcon0/bind
echo 0 > /sys/class/vtconsole/vtcon1/bind || true
echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind

sleep 2 # To avoid race condition

## Detach the GPU
virsh nodedev-detach pci_0000_0a_00_0 > /dev/null 2>&1
virsh nodedev-detach pci_0000_0a_00_1 > /dev/null 2>&1
virsh nodedev-detach pci_0000_0c_00_3 > /dev/null 2>&1

## Load vfio
modprobe vfio-pci
