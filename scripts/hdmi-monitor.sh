#!/bin/bash
export DISPLAY=:0
export PATH=/usr/bin:/usr/local/bin:/usr/bin/X11:$PATH

# Give the desktop session time to settle on boot
sleep 8

# Discover the HDMI-A-1 status file (path varies by kernel/driver version)
STATUS_FILE=$(find /sys/class/drm -name status 2>/dev/null | grep -i "HDMI-A-1" | head -1)

if [[ -z "$STATUS_FILE" ]]; then
    echo "Error: could not find HDMI-A-1 status file under /sys/class/drm"
    echo "Available connectors:"
    find /sys/class/drm -name status 2>/dev/null | sed 's/^/  /'
    exit 1
fi

echo "Monitoring HDMI connection state via: $STATUS_FILE"
echo "Poll interval: 5s"
echo ""

PREV_STATUS=""

while true; do
    CURRENT=$(cat "$STATUS_FILE" 2>/dev/null)

    if [[ -n "$PREV_STATUS" && "$CURRENT" != "$PREV_STATUS" ]]; then
        if [[ "$CURRENT" == "disconnected" ]]; then
            echo "[$(date '+%H:%M:%S')] HDMI disconnected — pausing media, disabling display"
            xdotool key space
            vcgencmd display_power 0
        elif [[ "$CURRENT" == "connected" ]]; then
            echo "[$(date '+%H:%M:%S')] HDMI reconnected — restoring display"
            vcgencmd display_power 1
        fi
    fi

    PREV_STATUS="$CURRENT"
    sleep 5
done
