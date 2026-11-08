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
  for m in $(xrandr --listactivemonitors | awk 'NR>1 {print $NF}'); do
    MONITOR=$m polybar --reload example & disown
  done
else
  polybar --reload example & disown
fi
