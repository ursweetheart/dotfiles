#!/bin/sh
# brightness.sh up|down: change laptop screen brightness and show it on the xob bar
case "$1" in
    up)   brightnessctl -q set 5%+ ;;
    down) brightnessctl -q set 5%- ;;
esac
pgrep -x xob >/dev/null && brightnessctl -m | cut -d, -f4 | tr -d % > /tmp/xobpipe
