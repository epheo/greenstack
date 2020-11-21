#!/bin/bash

if [[ -z "$(iwgetid -r)" ]] ;then
  icon=""
  net=$(ip -o route get to 1.1.1.1 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')
else
  icon=""
  net=$(iwgetid -r)
fi

case "$BLOCK_BUTTON" in
    1|2)
        text="$net";;
    3)
        text=""
esac

echo $text $icon
