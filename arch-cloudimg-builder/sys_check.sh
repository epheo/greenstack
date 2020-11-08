#!/bin/bash

if [ $debug = 'yes' ]; then
  set -e
  set -x
fi

test "$(sudo /usr/bin/id -u)" -eq 0 || echo "Need passwdless sudo."


if [ $format = 'qcow2' ]; then
  find /lib/modules/$(uname -r) -type f -name '*.ko*' |grep nbd
fi

if [ $format = 'raw' ]; then
  find /lib/modules/$(uname -r) -type f -name '*.ko*' |grep loop
  whereis kapartx
fi

whereis pacstrap

