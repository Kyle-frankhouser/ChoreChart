#!/bin/bash

###############################################################################
# Ubuntu Zoom Kiosk Setup Script
# This script automates the setup of a dedicated Zoom kiosk on Ubuntu
# 
# Usage: sudo ./setup-zoom-kiosk.sh
#
# Description: Creates a hands-off Zoom meeting room device with automatic
# updates, auto-login, and kiosk mode configuration.
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the actual user (not root, even if using sudo)
ACTUAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(eval echo ~$ACTUAL_USER)

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}Ubuntu Zoom Kiosk Setup Script${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: This script must be run with sudo${NC}"
    echo "Usage: sudo ./setup-zoom-kiosk.sh"
    exit 1
fi

echo -e "${YELLOW}This script will:${NC}"
echo "  - Install Xorg, Openbox, and dependencies"
echo "  - Download and install Zoom"
echo "  - Configure kiosk mode with auto-start"
echo "  - Enable auto-login for user: $ACTUAL_USER"
echo "  - Setup automatic system updates"
echo ""
read -p "Do you want to continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 1
fi

###############################################################################
# Step 1: Update system and install packages
###############################################################################
echo -e "\n${GREEN}[1/8] Updating system and installing packages...${NC}"
apt update
DEBIAN_FRONTEND=noninteractive apt upgrade -y

echo -e "${GREEN}[1/8] Installing required packages...${NC}"
DEBIAN_FRONTEND=noninteractive apt install -y \
    xorg \
    openbox \
    unclutter \
    wget \
    unattended-upgrades \
    pulseaudio \
    wmctrl \
    xterm

###############################################################################
# Step 2: Download and install Zoom
###############################################################################
echo -e "\n${GREEN}[2/8] Downloading and installing Zoom...${NC}"
ZOOM_DEB="/tmp/zoom_amd64.deb"
wget -O "$ZOOM_DEB" https://zoom.us/client/latest/zoom_amd64.deb

echo -e "${GREEN}[2/8] Installing Zoom package...${NC}"
DEBIAN_FRONTEND=noninteractive apt install -y "$ZOOM_DEB" || true
DEBIAN_FRONTEND=noninteractive apt --fix-broken install -y

rm -f "$ZOOM_DEB"

###############################################################################
# Step 3: Configure Openbox autostart
###############################################################################
echo -e "\n${GREEN}[3/8] Configuring Openbox kiosk mode...${NC}"
mkdir -p "$USER_HOME/.config/openbox"

cat > "$USER_HOME/.config/openbox/autostart" << 'EOF'
# Disable screen blanking and power management
xset s off
xset -dpms
xset s noblank

# Hide cursor after inactivity
unclutter -idle 0.1 -root &

# Start PulseAudio
pulseaudio --start &

# Wait a moment for system to stabilize
sleep 2

# Start Zoom
/usr/bin/zoom &

# Watchdog to restart Zoom if it closes (prevents black screen)
(
    while true; do
        sleep 10
        if ! pgrep -x "zoom" > /dev/null; then
            /usr/bin/zoom &
        fi
    done
) &

# Watchdog to auto-restore minimized Zoom windows
(
    sleep 15  # Wait for Zoom to fully start
    while true; do
        sleep 3
        # Find minimized Zoom windows and restore them
        wmctrl -l | grep -i zoom | while read -r line; do
            WIN_ID=$(echo "$line" | awk '{print $1}')
            # Check if window is minimized and restore + maximize it
            xprop -id "$WIN_ID" | grep -q "_NET_WM_STATE_HIDDEN" && \
                wmctrl -i -r "$WIN_ID" -b remove,hidden && \
                wmctrl -i -r "$WIN_ID" -b add,maximized_vert,maximized_horz
        done
    done
) &
EOF

chmod +x "$USER_HOME/.config/openbox/autostart"
chown -R "$ACTUAL_USER:$ACTUAL_USER" "$USER_HOME/.config/openbox"

###############################################################################
# Step 4: Configure X server auto-start
###############################################################################
echo -e "\n${GREEN}[4/8] Configuring X server auto-start...${NC}"

# Create .xinitrc
cat > "$USER_HOME/.xinitrc" << 'EOF'
exec openbox-session
EOF

chown "$ACTUAL_USER:$ACTUAL_USER" "$USER_HOME/.xinitrc"

# Create or append to .bash_profile
if [ -f "$USER_HOME/.bash_profile" ]; then
    # Check if auto-start X is already configured
    if ! grep -q "startx" "$USER_HOME/.bash_profile"; then
        cat >> "$USER_HOME/.bash_profile" << 'EOF'

# Auto-start X server on tty1
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    startx
fi
EOF
    fi
else
    cat > "$USER_HOME/.bash_profile" << 'EOF'
# Auto-start X server on tty1
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    startx
fi
EOF
fi

chown "$ACTUAL_USER:$ACTUAL_USER" "$USER_HOME/.bash_profile"

###############################################################################
# Step 5: Enable auto-login
###############################################################################
echo -e "\n${GREEN}[5/8] Enabling auto-login for $ACTUAL_USER...${NC}"

mkdir -p /etc/systemd/system/getty@tty1.service.d

cat > /etc/systemd/system/getty@tty1.service.d/override.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $ACTUAL_USER --noclear %I \$TERM
EOF

systemctl daemon-reload

###############################################################################
# Step 6: Configure automatic updates
###############################################################################
echo -e "\n${GREEN}[6/8] Configuring automatic updates...${NC}"

# Enable unattended upgrades non-interactively
echo unattended-upgrades unattended-upgrades/enable_auto_updates boolean true | debconf-set-selections
dpkg-reconfigure -f noninteractive unattended-upgrades

# Configure automatic reboots
cat > /etc/apt/apt.conf.d/52custom-unattended-upgrades << 'EOF'
// Enable automatic reboot if required
Unattended-Upgrade::Automatic-Reboot "true";

// Reboot at 2 AM
Unattended-Upgrade::Automatic-Reboot-Time "02:00";

// Remove unused dependencies
Unattended-Upgrade::Remove-Unused-Dependencies "true";

// Remove unused kernel packages
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
EOF

# Ensure auto-upgrades are configured
cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Download-Upgradeable-Packages "1";
EOF

###############################################################################
# Step 7: Disable problematic Openbox keybindings (optional security)
###############################################################################
echo -e "\n${GREEN}[7/8] Securing Openbox keybindings...${NC}"

if [ ! -f "$USER_HOME/.config/openbox/rc.xml" ]; then
    cp /etc/xdg/openbox/rc.xml "$USER_HOME/.config/openbox/rc.xml"
    chown "$ACTUAL_USER:$ACTUAL_USER" "$USER_HOME/.config/openbox/rc.xml"
fi

# Remove dangerous keybindings (Alt+F4 and Ctrl+Alt+Delete)
# Using a more robust approach with perl for multi-line XML blocks
perl -i -0pe 's/<keybind key="A-F4">.*?<\/keybind>//gs' "$USER_HOME/.config/openbox/rc.xml"
perl -i -0pe 's/<keybind key="C-A-Delete">.*?<\/keybind>//gs' "$USER_HOME/.config/openbox/rc.xml"

# Add keybinding for terminal (Ctrl+Alt+T) and window restore (Super+Up)
perl -i -pe 's|</keyboard>|  <keybind key="C-A-t">
    <action name="Execute">
      <command>xterm -maximized -fa "Monospace" -fs 12</command>
    </action>
  </keybind>
  <keybind key="W-Up">
    <action name="Maximize"/>
  </keybind>
  <keybind key="W-Return">
    <action name="ToggleMaximize"/>
  </keybind>
</keyboard>|' "$USER_HOME/.config/openbox/rc.xml"

# Disable window decorations globally for kiosk mode
perl -i -pe 's|<keepBorder>.*</keepBorder>|<keepBorder>no</keepBorder>|' "$USER_HOME/.config/openbox/rc.xml"
perl -i -pe 's|<theme>|<theme>\n    <titleLayout></titleLayout>|' "$USER_HOME/.config/openbox/rc.xml" || true

# Add Zoom-specific window rules for kiosk behavior
echo -e "${GREEN}[7/8] Configuring Zoom window rules...${NC}"

# Insert Zoom application rules before closing </openbox_config> tag
perl -i -pe 's|</openbox_config>|  <applications>
    <application class="zoom">
      <!-- Force maximized state -->
      <maximized>yes</maximized>
      <!-- Remove window decorations -->
      <decor>no</decor>
      <!-- Always focus Zoom windows -->
      <focus>yes</focus>
    </application>
    <application class="*">
      <!-- Remove decorations from all windows -->
      <decor>no</decor>
    </application>
  </applications>
</openbox_config>|' "$USER_HOME/.config/openbox/rc.xml" 2>/dev/null || true

###############################################################################
# Step 8: Enable SSH for remote management
###############################################################################
echo -e "\n${GREEN}[8/8] Enabling SSH for remote management...${NC}"

systemctl enable ssh
systemctl start ssh

###############################################################################
# Final steps and information
###############################################################################
echo -e "\n${GREEN}=====================================${NC}"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""
echo -e "${YELLOW}Configuration Summary:${NC}"
echo "  User: $ACTUAL_USER"
echo "  Home: $USER_HOME"
echo "  Auto-login: Enabled"
echo "  Automatic updates: Enabled (reboots at 2:00 AM if needed)"
echo "  SSH: Enabled"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "  1. Reboot the system: sudo reboot"
echo "  2. System will auto-login and start Zoom"
echo "  3. Sign in to your Zoom account on first boot"
echo ""
echo -e "${YELLOW}Remote Management:${NC}"
IP_ADDR=$(hostname -I | awk '{print $1}')
if [ -n "$IP_ADDR" ]; then
    echo "  SSH access: ssh $ACTUAL_USER@$IP_ADDR"
else
    echo "  SSH access: ssh $ACTUAL_USER@<IP_ADDRESS>"
fi
echo ""
echo -e "${YELLOW}Maintenance Commands:${NC}"
echo "  Check update logs: cat /var/log/unattended-upgrades/unattended-upgrades.log"
echo "  Force update check: sudo unattended-upgrade -d"
echo "  Check system errors: cat ~/.xsession-errors"
echo ""
echo -e "${YELLOW}Local Access:${NC}"
echo "  Open terminal in kiosk: Press Ctrl+Alt+T"
echo "  Restore/maximize window: Press Super+Up or Super+Enter"
echo "  Switch to text console: Press Ctrl+Alt+F2 (F1 to return)"
echo ""
echo -e "${GREEN}Reboot now? (y/n)${NC}"
read -p "" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Rebooting..."
    reboot
else
    echo "Remember to reboot before the kiosk will function properly."
fi