# dotfiles

My i3 desktop on CachyOS (Gigabyte G5 GE: Intel Iris Xe + RTX 3050 Laptop, 144 Hz HDMI monitor).

## Install

```sh
git clone https://github.com/<you>/dotfiles ~/dotfiles
cd ~/dotfiles
./install.sh
```

- `./install.sh --configs-only` only links the configs.
- `./install.sh --packages-only` only installs packages.

Configs in `home/` are **symlinked** into your home folder, so editing `~/.config/...` edits this repo. Existing files are moved to `<name>.bak-<date>` first. To save changes: `cd ~/dotfiles && git add -A && git commit -m "..." && git push`.

## What's in it

| | |
|---|---|
| **i3** | gaps, Windows-like shortcuts, `--no-startup-id` everywhere (no busy cursor) |
| **Screens** | `display.sh` keeps every screen at its max refresh rate (144 Hz) and switches between HDMI and laptop screen on hotplug |
| **Screenshots** | `Win+Shift+S` / `Print` area, `Shift+Print` current monitor. Copied to clipboard, never saved |
| **Polybar** | CPU, RAM, temp, network, Wi-Fi (click for menu), sound (click to choose output), battery, updates, clock |
| **Vietnamese** | fcitx5 + Unikey, `Ctrl+Shift` to switch |
| **Fn keys** | volume, mic mute, brightness, media, keyboard backlight (needs `tuxedo-drivers-dkms`) |
| **Look** | capitaine cursors everywhere, picom with blur |

## Key shortcuts (Win = Windows key)

| Key | Does |
|---|---|
| Win+Enter | Terminal |
| Ctrl+Space | App launcher |
| Win+Q | Close window |
| Win+Shift+S | Screenshot area to clipboard |
| Ctrl+Shift | English / Vietnamese |
| Win+L | Lock |
| Win+Shift+C / R | Reload / restart i3 |

## Machine-specific bits

Change these on a different laptop:

- `home/.config/i3/scripts/display.sh`: output names `eDP-1` / `HDMI-1` and `/sys/class/drm/card1-HDMI-A-1`
- `home/.config/polybar/config`: network interfaces `enp4s0` / `wlan0`, `thermal-zone = 5`, battery `BAT0`
- `home/.config/polybar/scripts/wifi-menu.sh`: `wlan0`
- `aur.txt`: `tuxedo-drivers-dkms` is only for Clevo-based laptops
- Run an app on the NVIDIA GPU with `prime-run <app>`. CUDA apps (PyTorch etc.) use it automatically.
