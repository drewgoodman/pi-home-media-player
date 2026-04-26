# Pi Home Media Center

Scripts and a local homepage for a Raspberry Pi 4 media center connected to a projector. Controlled from the couch with a wireless keyboard/touchpad.

## Hardware

| Component | Details |
|---|---|
| Board | Raspberry Pi 4 Model B 2GB |
| Storage | Samsung 32GB microSD |
| Input | REIIE H9+ 2.4GHz wireless keyboard/touchpad |
| Display | Projector via micro-HDMI → HDMI |

## Repo Structure

```
├── install.sh               # One-shot setup script — run once after cloning
├── scripts/
│   ├── cec-monitor.sh       # Watches CEC bus for projector power events (passive + active poll)
│   ├── kbd-wake.sh          # Wakes display on keyboard activity when display is off
│   ├── hdmi-monitor.sh      # Fallback: polls xrandr for HDMI connect/disconnect
│   └── low-power.sh         # Three-level power reduction (display/suspend/shutdown)
├── autostart/
│   ├── cec-monitor.desktop  # Autostart entry for CEC monitor
│   ├── kbd-wake.desktop     # Autostart entry for keyboard wake monitor
│   ├── hdmi-monitor.desktop # Autostart entry for HDMI monitor
│   └── chromium-kiosk.desktop  # Autostart entry for Chromium in kiosk mode (optional)
└── homepage/
    └── index.html           # Local streaming launcher page
```

## Fresh Install

### 1. Flash the SD card

Use [Raspberry Pi Imager](https://www.raspberrypi.com/software/) and open **Advanced Options** (Ctrl+Shift+X) to pre-configure:
- WiFi credentials
- Username and password
- Enable SSH (optional but recommended)

### 2. Clone this repo on the Pi

```bash
git clone https://github.com/drewgoodman/pi-home-media-player.git ~/pi-home-media-player
cd ~/pi-home-media-player
```

### 3. Run the install script

```bash
bash install.sh
```

This will:
- Install dependencies (`cec-utils`, `xdotool`, `git`)
- Copy scripts to `~/bin/` and make them executable
- Copy the homepage to `~/homepage/`
- Install autostart `.desktop` entries to `~/.config/autostart/`
- Write a Chromium managed policy to `/etc/chromium/policies/managed/pi-media.json` that sets the home button to the local launcher page

### 4. Test the monitors manually

```bash
~/bin/cec-monitor.sh --debug   # inspect raw CEC traffic and projector responses
~/bin/kbd-wake.sh              # verify keyboard device is detected and wake fires
```

Confirm each reacts correctly before relying on autostart.

### 4a. Check the `input` group

`kbd-wake.sh` reads directly from `/dev/input/eventX`. If it can't open the device, add your user to the `input` group and reboot:

```bash
sudo usermod -aG input $USER
```

### 5. Reboot

```bash
sudo reboot
```

The CEC monitor will start automatically. Chromium kiosk mode will also start if you leave `chromium-kiosk.desktop` in `~/.config/autostart/`. Remove it if you'd rather launch Chromium manually.

## Updating

On your main machine, make changes and push. On the Pi:

```bash
cd ~/pi-home-media-player && git pull && bash install.sh
```

`install.sh` is safe to re-run.

## Logs

Both `cec-monitor.sh` and `kbd-wake.sh` write to the same file: `~/cec-monitor.log`.

```bash
# Follow live output
tail -f ~/cec-monitor.log

# Check recent activity
tail -100 ~/cec-monitor.log

# Filter to just keyboard wake events
grep kbd-wake ~/cec-monitor.log

# Filter to just standby/wake detections
grep -E "Standby|Wake|Active poll" ~/cec-monitor.log
```

Each line is prefixed with a timestamp. CEC monitor lines have no extra tag; keyboard wake lines are prefixed with `[kbd-wake]`.

## Scripts

### `cec-monitor.sh`

Watches the HDMI-CEC bus using two complementary methods:

- **Passive listening** — matches human-readable CEC text and raw hex opcodes (`0x36` standby, `0x82`/`0x04`/`0x0D` wake). Reacts immediately when the projector broadcasts events.
- **Active polling (every 30s)** — sends a CEC `0x8F` (Give Device Power Status) query and reads the `0x90` response. Catches projectors that go silent on standby without broadcasting anything.

All raw CEC traffic is logged to `~/cec-monitor.log`. The monitor auto-restarts if `cec-client` exits unexpectedly.

If active polling isn't responding, the projector's CEC address may not be `0xF` (broadcast). Run debug mode and look for the address in the `scan` output:

```bash
~/bin/cec-monitor.sh --debug
```

Debug mode logs all raw CEC traffic to `~/cec-monitor.log` and stdout simultaneously. Look for lines like `power address:` in the scan output and update the `tx 1f:8F` address in the `query_power_status` function if needed (e.g. `tx 10:8F` to query device 0 directly).

### `kbd-wake.sh`

Watches the 2.4GHz wireless keyboard's evdev device for any input activity. When a keypress is detected while the display is off, it restores the HDMI output via `vcgencmd display_power 1`, which resumes the video signal and triggers the projector to wake.

Auto-detects the keyboard device from `/dev/input/by-id/` at startup (looks for `*kbd*` symlinks). If detection picks the wrong device or fails, set `KEYBOARD_DEVICE` manually at the top of the script:

```bash
# Find the right device on the Pi
ls -la /dev/input/by-id/
# Look for a line ending in -event-kbd, e.g.:
#   usb-REIIE_H9_Wireless_Keyboard_...-event-kbd -> ../event3
# Then set in kbd-wake.sh:
#   KEYBOARD_DEVICE="/dev/input/event3"
```

Requires the user to be in the `input` group (`sudo usermod -aG input $USER`, then reboot).

### `low-power.sh`

```bash
~/bin/low-power.sh display    # Turn off HDMI output only
~/bin/low-power.sh suspend    # Pause media, display off, suspend to RAM
~/bin/low-power.sh shutdown   # Full shutdown
```

## Homepage

A dark-themed local HTML page with big keyboard-navigable buttons for each streaming service. Arrow keys move between buttons; Enter opens the selected service.

The home button in Chromium is configured automatically by `install.sh` via a managed policy — it will always return to this page. The policy also suppresses the default new-tab shortcuts page. No manual `chrome://settings` changes needed.

**Local Media** links to `http://localhost:8096` (Jellyfin default port). Update this URL if you use a different media server or address.

## Performance Tips

- **GPU Memory:** `sudo raspi-config` → Performance Options → GPU Memory → 128
- **Hardware acceleration:** verify at `chrome://gpu` in Chromium
- **WiFi signal:** `iwconfig wlan0` — target better than -70 dBm
- **Mild overclock** (safe with CanaKit fan + heatsinks):
  ```
  # /boot/config.txt
  over_voltage=2
  arm_freq=1800
  ```
