#!/bin/bash
export DISPLAY=:0
export PATH=/usr/bin:/usr/local/bin:/usr/bin/X11:$PATH

LOG="$HOME/hdmi-monitor.log"

log() {
    echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG"
}

pause_media() {
    local win
    win=$(xdotool search --class "[Cc]hromium" 2>/dev/null | head -1)
    if [[ -n "$win" ]]; then
        xdotool windowfocus --sync "$win"
        sleep 0.1
        xdotool key --window "$win" --clearmodifiers space
        log "Sent pause to Chromium (window $win)"
    else
        log "No Chromium window found — skipping pause"
    fi
}

# Give the desktop session time to settle on boot
sleep 8

is_display_connected() {
    xrandr --query 2>/dev/null | grep -q " connected"
}

log "HDMI monitor started (poll: 5s, log: $LOG)"

PREV_STATE=""

while true; do
    if is_display_connected; then
        STATE="connected"
    else
        STATE="disconnected"
    fi

    if [[ -n "$PREV_STATE" && "$STATE" != "$PREV_STATE" ]]; then
        if [[ "$STATE" == "disconnected" ]]; then
            log "Display disconnected — pausing media, disabling HDMI"
            pause_media
            vcgencmd display_power 0
        else
            log "Display reconnected — restoring HDMI"
            vcgencmd display_power 1
        fi
    fi

    PREV_STATE="$STATE"
    sleep 5
done
