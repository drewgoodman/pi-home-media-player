#!/bin/bash
export DISPLAY=:0
export PATH=/usr/bin:/usr/local/bin:/usr/bin/X11:$PATH

# Give the desktop session time to settle on boot
sleep 8

is_display_connected() {
    # Looks for any output line containing " connected" (space-prefixed to
    # avoid matching "disconnected")
    xrandr --query 2>/dev/null | grep -q " connected"
}

echo "Monitoring HDMI connection state via xrandr..."
echo "Poll interval: 5s"
echo ""

PREV_STATE=""

while true; do
    if is_display_connected; then
        STATE="connected"
    else
        STATE="disconnected"
    fi

    if [[ -n "$PREV_STATE" && "$STATE" != "$PREV_STATE" ]]; then
        if [[ "$STATE" == "disconnected" ]]; then
            echo "[$(date '+%H:%M:%S')] Display disconnected — pausing media, disabling HDMI"
            xdotool key space
            vcgencmd display_power 0
        else
            echo "[$(date '+%H:%M:%S')] Display reconnected — restoring HDMI"
            vcgencmd display_power 1
        fi
    fi

    PREV_STATE="$STATE"
    sleep 5
done
