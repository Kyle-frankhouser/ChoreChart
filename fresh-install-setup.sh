#!/bin/bash

# Linux Mint Fresh Install Automated Setup Script
# Run this script on a fresh Linux Mint installation to set up your complete environment

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Linux Mint Fresh Install Automated Setup Script     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}This script will:${NC}"
echo -e "  1. Update system packages"
echo -e "  2. Add necessary PPAs and repositories"
echo -e "  3. Install your applications and packages"
echo -e "  4. Install Flatpaks and Snaps (if configured)"
echo -e "  5. Install Cinnamon extensions and applets"
echo -e "  6. Restore all your settings and themes"
echo -e "  7. Configure optional developer tools (git, SSH, etc.)"
echo ""
echo -e "${YELLOW}This may take 15-30 minutes depending on your internet speed.${NC}"
echo ""
read -p "Do you want to continue? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Setup cancelled."
    exit 0
fi

# Log file
LOG_FILE="$SCRIPT_DIR/setup_$(date +%Y%m%d_%H%M%S).log"
exec 1> >(tee -a "$LOG_FILE")
exec 2>&1

echo -e "\n${BLUE}=== Starting Setup at $(date) ===${NC}\n"

# Check if running with sudo
if [ "$EUID" -eq 0 ]; then 
    echo -e "${RED}ERROR: Do not run this script with sudo!${NC}"
    echo -e "${YELLOW}The script will ask for sudo password when needed.${NC}"
    exit 1
fi

# ============================================================================
# STEP 1: System Update
# ============================================================================
echo -e "\n${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  STEP 1: Updating System Packages                     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}\n"

sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y

echo -e "${GREEN}✓ System updated${NC}"

# ============================================================================
# STEP 2: Add PPAs and Repositories
# ============================================================================
echo -e "\n${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  STEP 2: Adding PPAs and Repositories                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}\n"

if [ -f "$SCRIPT_DIR/ppas.list" ]; then
    echo -e "${BLUE}Installing saved PPAs...${NC}"
    while IFS= read -r ppa; do
        # Skip comments and empty lines
        [[ "$ppa" =~ ^#.*$ || -z "$ppa" ]] && continue
        echo -e "${BLUE}Adding PPA: $ppa${NC}"
        sudo add-apt-repository -y "$ppa" || echo -e "${YELLOW}⊘ Failed to add $ppa${NC}"
    done < "$SCRIPT_DIR/ppas.list"
    sudo apt update
    echo -e "${GREEN}✓ PPAs added${NC}"
else
    echo -e "${YELLOW}⊘ No ppas.list found, skipping${NC}"
fi

# Add Flatpak support (if not already installed)
if ! command -v flatpak &> /dev/null; then
    echo -e "${BLUE}Installing Flatpak...${NC}"
    sudo apt install -y flatpak
    echo -e "${GREEN}✓ Flatpak installed${NC}"
fi

# Add Flathub repository
if ! flatpak remote-list | grep -q flathub; then
    echo -e "${BLUE}Adding Flathub repository...${NC}"
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    echo -e "${GREEN}✓ Flathub added${NC}"
fi

# ============================================================================
# STEP 3: Install Packages
# ============================================================================
echo -e "\n${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  STEP 3: Installing Packages                          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}\n"

# Install essential build tools first
echo -e "${BLUE}Installing essential build tools...${NC}"
sudo apt install -y build-essential git curl wget software-properties-common

if [ -f "$SCRIPT_DIR/manually-installed-packages.txt" ]; then
    echo -e "${BLUE}Installing manually installed packages...${NC}"
    echo -e "${YELLOW}This may take several minutes...${NC}"
    
    # Read packages and filter out any that might cause issues
    packages=$(cat "$SCRIPT_DIR/manually-installed-packages.txt" | grep -v "^#" | tr '\n' ' ')
    
    # Install packages (continue on error for individual packages)
    for package in $packages; do
        echo -e "${BLUE}Installing: $package${NC}"
        sudo apt install -y "$package" || echo -e "${YELLOW}⊘ Could not install $package${NC}"
    done
    
    echo -e "${GREEN}✓ Packages installed${NC}"
else
    echo -e "${YELLOW}⊘ No manually-installed-packages.txt found${NC}"
fi

# ============================================================================
# STEP 4: Install Flatpaks
# ============================================================================
echo -e "\n${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  STEP 4: Installing Flatpak Applications              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}\n"

if [ -f "$SCRIPT_DIR/flatpak-list.txt" ]; then
    echo -e "${BLUE}Installing Flatpak applications...${NC}"
    while IFS= read -r app; do
        [[ "$app" =~ ^#.*$ || -z "$app" ]] && continue
        echo -e "${BLUE}Installing: $app${NC}"
        flatpak install -y flathub "$app" || echo -e "${YELLOW}⊘ Could not install $app${NC}"
    done < "$SCRIPT_DIR/flatpak-list.txt"
    echo -e "${GREEN}✓ Flatpaks installed${NC}"
else
    echo -e "${YELLOW}⊘ No flatpak-list.txt found, skipping${NC}"
fi

# ============================================================================
# STEP 5: Install Cinnamon Extensions and Applets
# ============================================================================
echo -e "\n${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  STEP 5: Installing Cinnamon Extensions & Applets     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}\n"

# Function to download and install Cinnamon spices
install_spice() {
    local type=$1  # extension, applet, or desklet
    local uuid=$2
    local url="https://cinnamon-spices.linuxmint.com/files/${type}s/${uuid}.zip"
    local install_dir="$HOME/.local/share/cinnamon/${type}s"
    
    echo -e "${BLUE}Installing ${type}: $uuid${NC}"
    
    # Create temp directory
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # Download and extract
    if wget -q "$url" -O "${uuid}.zip"; then
        unzip -q "${uuid}.zip"
        mkdir -p "$install_dir"
        mv "$uuid" "$install_dir/"
        echo -e "${GREEN}✓ Installed $uuid${NC}"
    else
        echo -e "${YELLOW}⊘ Could not download $uuid${NC}"
    fi
    
    cd - > /dev/null
    rm -rf "$temp_dir"
}

# Install extensions from spices-extensions.txt
if [ -f "$SCRIPT_DIR/spices-extensions.txt" ]; then
    while IFS= read -r uuid; do
        [[ "$uuid" =~ ^#.*$ || -z "$uuid" ]] && continue
        install_spice "extension" "$uuid"
    done < "$SCRIPT_DIR/spices-extensions.txt"
fi

# Install applets from spices-applets.txt
if [ -f "$SCRIPT_DIR/spices-applets.txt" ]; then
    while IFS= read -r uuid; do
        [[ "$uuid" =~ ^#.*$ || -z "$uuid" ]] && continue
        install_spice "applet" "$uuid"
    done < "$SCRIPT_DIR/spices-applets.txt"
fi

# If extensions/applets are backed up in local/share/cinnamon, they'll be restored in step 6

# ============================================================================
# STEP 6: Restore Settings and Themes
# ============================================================================
echo -e "\n${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  STEP 6: Restoring Settings and Themes                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}\n"

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
if [ -f "$SCRIPT_DIR/cinnamon-settings.dconf" ]; then
    dconf load /org/cinnamon/ < "$SCRIPT_DIR/cinnamon-settings.dconf"
    echo -e "${GREEN}✓ Cinnamon settings restored${NC}"
fi

if [ -f "$SCRIPT_DIR/nemo-settings.dconf" ]; then
    dconf load /org/nemo/ < "$SCRIPT_DIR/nemo-settings.dconf"
    echo -e "${GREEN}✓ Nemo settings restored${NC}"
fi

if [ -f "$SCRIPT_DIR/gnome-terminal-settings.dconf" ]; then
    dconf load /org/gnome/terminal/ < "$SCRIPT_DIR/gnome-terminal-settings.dconf"
    echo -e "${GREEN}✓ Terminal settings restored${NC}"
fi

# Restore configs
restore_item "$SCRIPT_DIR/config/gtk-3.0" "$HOME/.config/gtk-3.0" "GTK 3.0 settings"
restore_item "$SCRIPT_DIR/config/gtk-4.0" "$HOME/.config/gtk-4.0" "GTK 4.0 settings"
restore_item "$SCRIPT_DIR/gtkrc-2.0" "$HOME/.gtkrc-2.0" "GTK 2.0 settings"
restore_item "$SCRIPT_DIR/cinnamon" "$HOME/.cinnamon" "Cinnamon configs"
restore_item "$SCRIPT_DIR/local/share/cinnamon" "$HOME/.local/share/cinnamon" "Cinnamon data"

# Restore themes and icons
restore_item "$SCRIPT_DIR/themes" "$HOME/.themes" "User themes"
restore_item "$SCRIPT_DIR/icons" "$HOME/.icons" "User icons"
restore_item "$SCRIPT_DIR/local/share/themes" "$HOME/.local/share/themes" "Local themes"
restore_item "$SCRIPT_DIR/local/share/icons" "$HOME/.local/share/icons" "Local icons"

# Restore fonts
restore_item "$SCRIPT_DIR/fonts" "$HOME/.fonts" "User fonts"
restore_item "$SCRIPT_DIR/local/share/fonts" "$HOME/.local/share/fonts" "Local fonts"

# Update font cache
if [ -d "$HOME/.fonts" ] || [ -d "$HOME/.local/share/fonts" ]; then
    echo -e "${BLUE}Updating font cache...${NC}"
    fc-cache -f
    echo -e "${GREEN}✓ Font cache updated${NC}"
fi

# Restore other settings
restore_item "$SCRIPT_DIR/config/monitors.xml" "$HOME/.config/monitors.xml" "Monitor settings"
restore_item "$SCRIPT_DIR/local/share/applications" "$HOME/.local/share/applications" "Application launchers"
restore_item "$SCRIPT_DIR/config/plank" "$HOME/.config/plank" "Plank dock settings"
restore_item "$SCRIPT_DIR/config/autostart" "$HOME/.config/autostart" "Autostart applications"

# Update desktop database
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

# ============================================================================
# STEP 7: Optional Developer Tools Setup
# ============================================================================
echo -e "\n${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  STEP 7: Optional Developer Tools Configuration       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}\n"

# Git configuration
if [ -f "$SCRIPT_DIR/gitconfig" ]; then
    echo -e "${BLUE}Restoring Git configuration...${NC}"
    cp "$SCRIPT_DIR/gitconfig" "$HOME/.gitconfig"
    echo -e "${GREEN}✓ Git config restored${NC}"
else
    echo -e "${YELLOW}Configure Git? (Skip if not needed)${NC}"
    read -p "Enter your Git name (or press Enter to skip): " git_name
    if [ -n "$git_name" ]; then
        read -p "Enter your Git email: " git_email
        git config --global user.name "$git_name"
        git config --global user.email "$git_email"
        git config --global init.defaultBranch main
        git config --global pull.rebase false
        echo -e "${GREEN}✓ Git configured${NC}"
    fi
fi

# SSH key setup
echo -e "\n${YELLOW}SSH Key Setup${NC}"
if [ -f "$HOME/.ssh/id_ed25519" ] || [ -f "$HOME/.ssh/id_rsa" ]; then
    echo -e "${GREEN}✓ SSH keys already exist${NC}"
else
    read -p "Generate new SSH key? (yes/no): " -r
    if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        read -p "Enter email for SSH key: " ssh_email
        ssh-keygen -t ed25519 -C "$ssh_email" -f "$HOME/.ssh/id_ed25519"
        eval "$(ssh-agent -s)"
        ssh-add "$HOME/.ssh/id_ed25519"
        echo -e "${GREEN}✓ SSH key generated${NC}"
        echo -e "${BLUE}Your public key:${NC}"
        cat "$HOME/.ssh/id_ed25519.pub"
    fi
fi

# Restore bashrc/zshrc customizations
if [ -f "$SCRIPT_DIR/bashrc-custom" ]; then
    echo -e "${BLUE}Restoring bash customizations...${NC}"
    cat "$SCRIPT_DIR/bashrc-custom" >> "$HOME/.bashrc"
    echo -e "${GREEN}✓ Bash customizations restored${NC}"
fi

# VS Code extensions
if command -v code &> /dev/null && [ -f "$SCRIPT_DIR/vscode-extensions.txt" ]; then
    echo -e "${BLUE}Installing VS Code extensions...${NC}"
    while IFS= read -r extension; do
        [[ "$extension" =~ ^#.*$ || -z "$extension" ]] && continue
        echo -e "${BLUE}Installing: $extension${NC}"
        code --install-extension "$extension" || true
    done < "$SCRIPT_DIR/vscode-extensions.txt"
    echo -e "${GREEN}✓ VS Code extensions installed${NC}"
fi

# Restore VS Code settings
if [ -f "$SCRIPT_DIR/vscode-settings.json" ]; then
    mkdir -p "$HOME/.config/Code/User"
    cp "$SCRIPT_DIR/vscode-settings.json" "$HOME/.config/Code/User/settings.json"
    echo -e "${GREEN}✓ VS Code settings restored${NC}"
fi

# ============================================================================
# STEP 8: System Tweaks (Optional)
# ============================================================================
echo -e "\n${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  STEP 8: System Tweaks (Optional)                     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}\n"

if [ -f "$SCRIPT_DIR/system-tweaks.sh" ]; then
    echo -e "${YELLOW}Found system-tweaks.sh${NC}"
    read -p "Apply system tweaks? (yes/no): " -r
    if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        bash "$SCRIPT_DIR/system-tweaks.sh"
        echo -e "${GREEN}✓ System tweaks applied${NC}"
    fi
else
    echo -e "${YELLOW}⊘ No system-tweaks.sh found, skipping${NC}"
fi

# ============================================================================
# STEP 9: Final Steps
# ============================================================================
echo -e "\n${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  STEP 9: Final Cleanup                                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}\n"

# Clean up package cache
sudo apt autoremove -y
sudo apt autoclean

# Restart Cinnamon to apply all changes
echo -e "${BLUE}Restarting Cinnamon to apply changes...${NC}"
nohup cinnamon --replace &> /dev/null &
sleep 2

# ============================================================================
# COMPLETION
# ============================================================================
echo -e "\n${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                  SETUP COMPLETE! 🎉                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${BLUE}Setup completed at $(date)${NC}"
echo -e "${BLUE}Log file: ${LOG_FILE}${NC}\n"

echo -e "${YELLOW}Next Steps:${NC}"
echo -e "  1. ${GREEN}Log out and log back in${NC} for all changes to take effect"
echo -e "  2. Review installed applications in the Menu"
echo -e "  3. Check Cinnamon extensions in System Settings"
echo -e "  4. Verify panel applets are working correctly"
echo ""
echo -e "${GREEN}Your Linux Mint system is now configured with your preferences!${NC}\n"
