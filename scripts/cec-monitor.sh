#!/bin/bash
export DISPLAY=:0
export PATH=/usr/bin:/usr/local/bin:/usr/bin/X11:$PATH

LOG="$HOME/cec-monitor.log"
# How often (seconds) to actively query the projector's power state as a fallback.
# Passive CEC events are caught immediately; this catches projectors that never broadcast standby.
POLL_INTERVAL=30

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

# --debug: dump all raw CEC traffic to console AND log, useful for tuning grep patterns.
if [[ "$1" == "--debug" ]]; then
    log "=== Debug mode started — logging all raw CEC traffic ==="
    echo "All output also written to $LOG"
    stdbuf -oL cec-client -d 8 2>&1 | tee -a "$LOG"
    exit 0
fi

# Query the projector's power status via CEC opcode 0x8F (Give Device Power Status).
# Returns "on", "standby", or "unknown" based on the 0x90 response.
# This works on projectors that don't broadcast standby events.
query_power_status() {
    local response
    # "tx 1f:8F" = from us (1) to TV/display (f is broadcast; some projectors need address 0)
    # cec-client -s runs a single command and exits
    response=$(echo "tx 1f:8F" | timeout 5 cec-client -s -d 1 2>/dev/null)
    if echo "$response" | grep -qi "power status: on\|power status: in transition to on"; then
        echo "on"
    elif echo "$response" | grep -qi "power status: stand\|power status: in transition to stand"; then
        echo "standby"
    else
        echo "unknown"
    fi
}

log "=== CEC monitor started (passive events + ${POLL_INTERVAL}s active poll, log: $LOG) ==="
log "Tip: run with --debug to capture raw traffic from your projector"

DISPLAY_STATE="on"   # assumed on at startup
LAST_POLL=0

# Restart loop — if cec-client exits unexpectedly, restart after a short pause.
while true; do
    log "Starting cec-client listener..."

    stdbuf -oL cec-client -d 8 2>&1 | while IFS= read -r line; do
        # Log every line so we can see exactly what the projector sends
        echo "[$(date '+%H:%M:%S')] RAW: $line" >> "$LOG"

        now=$(date +%s)

        # --- Passive standby detection ---
        # Matches:
        #   "standby" anywhere in a human-readable event
        #   ">> XX:36" — CEC opcode 0x36 (Standby) arriving from any device
        #   "power status: standby" — response to our active poll
        if echo "$line" | grep -qiE \
            "standby|\
>> [0-9a-f]{2}:36([^0-9a-f]|$)|\
power status: stand"; then

            if [[ "$DISPLAY_STATE" != "off" ]]; then
                DISPLAY_STATE="off"
                log "Standby detected (passive) — pausing media, disabling HDMI"
                pause_media
                vcgencmd display_power 0
            fi
        fi

        # --- Passive wake detection ---
        # Matches:
        #   0x82 = Active Source
        #   0x04 = Image View On
        #   0x0D = Text View On
        #   0x90 with "power status: on" = response to active poll
        if echo "$line" | grep -qiE \
            "active source|image view on|text view on|\
>> [0-9a-f]{2}:(82|04|0d)([^0-9a-f]|$)|\
power status: on|power status: in transition to on"; then

            if [[ "$DISPLAY_STATE" != "on" ]]; then
                DISPLAY_STATE="on"
                log "Wake detected (passive) — restoring HDMI"
                vcgencmd display_power 1
            fi
        fi

        # --- Active power status poll (fallback for projectors that go silent) ---
        if (( now - LAST_POLL >= POLL_INTERVAL )); then
            LAST_POLL=$now
            status=$(query_power_status)
            log "Active poll: projector reports '$status' (display state: $DISPLAY_STATE)"

            if [[ "$status" == "standby" && "$DISPLAY_STATE" != "off" ]]; then
                DISPLAY_STATE="off"
                log "Standby detected (active poll) — pausing media, disabling HDMI"
                pause_media
                vcgencmd display_power 0
            elif [[ "$status" == "on" && "$DISPLAY_STATE" != "on" ]]; then
                DISPLAY_STATE="on"
                log "Wake detected (active poll) — restoring HDMI"
                vcgencmd display_power 1
            fi
        fi
    done

    log "cec-client exited — restarting in 5s"
    sleep 5
done
