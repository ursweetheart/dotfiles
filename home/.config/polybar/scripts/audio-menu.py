#!/usr/bin/env python3
"""Sound output menu (rofi), opened by left-clicking the volume on the bar.

Lists every usable output on every sound card (laptop speakers, headphones,
the HDMI monitor, USB/Bluetooth headsets...). Picking one switches the card
profile if needed (keeping the microphone working), makes it the default
output, and moves everything that's currently playing over to it.
"""
import json
import subprocess
import time


def pactl_json(*args):
    out = subprocess.run(["pactl", "-f", "json", *args], capture_output=True, text=True)
    return json.loads(out.stdout or "[]")


def pactl(*args):
    subprocess.run(["pactl", *args], capture_output=True)


def notify(title, body=""):
    subprocess.run(["notify-send", "-a", "Sound", title, body], capture_output=True)


def input_part(profile):
    """'output:hdmi-stereo+input:analog-stereo' -> 'input:analog-stereo'"""
    return next((p for p in profile.split("+") if p.startswith("input:")), "")


def pick_profile(card, port):
    """Profile to use for this port: keep the current one if it already
    covers the port, otherwise prefer one that keeps the same mic input."""
    active = card["active_profile"]
    if active in port["profiles"]:
        return active
    candidates = [
        (name, card["profiles"][name])
        for name in port["profiles"]
        if name in card["profiles"]
        and card["profiles"][name]["available"]
        and card["profiles"][name]["sinks"] > 0
    ]
    if not candidates:
        return None
    want_input = input_part(active)
    candidates.sort(key=lambda c: (input_part(c[0]) == want_input, c[1]["priority"]), reverse=True)
    return candidates[0][0]


def label_for(card, port_name, port):
    props = port.get("properties", {})
    product = props.get("device.product.name")
    card_desc = card["properties"].get("device.description", card["name"])
    kind = port.get("type", "")
    if kind == "HDMI" or port_name.startswith("hdmi"):
        return f"󰍹  Monitor speakers ({product})" if product else f"󰍹  {port['description']}"
    if kind == "Headphones":
        return "  Headphones"
    if kind == "Speaker":
        return "󰓃  Laptop speakers"
    if kind == "Headset":
        return f"󰋎  {card_desc}"
    return f"  {card_desc}: {port['description']}"


def build_entries():
    cards = pactl_json("list", "cards")
    sinks = pactl_json("list", "sinks")
    default = subprocess.run(["pactl", "get-default-sink"], capture_output=True, text=True).stdout.strip()
    default_sink = next((s for s in sinks if s["name"] == default), None)

    entries = []
    for card in cards:
        for port_name, port in card["ports"].items():
            if "output" not in port_name or port["availability"] == "not available":
                continue
            profile = pick_profile(card, port)
            if not profile:
                continue
            current = (
                default_sink is not None
                and default_sink["properties"].get("device.name") == card["name"]
                and default_sink.get("active_port") == port_name
            )
            entries.append({
                "label": label_for(card, port_name, port),
                "card": card["name"],
                "port": port_name,
                "profile": profile,
                "current": current,
            })

    # Outputs that don't belong to a card with ports (rare: virtual sinks etc.)
    card_names = {c["name"] for c in cards}
    for s in sinks:
        if s["properties"].get("device.name") not in card_names:
            entries.append({"label": f"  {s['description']}", "sink": s["name"],
                            "current": s["name"] == default})
    return entries


def sink_for(card_name, timeout=3.0):
    end = time.time() + timeout
    while time.time() < end:
        for s in pactl_json("list", "sinks"):
            if s["properties"].get("device.name") == card_name:
                return s
        time.sleep(0.1)
    return None


def switch(entry):
    if "sink" in entry:
        sink_name = entry["sink"]
    else:
        card = next(c for c in pactl_json("list", "cards") if c["name"] == entry["card"])
        if card["active_profile"] != entry["profile"]:
            pactl("set-card-profile", entry["card"], entry["profile"])
        sink = sink_for(entry["card"])
        if sink is None:
            notify("Couldn't switch sound output", entry["label"].strip())
            return
        sink_name = sink["name"]
        if sink.get("active_port") != entry["port"]:
            pactl("set-sink-port", sink_name, entry["port"])

    pactl("set-default-sink", sink_name)
    for stream in pactl_json("list", "sink-inputs"):
        pactl("move-sink-input", str(stream["index"]), sink_name)
    notify("Sound output", entry["label"].split("  ", 1)[-1])


def main():
    entries = build_entries()
    if not entries:
        notify("No sound outputs found")
        return
    lines = [e["label"] + ("   ✓" if e["current"] else "") for e in entries]
    lines.append("  Sound settings…")
    selected = next((i for i, e in enumerate(entries) if e["current"]), 0)
    res = subprocess.run(
        ["rofi", "-dmenu", "-i", "-p", "Sound output", "-format", "i", "-selected-row", str(selected)],
        input="\n".join(lines), capture_output=True, text=True,
    )
    if res.returncode != 0 or not res.stdout.strip():
        return
    i = int(res.stdout.strip())
    if i == len(entries):
        subprocess.Popen(["pavucontrol"], start_new_session=True)
        return
    switch(entries[i])


if __name__ == "__main__":
    main()
