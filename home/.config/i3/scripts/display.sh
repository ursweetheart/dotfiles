#!/bin/sh
# Keeps every screen at its highest refresh rate, and handles plugging the
# HDMI monitor in and out.
#
#   display.sh          start the watcher (run once from the i3 config)
#   display.sh layout   apply the default layout now
#   display.sh fix      raise every active screen to its max refresh rate now
#
# Default layout:
#   HDMI plugged in -> HDMI-1 only, primary   (laptop screen off)
#   HDMI unplugged  -> laptop screen (eDP-1)
# Change the layout any time with arandr; this script only bumps the refresh
# rate back up and won't undo your layout, except when the cable is plugged
# in or unplugged.

LAPTOP=eDP-1
EXTERNAL=HDMI-1
HDMI_STATUS=/sys/class/drm/card1-HDMI-A-1/status

hdmi_connected() { [ "$(cat "$HDMI_STATUS" 2>/dev/null)" = connected ]; }

layout() {
    if hdmi_connected; then
        xrandr --output "$EXTERNAL" --mode 1920x1080 --rate 144 --primary --pos 0x0 \
               --output "$LAPTOP" --off
    else
        xrandr --output "$LAPTOP" --mode 1920x1080 --rate 144 --primary --pos 0x0 \
               --output "$EXTERNAL" --off
    fi
}

# For each active screen: if its current rate isn't the highest one its
# current resolution supports, switch to the highest.
fix() {
    xrandr --current | awk '
        /^[^ ]/ { out = ""; if ($2 == "connected" && $0 ~ /[0-9]+x[0-9]+\+[0-9]+\+[0-9]+/) out = $1; next }
        out != "" && /\*/ {
            mode = $1; cur = ""; max = 0
            for (i = 2; i <= NF; i++) {
                r = $i; gsub(/[*+]/, "", r)
                if (r == "") continue
                if ($i ~ /\*/) cur = r
                if (r + 0 > max + 0) max = r
            }
            if (cur != max) print out, mode, max
            out = ""
        }' |
    while read -r out mode rate; do
        xrandr --output "$out" --mode "$mode" --rate "$rate"
    done
}

watch() {
    # Only one watcher at a time
    exec 9>"${XDG_RUNTIME_DIR:-/tmp}/display-watch.lock"
    flock -n 9 || exit 0

    layout
    last=$(cat "$HDMI_STATUS" 2>/dev/null)
    last_screens=$(xrandr --listactivemonitors)

    # Wake up on any i3 output change (arandr, xrandr) or cable hotplug
    { i3-msg -t subscribe -m '["output"]' & udevadm monitor --udev --subsystem-match=drm & wait; } |
    while read -r _; do
        sleep 1
        now=$(cat "$HDMI_STATUS" 2>/dev/null)
        if [ "$now" != "$last" ]; then
            last=$now
            layout
        fi
        fix
        # Screens added, removed or moved: redraw wallpaper and bars to match
        screens=$(xrandr --listactivemonitors)
        if [ "$screens" != "$last_screens" ]; then
            last_screens=$screens
            feh --no-fehbg --bg-fill ~/.config/i3/wallpaper.png
            ~/.config/polybar/launch.sh >/dev/null 2>&1 &
        fi
    done
}

case "$1" in
    layout) layout ;;
    fix)    fix ;;
    *)      watch ;;
esac
