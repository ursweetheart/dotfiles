#!/bin/sh
# Copy a screenshot to the clipboard (nothing is saved to disk).
#   screenshot.sh area     -> drag to select an area, or click a window
#   screenshot.sh monitor  -> the monitor the mouse is on
case "$1" in
  monitor)
    eval "$(xdotool getmouselocation --shell)"
    geom=$(xrandr --listactivemonitors | awk -v x="$X" -v y="$Y" 'NR>1 {
        split($3, a, /[\/x+]/)   # 1920/527x1080/296+1920+0
        if (x >= a[5] && x < a[5]+a[1] && y >= a[6] && y < a[6]+a[3])
            print a[1] "x" a[3] "+" a[5] "+" a[6]
    }')
    [ -n "$DRYRUN" ] && { echo "$geom"; exit; }
    maim -u ${geom:+-g "$geom"} | xclip -selection clipboard -t image/png ;;
  *)
    maim -s -u | xclip -selection clipboard -t image/png ;;
esac
