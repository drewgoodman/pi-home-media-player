#!/bin/bash
export DISPLAY=:0
export PATH=/usr/bin:/usr/local/bin:/usr/bin/X11:$PATH

LOG="$HOME/cec-monitor.log"

# Override with a specific path if auto-detection picks the wrong device, e.g.:
#   KEYBOARD_DEVICE="/dev/input/event3"
# Run `ls -la /dev/input/by-id/` on the Pi to find the right symlink.
KEYBOARD_DEVICE=""

log() {
    echo "[$(date '+%H:%M:%S')] [kbd-wake] $*" | tee -a "$LOG"
}

find_keyboard() {
    # Prefer /dev/input/by-id/ entries that name themselves as keyboards.
    # The REIIE H9+ shows up here as something like:
    #   usb-REIIE_...-event-kbd
    local symlink
    for symlink in /dev/input/by-id/*kbd* /dev/input/by-id/*Keyboard* /dev/input/by-id/*keyboard*; do
        [[ -e "$symlink" ]] && readlink -f "$symlink" && return
    done

    # Fallback: parse /proc/bus/input/devices for HID/keyboard handlers.
    awk '
        /Keyboard|keyboard|HID|Wireless/ { found=1 }
        found && /Handlers/ {
            match($0, /event[0-9]+/)
            if (RSTART) { print "/dev/input/" substr($0, RSTART, RLENGTH); found=0; exit }
        }
        /^$/ { found=0 }
    ' /proc/bus/input/devices
}

is_display_off() {
    vcgencmd display_power 2>/dev/null | grep -q "=0"
}

wake_display() {
    log "Keypress detected while display off — restoring HDMI"
    vcgencmd display_power 1
    log "HDMI restored"
}

# Give the desktop session time to settle on boot before we start watching.
sleep 8

if [[ -z "$KEYBOARD_DEVICE" ]]; then
    KEYBOARD_DEVICE=$(find_keyboard)
fi

if [[ -z "$KEYBOARD_DEVICE" || ! -e "$KEYBOARD_DEVICE" ]]; then
    log "ERROR: Could not find keyboard input device. Set KEYBOARD_DEVICE manually in this script."
    log "       Run: ls -la /dev/input/by-id/  — look for a *kbd* or *keyboard* entry."
    exit 1
fi

log "=== Keyboard wake monitor started (device: $KEYBOARD_DEVICE, log: $LOG) ==="

while true; do
    # Block here until any input event arrives (one struct input_event = 24 bytes on 64-bit).
    # This does not grab exclusive access — X11 still receives the same events normally.
    dd if="$KEYBOARD_DEVICE" bs=24 count=1 > /dev/null 2>&1

    if is_display_off; then
        wake_display
        # Drain buffered events and give the projector time to wake before re-arming.
        sleep 3
    fi
done
