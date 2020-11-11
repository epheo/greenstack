#!/bin/bash

if [[ -d /sys/class/power_supply/BAT0 ]]; then
  BAT=$(acpi -b | grep -E -o '[0-9][0-9][0-9]?%')
  # Full and short texts
  echo "Battery: $BAT"
  echo "BAT: $BAT"

  # Set urgent flag below 5% or use orange below 20%
  [ ${BAT%?} -le 5  ] && echo " " ;echo 33
  [ ${BAT%?} -le 25 ] && echo " " ;echo "#FF8000"
  [ ${BAT%?} -le 50 ] && echo " "
  [ ${BAT%?} -le 75 ] && echo " "
  [ ${BAT%?} -le 90 ] && echo " "

  exit 0
  echo " "
else
  exit 0
fi
