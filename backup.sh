#!/bin/bash

# Linux Mint Cinnamon Settings Backup Script
# This script backs up your customized Cinnamon desktop environment settings

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Linux Mint Cinnamon Backup Script ===${NC}"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/backup_$(date +%Y%m%d_%H%M%S)"

echo -e "${GREEN}Creating backup in: ${BACKUP_DIR}${NC}"
mkdir -p "$BACKUP_DIR"

# Function to backup with progress
backup_item() {
    local source="$1"
    local dest="$2"
    local name="$3"
    
    if [ -e "$source" ]; then
        echo -e "${BLUE}Backing up ${name}...${NC}"
        mkdir -p "$(dirname "$dest")"
        cp -r "$source" "$dest"
        echo -e "${GREEN}✓ ${name} backed up${NC}"
    else
        echo -e "${YELLOW}⊘ ${name} not found, skipping${NC}"
    fi
}

# 1. Backup Cinnamon dconf settings
echo -e "\n${BLUE}=== Backing up Cinnamon Settings ===${NC}"
dconf dump /org/cinnamon/ > "$BACKUP_DIR/cinnamon-settings.dconf"
echo -e "${GREEN}✓ Cinnamon dconf settings backed up${NC}"

# 2. Backup Nemo (file manager) settings
echo -e "\n${BLUE}=== Backing up Nemo Settings ===${NC}"
dconf dump /org/nemo/ > "$BACKUP_DIR/nemo-settings.dconf"
echo -e "${GREEN}✓ Nemo settings backed up${NC}"

# 3. Backup GTK settings
backup_item "$HOME/.config/gtk-3.0" "$BACKUP_DIR/config/gtk-3.0" "GTK 3.0 settings"
backup_item "$HOME/.config/gtk-4.0" "$BACKUP_DIR/config/gtk-4.0" "GTK 4.0 settings"
backup_item "$HOME/.gtkrc-2.0" "$BACKUP_DIR/gtkrc-2.0" "GTK 2.0 settings"

# 4. Backup Cinnamon specific configs
echo -e "\n${BLUE}=== Backing up Cinnamon Configurations ===${NC}"
backup_item "$HOME/.cinnamon" "$BACKUP_DIR/cinnamon" "Cinnamon configs"
backup_item "$HOME/.local/share/cinnamon" "$BACKUP_DIR/local/share/cinnamon" "Cinnamon data"

# 5. Backup themes, icons, and cursors
echo -e "\n${BLUE}=== Backing up Themes and Icons ===${NC}"
backup_item "$HOME/.themes" "$BACKUP_DIR/themes" "User themes"
backup_item "$HOME/.icons" "$BACKUP_DIR/icons" "User icons"
backup_item "$HOME/.local/share/themes" "$BACKUP_DIR/local/share/themes" "Local themes"
backup_item "$HOME/.local/share/icons" "$BACKUP_DIR/local/share/icons" "Local icons"

# 6. Backup fonts
backup_item "$HOME/.fonts" "$BACKUP_DIR/fonts" "User fonts"
backup_item "$HOME/.local/share/fonts" "$BACKUP_DIR/local/share/fonts" "Local fonts"

# 7. Backup desktop background/wallpaper info
echo -e "\n${BLUE}=== Backing up Desktop Settings ===${NC}"
backup_item "$HOME/.config/monitors.xml" "$BACKUP_DIR/config/monitors.xml" "Monitor settings"

# 8. Backup application launchers and menu
backup_item "$HOME/.local/share/applications" "$BACKUP_DIR/local/share/applications" "Application launchers"

# 9. Backup Plank (if used)
backup_item "$HOME/.config/plank" "$BACKUP_DIR/config/plank" "Plank dock settings"

# 10. Backup keyboard shortcuts and input methods
backup_item "$HOME/.config/autostart" "$BACKUP_DIR/config/autostart" "Autostart applications"

# 11. Backup terminal settings (gnome-terminal or other)
dconf dump /org/gnome/terminal/ > "$BACKUP_DIR/gnome-terminal-settings.dconf" 2>/dev/null || echo -e "${YELLOW}⊘ GNOME Terminal settings not found${NC}"

# 12. Save list of installed packages
echo -e "\n${BLUE}=== Saving Package List ===${NC}"
dpkg --get-selections > "$BACKUP_DIR/package-list.txt"
apt-mark showmanual > "$BACKUP_DIR/manually-installed-packages.txt"
echo -e "${GREEN}✓ Package lists saved${NC}"

# 13. Save Cinnamon extensions and applets list
echo -e "\n${BLUE}=== Saving Extension/Applet List ===${NC}"
if [ -d "$HOME/.local/share/cinnamon/extensions" ]; then
    ls "$HOME/.local/share/cinnamon/extensions" > "$BACKUP_DIR/installed-extensions.txt"
    echo -e "${GREEN}✓ Extensions list saved${NC}"
    
    # Save spices extension UUIDs for automated reinstall
    ls "$HOME/.local/share/cinnamon/extensions" > "$BACKUP_DIR/spices-extensions.txt"
fi
if [ -d "$HOME/.local/share/cinnamon/applets" ]; then
    ls "$HOME/.local/share/cinnamon/applets" > "$BACKUP_DIR/installed-applets.txt"
    echo -e "${GREEN}✓ Applets list saved${NC}"
    
    # Save spices applet UUIDs for automated reinstall
    ls "$HOME/.local/share/cinnamon/applets" > "$BACKUP_DIR/spices-applets.txt"
fi

# 14. Save PPAs and repositories
echo -e "\n${BLUE}=== Saving PPAs and Repositories ===${NC}"
if [ -d "/etc/apt/sources.list.d" ]; then
    # Extract PPA information from sources
    grep -rh "^deb .*ppa\.launchpad" /etc/apt/sources.list.d/ 2>/dev/null | \
        sed 's/deb http.*\/\(.*\)\/ubuntu.*/ppa:\1/' | \
        sort -u > "$BACKUP_DIR/ppas.list" 2>/dev/null || touch "$BACKUP_DIR/ppas.list"
    
    if [ -s "$BACKUP_DIR/ppas.list" ]; then
        echo -e "${GREEN}✓ PPAs saved ($(wc -l < "$BACKUP_DIR/ppas.list") PPAs)${NC}"
    else
        echo -e "${YELLOW}⊘ No PPAs found${NC}"
    fi
fi

# 15. Save Flatpak applications
echo -e "\n${BLUE}=== Saving Flatpak Applications ===${NC}"
if command -v flatpak &> /dev/null; then
    flatpak list --app --columns=application 2>/dev/null > "$BACKUP_DIR/flatpak-list.txt" || touch "$BACKUP_DIR/flatpak-list.txt"
    if [ -s "$BACKUP_DIR/flatpak-list.txt" ]; then
        echo -e "${GREEN}✓ Flatpak list saved ($(wc -l < "$BACKUP_DIR/flatpak-list.txt") apps)${NC}"
    else
        echo -e "${YELLOW}⊘ No Flatpak applications found${NC}"
    fi
else
    echo -e "${YELLOW}⊘ Flatpak not installed${NC}"
    touch "$BACKUP_DIR/flatpak-list.txt"
fi

# 16. Save Snap applications (optional)
echo -e "\n${BLUE}=== Saving Snap Applications ===${NC}"
if command -v snap &> /dev/null; then
    snap list 2>/dev/null | tail -n +2 | awk '{print $1}' > "$BACKUP_DIR/snap-list.txt" || touch "$BACKUP_DIR/snap-list.txt"
    if [ -s "$BACKUP_DIR/snap-list.txt" ]; then
        echo -e "${GREEN}✓ Snap list saved ($(wc -l < "$BACKUP_DIR/snap-list.txt") snaps)${NC}"
    else
        echo -e "${YELLOW}⊘ No Snap applications found${NC}"
    fi
else
    echo -e "${YELLOW}⊘ Snap not installed${NC}"
    touch "$BACKUP_DIR/snap-list.txt"
fi

# 17. Save VS Code extensions and settings
echo -e "\n${BLUE}=== Saving VS Code Configuration ===${NC}"
if command -v code &> /dev/null; then
    code --list-extensions > "$BACKUP_DIR/vscode-extensions.txt" 2>/dev/null || touch "$BACKUP_DIR/vscode-extensions.txt"
    if [ -s "$BACKUP_DIR/vscode-extensions.txt" ]; then
        echo -e "${GREEN}✓ VS Code extensions saved ($(wc -l < "$BACKUP_DIR/vscode-extensions.txt") extensions)${NC}"
    fi
    
    # Backup VS Code settings
    if [ -f "$HOME/.config/Code/User/settings.json" ]; then
        cp "$HOME/.config/Code/User/settings.json" "$BACKUP_DIR/vscode-settings.json"
        echo -e "${GREEN}✓ VS Code settings saved${NC}"
    fi
else
    echo -e "${YELLOW}⊘ VS Code not installed${NC}"
fi

# 18. Save Git configuration
echo -e "\n${BLUE}=== Saving Git Configuration ===${NC}"
if [ -f "$HOME/.gitconfig" ]; then
    cp "$HOME/.gitconfig" "$BACKUP_DIR/gitconfig"
    echo -e "${GREEN}✓ Git config saved${NC}"
else
    echo -e "${YELLOW}⊘ No .gitconfig found${NC}"
fi

# 19. Save custom bash/zsh configurations
echo -e "\n${BLUE}=== Saving Shell Customizations ===${NC}"
if [ -f "$HOME/.bashrc" ]; then
    # Extract custom additions (after "# User customizations" marker if exists)
    if grep -q "# User customizations" "$HOME/.bashrc"; then
        sed -n '/# User customizations/,$p' "$HOME/.bashrc" > "$BACKUP_DIR/bashrc-custom"
        echo -e "${GREEN}✓ Custom bashrc saved${NC}"
    else
        echo -e "${YELLOW}⊘ No custom bashrc marker found${NC}"
        echo -e "${YELLOW}   Tip: Add '# User customizations' before your custom bash additions${NC}"
    fi
fi

# 14. Create a restore script
echo -e "\n${BLUE}=== Creating Restore Script ===${NC}"

# Copy the fresh install setup script
if [ -f "$SCRIPT_DIR/fresh-install-setup.sh" ]; then
    cp "$SCRIPT_DIR/fresh-install-setup.sh" "$BACKUP_DIR/fresh-install-setup.sh"
    chmod +x "$BACKUP_DIR/fresh-install-setup.sh"
    echo -e "${GREEN}✓ Fresh install setup script copied${NC}"
fi

# Copy system tweaks script
if [ -f "$SCRIPT_DIR/system-tweaks.sh" ]; then
    cp "$SCRIPT_DIR/system-tweaks.sh" "$BACKUP_DIR/system-tweaks.sh"
    chmod +x "$BACKUP_DIR/system-tweaks.sh"
    echo -e "${GREEN}✓ System tweaks script copied${NC}"
fi

# Copy setup config script
if [ -f "$SCRIPT_DIR/setup-config.sh" ]; then
    cp "$SCRIPT_DIR/setup-config.sh" "$BACKUP_DIR/setup-config.sh"
    chmod +x "$BACKUP_DIR/setup-config.sh"
    echo -e "${GREEN}✓ Setup config script copied${NC}"
fi

# Create the basic restore script
cat > "$BACKUP_DIR/restore.sh" << 'RESTORE_SCRIPT'
#!/bin/bash

# Linux Mint Cinnamon Settings Restore Script

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Linux Mint Cinnamon Restore Script ===${NC}"
echo ""
echo -e "${YELLOW}WARNING: This will overwrite your current Cinnamon settings!${NC}"
echo -e "${YELLOW}It's recommended to backup your current settings first.${NC}"
echo ""
read -p "Do you want to continue? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Restore cancelled."
    exit 0
fi

BACKUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

restore_item() {
    local source="$1"
    local dest="$2"
    local name="$3"
    
    if [ -e "$source" ]; then
        echo -e "${BLUE}Restoring ${name}...${NC}"
        mkdir -p "$(dirname "$dest")"
        cp -r "$source" "$dest"
        echo -e "${GREEN}✓ ${name} restored${NC}"
    else
        echo -e "${YELLOW}⊘ ${name} backup not found, skipping${NC}"
    fi
}

# Restore dconf settings
echo -e "\n${BLUE}=== Restoring Cinnamon Settings ===${NC}"
if [ -f "$BACKUP_DIR/cinnamon-settings.dconf" ]; then
    dconf load /org/cinnamon/ < "$BACKUP_DIR/cinnamon-settings.dconf"
    echo -e "${GREEN}✓ Cinnamon settings restored${NC}"
fi

if [ -f "$BACKUP_DIR/nemo-settings.dconf" ]; then
    dconf load /org/nemo/ < "$BACKUP_DIR/nemo-settings.dconf"
    echo -e "${GREEN}✓ Nemo settings restored${NC}"
fi

if [ -f "$BACKUP_DIR/gnome-terminal-settings.dconf" ]; then
    dconf load /org/gnome/terminal/ < "$BACKUP_DIR/gnome-terminal-settings.dconf"
    echo -e "${GREEN}✓ Terminal settings restored${NC}"
fi

# Restore configs
restore_item "$BACKUP_DIR/config/gtk-3.0" "$HOME/.config/gtk-3.0" "GTK 3.0 settings"
restore_item "$BACKUP_DIR/config/gtk-4.0" "$HOME/.config/gtk-4.0" "GTK 4.0 settings"
restore_item "$BACKUP_DIR/gtkrc-2.0" "$HOME/.gtkrc-2.0" "GTK 2.0 settings"
restore_item "$BACKUP_DIR/cinnamon" "$HOME/.cinnamon" "Cinnamon configs"
restore_item "$BACKUP_DIR/local/share/cinnamon" "$HOME/.local/share/cinnamon" "Cinnamon data"

# Restore themes and icons
echo -e "\n${BLUE}=== Restoring Themes and Icons ===${NC}"
restore_item "$BACKUP_DIR/themes" "$HOME/.themes" "User themes"
restore_item "$BACKUP_DIR/icons" "$HOME/.icons" "User icons"
restore_item "$BACKUP_DIR/local/share/themes" "$HOME/.local/share/themes" "Local themes"
restore_item "$BACKUP_DIR/local/share/icons" "$HOME/.local/share/icons" "Local icons"

# Restore fonts
restore_item "$BACKUP_DIR/fonts" "$HOME/.fonts" "User fonts"
restore_item "$BACKUP_DIR/local/share/fonts" "$HOME/.local/share/fonts" "Local fonts"

# Update font cache
if [ -d "$HOME/.fonts" ] || [ -d "$HOME/.local/share/fonts" ]; then
    echo -e "${BLUE}Updating font cache...${NC}"
    fc-cache -f
    echo -e "${GREEN}✓ Font cache updated${NC}"
fi

# Restore other settings
restore_item "$BACKUP_DIR/config/monitors.xml" "$HOME/.config/monitors.xml" "Monitor settings"
restore_item "$BACKUP_DIR/local/share/applications" "$HOME/.local/share/applications" "Application launchers"
restore_item "$BACKUP_DIR/config/plank" "$HOME/.config/plank" "Plank dock settings"
restore_item "$BACKUP_DIR/config/autostart" "$HOME/.config/autostart" "Autostart applications"

# Update desktop database
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

echo -e "\n${GREEN}=== Restore Complete ===${NC}"
echo -e "${YELLOW}Please log out and log back in for all changes to take effect.${NC}"
echo ""
echo -e "Optional: Review the following files for packages to install:"
echo -e "  - ${BLUE}package-list.txt${NC} (all packages)"
echo -e "  - ${BLUE}manually-installed-packages.txt${NC} (manually installed)"
echo -e "  - ${BLUE}installed-extensions.txt${NC} (Cinnamon extensions)"
echo -e "  - ${BLUE}installed-applets.txt${NC} (Cinnamon applets)"
RESTORE_SCRIPT

chmod +x "$BACKUP_DIR/restore.sh"
echo -e "${GREEN}✓ Restore script created${NC}"

# Create a README
cat > "$BACKUP_DIR/README.txt" << 'README'
Linux Mint Cinnamon Settings Backup
====================================

This backup was created using the backup.sh script.

Contents:
---------
- cinnamon-settings.dconf: Cinnamon desktop settings
- nemo-settings.dconf: File manager settings
- gnome-terminal-settings.dconf: Terminal settings
- config/: Various configuration files
- themes/: Custom themes
- icons/: Custom icons
- fonts/: Custom fonts
- package-list.txt: List of all installed packages
- manually-installed-packages.txt: List of manually installed packages
- installed-extensions.txt: List of installed Cinnamon extensions
- installed-applets.txt: List of installed Cinnamon applets

How to Restore:
--------------
1. Copy this entire backup folder to your new computer
2. Run: ./restore.sh
3. Log out and log back in

Note: The restore script will NOT automatically install packages.
Review the package list files and install needed packages manually:
  sudo apt install <package-name>

For Cinnamon extensions and applets, you may need to reinstall them
through the System Settings > Extensions/Applets interface.
README

echo -e "${GREEN}✓ README created${NC}"

# Create summary
echo ""
echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN}Backup completed successfully!${NC}"
echo -e "${GREEN}==================================================${NC}"
echo ""
echo -e "Backup location: ${BLUE}$BACKUP_DIR${NC}"
echo ""
echo -e "To restore on another computer:"
echo -e "  1. Copy the backup folder to the target computer"
echo -e "  2. Run: ${BLUE}cd $(basename $BACKUP_DIR) && ./restore.sh${NC}"
echo -e "  3. Log out and log back in"
echo ""
