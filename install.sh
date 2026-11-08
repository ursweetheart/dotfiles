#!/usr/bin/env bash
# Sets up this i3 desktop on an Arch / CachyOS machine.
#
#   ./install.sh                  packages + configs + system settings
#   ./install.sh --configs-only   only link the config files
#   ./install.sh --packages-only  only install packages
#
# Config files are symlinked from ./home into your home folder, so editing
# ~/.config/... edits this repo too. Any existing file is moved aside to
# <name>.bak-<date> first, never deleted.
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"

say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }

read_list() { grep -vE '^\s*(#|$)' "$1"; }

install_packages() {
    say "Installing packages from packages.txt"
    # shellcheck disable=SC2046
    sudo pacman -S --needed $(read_list "$DOTFILES/packages.txt")

    if ! command -v yay >/dev/null; then
        if pacman -Si yay >/dev/null 2>&1; then
            say "Installing yay"
            sudo pacman -S --needed yay
        else
            warn "yay isn't in your repos; skipping aur.txt. Install yay, then rerun with --packages-only."
            return
        fi
    fi
    say "Installing packages from aur.txt"
    # shellcheck disable=SC2046
    yay -S --needed $(read_list "$DOTFILES/aur.txt")
}

link_configs() {
    say "Linking config files into $HOME"
    cd "$DOTFILES/home"
    find . -type f -print0 | while IFS= read -r -d '' f; do
        f="${f#./}"
        src="$DOTFILES/home/$f"
        dst="$HOME/$f"
        mkdir -p "$(dirname "$dst")"
        if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
            continue
        fi
        if [ -e "$dst" ] || [ -L "$dst" ]; then
            mv "$dst" "$dst.bak-$STAMP"
            echo "   backed up ~/$f -> ~/$f.bak-$STAMP"
        fi
        ln -s "$src" "$dst"
        echo "   linked ~/$f"
    done
}

system_settings() {
    say "System settings"
    # Vietnamese typing (fcitx5) for GTK/Qt/SDL apps
    if ! grep -q '^GTK_IM_MODULE=fcitx' /etc/environment; then
        printf 'GTK_IM_MODULE=fcitx\nQT_IM_MODULE=fcitx\nXMODIFIERS=@im=fcitx\nSDL_IM_MODULE=fcitx\n' |
            sudo tee -a /etc/environment >/dev/null
        echo "   added fcitx5 variables to /etc/environment"
    fi
    # NVIDIA sleep/wake support
    if command -v nvidia-smi >/dev/null; then
        sudo systemctl enable nvidia-suspend nvidia-resume nvidia-hibernate
    fi
}

case "${1:-}" in
    --configs-only)  link_configs ;;
    --packages-only) install_packages ;;
    "")              install_packages; link_configs; system_settings ;;
    *) echo "usage: $0 [--configs-only | --packages-only]"; exit 1 ;;
esac

say "Done. Log out and back in (or press Win+Shift+R) to load everything."
