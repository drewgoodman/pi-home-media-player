#!/bin/bash
# Usage: ./low-power.sh [display|suspend|shutdown]
export DISPLAY=:0

case "$1" in
    display)
        # Level 1: turn off HDMI output, keep everything running
        vcgencmd display_power 0
        ;;
    suspend)
        # Level 2: pause media, turn off display, suspend to RAM
        xdotool key space
        vcgencmd display_power 0
        sleep 2
        systemctl suspend
        ;;
    shutdown)
        # Level 3: full shutdown
        xdotool key space
        shutdown -h now
        ;;
    *)
        echo "Usage: $0 [display|suspend|shutdown]"
        exit 1
        ;;
esac
