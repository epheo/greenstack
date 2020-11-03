#!/bin/bash

parted_bin=sudo /usr/bin/parted
$parted_bin -s $vol mktable msdos
$parted_bin -s -a optimal $vol mkpart primary ext4 1M 100%
$parted_bin -s $vol set 1 boot on

