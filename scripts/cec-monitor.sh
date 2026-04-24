#!/bin/bash
export DISPLAY=:0

# Pass --debug to dump all raw CEC traffic — useful for seeing exactly what your
# projector sends before the grep patterns below can be tuned to match it.
if [[ "$1" == "--debug" ]]; then
    echo "Debug mode: printing all raw CEC traffic. Press Ctrl+C to stop."
    cec-client -d 8
    exit 0
fi

echo "Monitoring CEC for display power events..."
echo "Tip: run with --debug to inspect raw traffic from your projector"
echo ""

cec-client -d 8 | while read -r line; do
    # Standby: text match OR hex opcode 0x36 (CEC Standby command)
    # e.g. ">> 0f:36" or "<< (0) standby"
    if echo "$line" | grep -qiE "standby|>> [0-9a-f]{2}:36([^0-9a-f]|$)"; then
        echo "[$(date '+%H:%M:%S')] Standby detected — pausing media, disabling HDMI"
        xdotool key space
        vcgencmd display_power 0
    fi

    # Wake: text match OR hex opcodes:
    #   0x82 = Active Source
    #   0x04 = Image View On
    #   0x0D = Text View On
    if echo "$line" | grep -qiE "active source|image view on|text view on|>> [0-9a-f]{2}:(82|04|0d)([^0-9a-f]|$)"; then
        echo "[$(date '+%H:%M:%S')] Wake detected — restoring HDMI"
        vcgencmd display_power 1
    fi
done
