#!/bin/bash

# args: $vol is either a nbd volume or a raw volume

gdisk_bin="sudo /usr/bin/gdisk"

# Create a new empty table
$gdisk_bin $vol << EOF
o
Y
w
Y
EOF

# Create a new EFI partition
$gdisk_bin $vol << EOF
n
1

+1G
ef00
w
Y
EOF

# Create a new root partition
$gdisk_bin $vol << EOF
n
2


8300
w
Y
EOF

