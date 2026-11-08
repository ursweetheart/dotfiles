#!/bin/sh
# Wi-Fi menu (rofi + NetworkManager). Opened by clicking Wi-Fi on the bar.

notify() { notify-send -a "Wi-Fi" "$1" "$2" 2>/dev/null; }

radio=$(nmcli radio wifi)
if [ "$radio" = disabled ]; then
    choice=$(printf '󰖩  Turn Wi-Fi on\n' | rofi -dmenu -i -p "Wi-Fi")
    [ -n "$choice" ] && nmcli radio wifi on && notify "Wi-Fi turned on" "Click Wi-Fi on the bar again to pick a network."
    exit 0
fi

notify "Wi-Fi" "Scanning for networks..."

# Fields without colons first, SSID last (nmcli escapes ':' inside it as '\:')
list=$(nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID dev wifi list --rescan auto |
    awk -F: '{
        inuse = $1; sig = $2; sec = $3
        ssid = $0; sub(/^[^:]*:[^:]*:[^:]*:/, "", ssid); gsub(/\\:/, ":", ssid)
        if (ssid == "" || seen[ssid]++) next
        print inuse "\t" sig "\t" sec "\t" ssid
    }')

current=$(printf '%s\n' "$list" | awk -F'\t' '$1 == "*" {print $4}')

menu=$(printf '%s\n' "$list" | awk -F'\t' '{
    lock = ($3 == "" || $3 == "--") ? "  " : "󰌾 "
    mark = ($1 == "*") ? "  (connected)" : ""
    printf "%s %3s%%  %s%s\n", lock, $2, $4, mark
}')

header="󰖪  Turn Wi-Fi off"
[ -n "$current" ] && header="󰅖  Disconnect from $current
$header"

choice=$(printf '%s\n%s\n' "$header" "$menu" | rofi -dmenu -i -p "Wi-Fi" -format i)
[ -z "$choice" ] && exit 0

# Header lines come first in the list
headers=$(printf '%s\n' "$header" | wc -l)
if [ "$choice" -lt "$headers" ]; then
    line=$(printf '%s\n' "$header" | sed -n "$((choice + 1))p")
    case "$line" in
        *Disconnect*) nmcli dev disconnect wlan0 >/dev/null && notify "Disconnected" "$current" ;;
        *off*)        nmcli radio wifi off && notify "Wi-Fi turned off" ;;
    esac
    exit 0
fi

row=$(printf '%s\n' "$list" | sed -n "$((choice - headers + 1))p")
ssid=$(printf '%s' "$row" | cut -f4)
security=$(printf '%s' "$row" | cut -f3)
[ -z "$ssid" ] && exit 0

# Saved network: just connect
if nmcli -g NAME connection show | grep -Fxq "$ssid"; then
    if out=$(nmcli connection up id "$ssid" 2>&1); then
        notify "Connected" "$ssid"
        exit 0
    fi
    # Saved password may be wrong; fall through and ask again
    nmcli connection delete id "$ssid" >/dev/null 2>&1
fi

if [ -n "$security" ] && [ "$security" != "--" ]; then
    pw=$(rofi -dmenu -password -p "Password for $ssid" < /dev/null)
    [ -z "$pw" ] && exit 0
    out=$(nmcli dev wifi connect "$ssid" password "$pw" 2>&1)
else
    out=$(nmcli dev wifi connect "$ssid" 2>&1)
fi

if [ $? -eq 0 ]; then
    notify "Connected" "$ssid"
else
    nmcli connection delete id "$ssid" >/dev/null 2>&1
    notify "Couldn't connect to $ssid" "$out"
fi
