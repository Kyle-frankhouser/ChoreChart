#!/bin/bash

# Setup Configuration File
# Edit this file to customize what gets installed during fresh-install-setup.sh

# ============================================================================
# Personal Information
# ============================================================================

# Git Configuration (leave empty to skip or configure interactively)
GIT_USER_NAME=""
GIT_USER_EMAIL=""

# SSH Key Configuration
GENERATE_SSH_KEY="ask"  # Options: yes, no, ask
SSH_KEY_EMAIL=""

# ============================================================================
# Additional Packages to Install
# ============================================================================

# Add any extra packages you want installed beyond what's in manually-installed-packages.txt
EXTRA_PACKAGES=(
    # Development tools
    # "vim"
    # "neovim"
    # "tmux"
    
    # Media tools
    # "vlc"
    # "gimp"
    # "inkscape"
    
    # Productivity
    # "timeshift"
    # "gparted"
    
    # System utilities
    # "htop"
    # "neofetch"
    # "tree"
)

# ============================================================================
# Additional Flatpaks to Install
# ============================================================================

# Add any Flatpak applications beyond what's in flatpak-list.txt
EXTRA_FLATPAKS=(
    # "com.spotify.Client"
    # "com.discordapp.Discord"
    # "org.videolan.VLC"
)

# ============================================================================
# Additional PPAs
# ============================================================================

# Add any PPAs beyond what's in ppas.list
EXTRA_PPAS=(
    # "ppa:graphics-drivers/ppa"  # NVIDIA drivers
    # "ppa:obsproject/obs-studio"  # OBS Studio
)

# ============================================================================
# Feature Flags
# ============================================================================

# Enable/disable specific setup steps
INSTALL_PACKAGES=true
INSTALL_FLATPAKS=true
INSTALL_SNAPS=false  # Set to true if you use Snap
RESTORE_SETTINGS=true
CONFIGURE_GIT=true
SETUP_SSH=true
INSTALL_VSCODE_EXTENSIONS=true
APPLY_SYSTEM_TWEAKS="ask"  # Options: yes, no, ask

# ============================================================================
# System Tweaks
# ============================================================================

# Apply performance tweaks
ENABLE_SWAPPINESS_TWEAK=true
SWAPPINESS_VALUE=10

# Increase file watchers for development
INCREASE_FILE_WATCHERS=true

# ============================================================================
# Post-Install Commands
# ============================================================================

# Commands to run after the main setup completes
# (e.g., custom configurations, downloading files, etc.)
POST_INSTALL_COMMANDS=(
    # "echo 'Setup complete!'"
    # "mkdir -p ~/Projects"
    # "git clone https://github.com/user/dotfiles ~/.dotfiles"
)

# ============================================================================
# Notes
# ============================================================================

# This configuration file is sourced by fresh-install-setup.sh
# You can add any bash variables or functions here
# They will be available during the setup process
