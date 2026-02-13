#!/bin/bash

# System Tweaks for Linux Mint
# Customize this file with your preferred system optimizations

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== Applying System Tweaks ===${NC}\n"

# ============================================================================
# Performance Tweaks
# ============================================================================

# Reduce swappiness (makes system use RAM more and swap less)
# Default is 60, lower values (10-20) are better for desktop use
echo -e "${BLUE}Setting swappiness to 10...${NC}"
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf > /dev/null
sudo sysctl -p

# Improve system responsiveness under memory pressure
echo -e "${BLUE}Improving I/O scheduler for SSD...${NC}"
echo "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf > /dev/null

# ============================================================================
# File System Tweaks
# ============================================================================

# Increase the number of file watchers (useful for development)
echo -e "${BLUE}Increasing file watcher limit...${NC}"
echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.conf > /dev/null

# ============================================================================
# Network Tweaks (Optional)
# ============================================================================

# Speed up DNS resolution
# echo -e "${BLUE}Configuring faster DNS...${NC}"
# echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf.head > /dev/null
# echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf.head > /dev/null

# ============================================================================
# Desktop Environment Tweaks
# ============================================================================

# Disable unnecessary startup services (comment out what you want to keep)
# echo -e "${BLUE}Disabling unnecessary services...${NC}"
# sudo systemctl disable bluetooth.service  # Disable if you don't use Bluetooth
# sudo systemctl disable cups-browsed.service  # Disable if you don't use network printing

echo -e "${GREEN}✓ System tweaks applied${NC}"
echo -e "${YELLOW}Note: Some changes require a reboot to take effect${NC}"
