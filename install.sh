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
echo "[1/5] Installing dependencies..."
sudo apt update -q
sudo apt install -y cec-utils xdotool git

# Install scripts
echo "[2/5] Installing scripts..."
mkdir -p "$HOME_DIR/bin"
cp "$REPO_DIR/scripts/cec-monitor.sh" "$HOME_DIR/bin/cec-monitor.sh"
cp "$REPO_DIR/scripts/low-power.sh"   "$HOME_DIR/bin/low-power.sh"
chmod +x "$HOME_DIR/bin/cec-monitor.sh"
chmod +x "$HOME_DIR/bin/low-power.sh"

# Install homepage
echo "[3/5] Installing homepage..."
mkdir -p "$HOME_DIR/homepage"
cp "$REPO_DIR/homepage/index.html" "$HOME_DIR/homepage/index.html"

# Install autostart entries
echo "[4/5] Installing autostart entries..."
mkdir -p "$HOME_DIR/.config/autostart"
sed "s|YOUR_USERNAME|$USERNAME|g" "$REPO_DIR/autostart/cec-monitor.desktop"     > "$HOME_DIR/.config/autostart/cec-monitor.desktop"
sed "s|YOUR_USERNAME|$USERNAME|g" "$REPO_DIR/autostart/chromium-kiosk.desktop"  > "$HOME_DIR/.config/autostart/chromium-kiosk.desktop"

# Configure Chromium homepage via managed policy
# This makes the home button always return to the local launcher page and
# overrides the default new-tab shortcuts page.
echo "[5/5] Configuring Chromium homepage policy..."
sudo mkdir -p /etc/chromium/policies/managed
sudo tee /etc/chromium/policies/managed/pi-media.json > /dev/null <<EOF
{
  "HomepageLocation": "file://$HOME_DIR/homepage/index.html",
  "HomepageIsNewTabPage": false,
  "ShowHomeButton": true
}
EOF

echo ""
echo "=== Done ==="
echo "Scripts:   $HOME_DIR/bin/"
echo "Homepage:  file://$HOME_DIR/homepage/index.html"
echo ""
echo "Test the CEC monitor manually before relying on autostart:"
echo "  ~/bin/cec-monitor.sh"
echo ""
echo "To diagnose what CEC events your projector sends:"
echo "  ~/bin/cec-monitor.sh --debug"
