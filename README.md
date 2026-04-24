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
│   ├── cec-monitor.sh       # Watches CEC bus for projector power events
│   └── low-power.sh         # Three-level power reduction (display/suspend/shutdown)
├── autostart/
│   ├── cec-monitor.desktop  # Autostart entry for CEC monitor
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

### 4. Test the CEC monitor manually

```bash
~/bin/cec-monitor.sh
```

Confirm it reacts to projector standby/wake events before relying on autostart.

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

## Scripts

### `cec-monitor.sh`

Watches the HDMI-CEC bus. When the projector goes to standby, it pauses playback and turns off the HDMI output. When the projector becomes the active source again, it restores the display.

### `low-power.sh`

```bash
~/bin/low-power.sh display    # Turn off HDMI output only
~/bin/low-power.sh suspend    # Pause media, display off, suspend to RAM
~/bin/low-power.sh shutdown   # Full shutdown
```

## Homepage

A dark-themed local HTML page with big keyboard-navigable buttons for each streaming service. Arrow keys move between buttons; Enter opens the selected service.

Set as Chromium's homepage in `chrome://settings`, or launch automatically in kiosk mode via the autostart entry.

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
