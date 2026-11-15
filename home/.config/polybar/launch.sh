#!/usr/bin/env sh

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
# (force-kill after 5 seconds so this can never hang)
i=0
while pgrep -u "$(id -u)" -x polybar >/dev/null; do
  i=$((i + 1))
  [ "$i" -ge 5 ] && killall -q -9 polybar
  sleep 1
done

# for multimonitor
if type "xrandr"; then
  monitors=$(xrandr --listactivemonitors | awk 'NR>1 {print $NF}')
  # Only one bar can own the X11 tray: prefer HDMI-1, else the first monitor
  tray_mon=$(echo "$monitors" | grep -x HDMI-1 || echo "$monitors" | head -n1)
  for m in $monitors; do
    if [ "$m" = "$tray_mon" ]; then tp=right; else tp=none; fi
    MONITOR=$m TRAY_POSITION=$tp polybar --reload example & disown
  done
else
  polybar --reload example & disown
fi
