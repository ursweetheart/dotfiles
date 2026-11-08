#!/usr/bin/env bash
set -euo pipefail

if ! updates_arch=$(checkupdates 2> /dev/null | wc -l ); then
    updates_arch=0
fi

updates_aur=0
if command -v paru >/dev/null 2>&1; then
    updates_aur=$(paru -Qum 2>/dev/null | wc -l) || updates_aur=0
elif command -v yay >/dev/null 2>&1; then
    updates_aur=$(yay -Qum 2>/dev/null | wc -l) || updates_aur=0
fi

updates=$(("$updates_arch" + "$updates_aur"))

#if [ "$updates" -gt 0 ]; then
#    echo "# $updates"
#else
#    echo ""
#fi


re='^[0-9]+$'
if ! [[ $updates_arch =~ $re ]] ; then
   updates_aur=999; exit 1
fi

if ! [[ $updates_arch =~ $re ]] ; then
   updates_aur=999; exit 1
fi

echo "P:$updates_arch Y:$updates_aur"
