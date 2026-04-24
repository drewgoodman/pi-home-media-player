#!/bin/bash
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
USERNAME="$(whoami)"
HOME_DIR="/home/$USERNAME"

echo "=== Pi Home Media Install ==="
echo "User: $USERNAME"
echo "Repo: $REPO_DIR"
echo ""

# Install dependencies
echo "[1/4] Installing dependencies..."
sudo apt update -q
sudo apt install -y cec-utils xdotool git

# Install scripts
echo "[2/4] Installing scripts..."
mkdir -p "$HOME_DIR/bin"
cp "$REPO_DIR/scripts/cec-monitor.sh" "$HOME_DIR/bin/cec-monitor.sh"
cp "$REPO_DIR/scripts/low-power.sh"   "$HOME_DIR/bin/low-power.sh"
chmod +x "$HOME_DIR/bin/cec-monitor.sh"
chmod +x "$HOME_DIR/bin/low-power.sh"

# Install homepage
echo "[3/4] Installing homepage..."
mkdir -p "$HOME_DIR/homepage"
cp "$REPO_DIR/homepage/index.html" "$HOME_DIR/homepage/index.html"

# Install autostart entries
echo "[4/4] Installing autostart entries..."
mkdir -p "$HOME_DIR/.config/autostart"
sed "s|YOUR_USERNAME|$USERNAME|g" "$REPO_DIR/autostart/cec-monitor.desktop"     > "$HOME_DIR/.config/autostart/cec-monitor.desktop"
sed "s|YOUR_USERNAME|$USERNAME|g" "$REPO_DIR/autostart/chromium-kiosk.desktop"  > "$HOME_DIR/.config/autostart/chromium-kiosk.desktop"

echo ""
echo "=== Done ==="
echo "Scripts:   $HOME_DIR/bin/"
echo "Homepage:  file://$HOME_DIR/homepage/index.html"
echo ""
echo "Test the CEC monitor manually before relying on autostart:"
echo "  ~/bin/cec-monitor.sh"
