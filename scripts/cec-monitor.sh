#!/bin/bash
export DISPLAY=:0

echo "Monitoring CEC for display power events..."

cec-client -d 1 | while read -r line; do
    if echo "$line" | grep -q "standby"; then
        echo "Display went to standby — pausing media and disabling HDMI output"
        xdotool key space
        vcgencmd display_power 0
    fi

    if echo "$line" | grep -q "active source"; then
        echo "Display became active — restoring HDMI output"
        vcgencmd display_power 1
    fi
done
