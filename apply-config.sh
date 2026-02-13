#!/bin/bash

# Apply System Configuration from JSON
# This script reads system-config.json and applies all settings

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${1:-$SCRIPT_DIR/system-config.json}"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}Installing jq (JSON parser)...${NC}"
    sudo apt update && sudo apt install -y jq
fi

# Validate JSON
if ! jq empty "$CONFIG_FILE" 2>/dev/null; then
    echo -e "${RED}ERROR: Invalid JSON in $CONFIG_FILE${NC}"
    exit 1
fi

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Applying System Configuration from JSON           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Config file: ${CONFIG_FILE}${NC}"
echo -e "${BLUE}Name: $(jq -r '.metadata.name' "$CONFIG_FILE")${NC}"
echo -e "${BLUE}Description: $(jq -r '.metadata.description' "$CONFIG_FILE")${NC}"
echo ""

read -p "Apply this configuration? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# ============================================================================
# STEP 1: System Update
# ============================================================================
echo -e "\n${BLUE}=== Step 1: System Update ===${NC}"
sudo apt update
sudo apt upgrade -y
echo -e "${GREEN}✓ System updated${NC}"

# ============================================================================
# STEP 2: Add Repositories
# ============================================================================
echo -e "\n${BLUE}=== Step 2: Adding Repositories ===${NC}"

# Read PPAs from JSON
readarray -t ppas < <(jq -r '.packages.apt.repositories[]?' "$CONFIG_FILE")
for ppa in "${ppas[@]}"; do
    if [ -n "$ppa" ]; then
        echo -e "${BLUE}Adding PPA: $ppa${NC}"
        sudo add-apt-repository -y "$ppa" || echo -e "${YELLOW}⊘ Failed to add $ppa${NC}"
    fi
done

if [ ${#ppas[@]} -gt 0 ]; then
    sudo apt update
fi

echo -e "${GREEN}✓ Repositories configured${NC}"

# ============================================================================
# STEP 3: Install APT Packages
# ============================================================================
echo -e "\n${BLUE}=== Step 3: Installing APT Packages ===${NC}"

readarray -t packages < <(jq -r '.packages.apt.packages[]?' "$CONFIG_FILE")
if [ ${#packages[@]} -gt 0 ]; then
    echo -e "${BLUE}Installing ${#packages[@]} packages...${NC}"
    for pkg in "${packages[@]}"; do
        if [ -n "$pkg" ]; then
            echo -e "${BLUE}Installing: $pkg${NC}"
            sudo apt install -y "$pkg" || echo -e "${YELLOW}⊘ Could not install $pkg${NC}"
        fi
    done
    echo -e "${GREEN}✓ APT packages installed${NC}"
else
    echo -e "${YELLOW}⊘ No APT packages defined${NC}"
fi

# ============================================================================
# STEP 4: Install Flatpak Packages
# ============================================================================
echo -e "\n${BLUE}=== Step 4: Installing Flatpak Packages ===${NC}"

flatpak_enabled=$(jq -r '.packages.flatpak.enable' "$CONFIG_FILE")
if [ "$flatpak_enabled" = "true" ]; then
    # Ensure Flatpak is installed
    if ! command -v flatpak &> /dev/null; then
        sudo apt install -y flatpak
    fi
    
    # Add Flathub
    if ! flatpak remote-list | grep -q flathub; then
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    fi
    
    # Install packages
    readarray -t flatpaks < <(jq -r '.packages.flatpak.packages[]?' "$CONFIG_FILE")
    for app in "${flatpaks[@]}"; do
        if [ -n "$app" ]; then
            echo -e "${BLUE}Installing Flatpak: $app${NC}"
            flatpak install -y flathub "$app" || echo -e "${YELLOW}⊘ Could not install $app${NC}"
        fi
    done
    echo -e "${GREEN}✓ Flatpak packages installed${NC}"
else
    echo -e "${YELLOW}⊘ Flatpak disabled in config${NC}"
fi

# ============================================================================
# STEP 5: Apply Cinnamon Settings
# ============================================================================
echo -e "\n${BLUE}=== Step 5: Applying Cinnamon Settings ===${NC}"

# GTK Theme
gtk_theme=$(jq -r '.cinnamon.desktop.interface."gtk-theme"?' "$CONFIG_FILE")
if [ -n "$gtk_theme" ] && [ "$gtk_theme" != "null" ]; then
    gsettings set org.cinnamon.desktop.interface gtk-theme "$gtk_theme"
    echo -e "${GREEN}✓ GTK theme: $gtk_theme${NC}"
fi

# Icon Theme
icon_theme=$(jq -r '.cinnamon.desktop.interface."icon-theme"?' "$CONFIG_FILE")
if [ -n "$icon_theme" ] && [ "$icon_theme" != "null" ]; then
    gsettings set org.cinnamon.desktop.interface icon-theme "$icon_theme"
    echo -e "${GREEN}✓ Icon theme: $icon_theme${NC}"
fi

# Cursor Theme
cursor_theme=$(jq -r '.cinnamon.desktop.interface."cursor-theme"?' "$CONFIG_FILE")
if [ -n "$cursor_theme" ] && [ "$cursor_theme" != "null" ]; then
    gsettings set org.cinnamon.desktop.interface cursor-theme "$cursor_theme"
    echo -e "${GREEN}✓ Cursor theme: $cursor_theme${NC}"
fi

# Cursor Size
cursor_size=$(jq -r '.cinnamon.desktop.interface."cursor-size"?' "$CONFIG_FILE")
if [ -n "$cursor_size" ] && [ "$cursor_size" != "null" ]; then
    gsettings set org.cinnamon.desktop.interface cursor-size "$cursor_size"
    echo -e "${GREEN}✓ Cursor size: $cursor_size${NC}"
fi

# Window Manager Theme
wm_theme=$(jq -r '.cinnamon.desktop.wm.preferences.theme?' "$CONFIG_FILE")
if [ -n "$wm_theme" ] && [ "$wm_theme" != "null" ]; then
    gsettings set org.cinnamon.desktop.wm.preferences theme "$wm_theme"
    echo -e "${GREEN}✓ WM theme: $wm_theme${NC}"
fi

# Number of Workspaces
num_workspaces=$(jq -r '.cinnamon.desktop.wm.preferences."num-workspaces"?' "$CONFIG_FILE")
if [ -n "$num_workspaces" ] && [ "$num_workspaces" != "null" ]; then
    gsettings set org.cinnamon.desktop.wm.preferences num-workspaces "$num_workspaces"
    echo -e "${GREEN}✓ Workspaces: $num_workspaces${NC}"
fi

# Workspace Names
workspace_names=$(jq -r '.cinnamon.desktop.wm.preferences."workspace-names"?' "$CONFIG_FILE")
if [ -n "$workspace_names" ] && [ "$workspace_names" != "null" ]; then
    gsettings set org.cinnamon.desktop.wm.preferences workspace-names "$workspace_names"
    echo -e "${GREEN}✓ Workspace names configured${NC}"
fi

# Background
bg_uri=$(jq -r '.cinnamon.desktop.background."picture-uri"?' "$CONFIG_FILE")
if [ -n "$bg_uri" ] && [ "$bg_uri" != "null" ]; then
    # Expand variable placeholders
    bg_uri=$(echo "$bg_uri" | sed "s|{HOME}|$HOME|g")
    bg_uri=$(echo "$bg_uri" | sed "s|{USER}|$USER|g")
    gsettings set org.cinnamon.desktop.background picture-uri "$bg_uri"
    echo -e "${GREEN}✓ Background: $bg_uri${NC}"
fi

bg_options=$(jq -r '.cinnamon.desktop.background."picture-options"?' "$CONFIG_FILE")
if [ -n "$bg_options" ] && [ "$bg_options" != "null" ]; then
    gsettings set org.cinnamon.desktop.background picture-options "$bg_options"
fi

echo -e "${GREEN}✓ Cinnamon settings applied${NC}"

# ============================================================================
# STEP 6: Apply Nemo Settings
# ============================================================================
echo -e "\n${BLUE}=== Step 6: Applying Nemo Settings ===${NC}"

# Default folder viewer
folder_viewer=$(jq -r '.nemo.preferences."default-folder-viewer"?' "$CONFIG_FILE")
if [ -n "$folder_viewer" ] && [ "$folder_viewer" != "null" ]; then
    gsettings set org.nemo.preferences default-folder-viewer "$folder_viewer"
    echo -e "${GREEN}✓ Default view: $folder_viewer${NC}"
fi

# Show hidden files
show_hidden=$(jq -r '.nemo.preferences."show-hidden-files"?' "$CONFIG_FILE")
if [ -n "$show_hidden" ] && [ "$show_hidden" != "null" ]; then
    gsettings set org.nemo.preferences show-hidden-files "$show_hidden"
    echo -e "${GREEN}✓ Show hidden files: $show_hidden${NC}"
fi

echo -e "${GREEN}✓ Nemo settings applied${NC}"

# ============================================================================
# STEP 7: Apply Terminal Settings
# ============================================================================
echo -e "\n${BLUE}=== Step 7: Applying Terminal Settings ===${NC}"

# Get default profile UUID (create if doesn't exist)
PROFILE_UUID=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")
if [ -z "$PROFILE_UUID" ] || [ "$PROFILE_UUID" = "" ]; then
    PROFILE_UUID=$(uuidgen)
    gsettings set org.gnome.Terminal.ProfilesList list "['$PROFILE_UUID']"
    gsettings set org.gnome.Terminal.ProfilesList default "'$PROFILE_UUID'"
fi

PROFILE_PATH="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE_UUID/"

# Background color
bg_color=$(jq -r '.terminal.profiles.default."background-color"?' "$CONFIG_FILE")
if [ -n "$bg_color" ] && [ "$bg_color" != "null" ]; then
    dconf write "/org/gnome/terminal/legacy/profiles:/:$PROFILE_UUID/background-color" "'$bg_color'"
    dconf write "/org/gnome/terminal/legacy/profiles:/:$PROFILE_UUID/use-theme-colors" "false"
    echo -e "${GREEN}✓ Terminal background: $bg_color${NC}"
fi

# Foreground color
fg_color=$(jq -r '.terminal.profiles.default."foreground-color"?' "$CONFIG_FILE")
if [ -n "$fg_color" ] && [ "$fg_color" != "null" ]; then
    dconf write "/org/gnome/terminal/legacy/profiles:/:$PROFILE_UUID/foreground-color" "'$fg_color'"
fi

# Font
term_font=$(jq -r '.terminal.profiles.default.font?' "$CONFIG_FILE")
use_system_font=$(jq -r '.terminal.profiles.default."use-system-font"?' "$CONFIG_FILE")
if [ -n "$term_font" ] && [ "$term_font" != "null" ]; then
    dconf write "/org/gnome/terminal/legacy/profiles:/:$PROFILE_UUID/use-system-font" "$use_system_font"
    dconf write "/org/gnome/terminal/legacy/profiles:/:$PROFILE_UUID/font" "'$term_font'"
    echo -e "${GREEN}✓ Terminal font: $term_font${NC}"
fi

echo -e "${GREEN}✓ Terminal settings applied${NC}"

# ============================================================================
# STEP 8: Apply GTK Settings
# ============================================================================
echo -e "\n${BLUE}=== Step 8: Applying GTK Settings ===${NC}"

# Create GTK-3.0 settings
mkdir -p "$HOME/.config/gtk-3.0"

dark_theme=$(jq -r '.gtk."gtk-3".Settings."gtk-application-prefer-dark-theme"?' "$CONFIG_FILE")
if [ -n "$dark_theme" ] && [ "$dark_theme" != "null" ]; then
    cat > "$HOME/.config/gtk-3.0/settings.ini" << EOF
[Settings]
gtk-application-prefer-dark-theme=$dark_theme
gtk-theme-name=$(jq -r '.gtk."gtk-3".Settings."gtk-theme-name"' "$CONFIG_FILE")
gtk-icon-theme-name=$(jq -r '.gtk."gtk-3".Settings."gtk-icon-theme-name"' "$CONFIG_FILE")
gtk-font-name=$(jq -r '.gtk."gtk-3".Settings."gtk-font-name"' "$CONFIG_FILE")
gtk-cursor-theme-name=$(jq -r '.gtk."gtk-3".Settings."gtk-cursor-theme-name"' "$CONFIG_FILE")
gtk-cursor-theme-size=$(jq -r '.gtk."gtk-3".Settings."gtk-cursor-theme-size"' "$CONFIG_FILE")
EOF
    echo -e "${GREEN}✓ GTK-3 settings configured${NC}"
fi

# GTK bookmarks
readarray -t bookmarks < <(jq -r '.gtk.bookmarks[]?' "$CONFIG_FILE")
if [ ${#bookmarks[@]} -gt 0 ]; then
    : > "$HOME/.config/gtk-3.0/bookmarks"
    for bookmark in "${bookmarks[@]}"; do
        if [ -n "$bookmark" ]; then
            # Expand variable placeholders
            bookmark=$(echo "$bookmark" | sed "s|{HOME}|$HOME|g")
            bookmark=$(echo "$bookmark" | sed "s|{USER}|$USER|g")
            echo "$bookmark" >> "$HOME/.config/gtk-3.0/bookmarks"
        fi
    done
    echo -e "${GREEN}✓ GTK bookmarks configured${NC}"
fi

# ============================================================================
# STEP 9: Configure Applications
# ============================================================================
echo -e "\n${BLUE}=== Step 9: Configuring Applications ===${NC}"

# VS Code
vscode_install=$(jq -r '.applications.vscode.install?' "$CONFIG_FILE")
if [ "$vscode_install" = "true" ]; then
    if ! command -v code &> /dev/null; then
        echo -e "${BLUE}Installing VS Code...${NC}"
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
        sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
        echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
        rm -f packages.microsoft.gpg
        sudo apt update
        sudo apt install -y code
    fi
    
    # Install extensions
    readarray -t extensions < <(jq -r '.applications.vscode.extensions[]?' "$CONFIG_FILE")
    for ext in "${extensions[@]}"; do
        if [ -n "$ext" ]; then
            echo -e "${BLUE}Installing VS Code extension: $ext${NC}"
            code --install-extension "$ext" || true
        fi
    done
    
    # Apply settings
    mkdir -p "$HOME/.config/Code/User"
    jq -r '.applications.vscode.settings' "$CONFIG_FILE" > "$HOME/.config/Code/User/settings.json"
    echo -e "${GREEN}✓ VS Code configured${NC}"
fi

# ============================================================================
# STEP 10: Configure Git
# ============================================================================
echo -e "\n${BLUE}=== Step 10: Configuring Git ===${NC}"

git_name=$(jq -r '.git.user.name?' "$CONFIG_FILE")
git_email=$(jq -r '.git.user.email?' "$CONFIG_FILE")

if [ -n "$git_name" ] && [ "$git_name" != "null" ] && [ "$git_name" != "" ]; then
    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
    echo -e "${GREEN}✓ Git user configured${NC}"
fi

git_editor=$(jq -r '.git.core.editor?' "$CONFIG_FILE")
if [ -n "$git_editor" ] && [ "$git_editor" != "null" ]; then
    git config --global core.editor "$git_editor"
fi

git_branch=$(jq -r '.git.init.defaultBranch?' "$CONFIG_FILE")
if [ -n "$git_branch" ] && [ "$git_branch" != "null" ]; then
    git config --global init.defaultBranch "$git_branch"
fi

git_rebase=$(jq -r '.git.pull.rebase?' "$CONFIG_FILE")
if [ -n "$git_rebase" ] && [ "$git_rebase" != "null" ]; then
    git config --global pull.rebase "$git_rebase"
fi

echo -e "${GREEN}✓ Git configured${NC}"

# ============================================================================
# STEP 11: Apply System Tweaks
# ============================================================================
echo -e "\n${BLUE}=== Step 11: Applying System Tweaks ===${NC}"

swappiness=$(jq -r '.system.tweaks.swappiness?' "$CONFIG_FILE")
if [ -n "$swappiness" ] && [ "$swappiness" != "null" ]; then
    echo "vm.swappiness=$swappiness" | sudo tee -a /etc/sysctl.conf > /dev/null
    sudo sysctl vm.swappiness=$swappiness
    echo -e "${GREEN}✓ Swappiness set to $swappiness${NC}"
fi

vfs_cache=$(jq -r '.system.tweaks.vfs_cache_pressure?' "$CONFIG_FILE")
if [ -n "$vfs_cache" ] && [ "$vfs_cache" != "null" ]; then
    echo "vm.vfs_cache_pressure=$vfs_cache" | sudo tee -a /etc/sysctl.conf > /dev/null
    sudo sysctl vm.vfs_cache_pressure=$vfs_cache
    echo -e "${GREEN}✓ VFS cache pressure set to $vfs_cache${NC}"
fi

inotify_watches=$(jq -r '.system.tweaks.inotify_max_user_watches?' "$CONFIG_FILE")
if [ -n "$inotify_watches" ] && [ "$inotify_watches" != "null" ]; then
    echo "fs.inotify.max_user_watches=$inotify_watches" | sudo tee -a /etc/sysctl.conf > /dev/null
    sudo sysctl fs.inotify.max_user_watches=$inotify_watches
    echo -e "${GREEN}✓ Inotify watches set to $inotify_watches${NC}"
fi

# ============================================================================
# COMPLETION
# ============================================================================
echo -e "\n${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║            Configuration Applied Successfully!         ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${YELLOW}Please log out and log back in for all changes to take effect.${NC}"
echo -e "${BLUE}You may also want to restart Cinnamon: ${NC}cinnamon --replace"
echo ""
