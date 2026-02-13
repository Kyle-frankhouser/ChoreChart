#!/bin/bash

# Example: Fresh Install Setup Workflow
# This is a documented example showing the complete process

echo "=== Linux Mint Fresh Install Workflow Example ==="
echo ""
echo "This file demonstrates the complete workflow. Don't execute it directly!"
echo ""

# ============================================================================
# PART 1: On Your Current (Working) System
# ============================================================================

echo "PART 1: Creating a Backup"
echo "-------------------------"
cat << 'EOF'

1. Navigate to your mintbackup directory:
   cd ~/Documents/mintbackup

2. Run the backup script:
   ./backup.sh

3. This creates a folder like: backup_20260213_140530/
   This folder contains everything you need for fresh install!

4. What gets backed up:
   ✓ All Cinnamon settings (panels, applets, themes)
   ✓ All installed packages (APT, Flatpak, Snap)
   ✓ All PPAs and repositories
   ✓ VS Code extensions & settings
   ✓ Git configuration
   ✓ Cinnamon extensions/applets
   ✓ Themes, icons, fonts
   ✓ Terminal settings
   ✓ Auto-start programs

5. Transfer the backup folder to your new system:
   - USB drive
   - Network copy: scp -r backup_*/ user@newcomputer:~/
   - Cloud storage (Dropbox, Drive, etc.)
   - External hard drive

EOF

# ============================================================================
# PART 2: On Your Fresh Linux Mint Installation
# ============================================================================

echo ""
echo "PART 2: Fresh Install Setup"
echo "---------------------------"
cat << 'EOF'

1. Fresh install Linux Mint and complete initial setup

2. Copy or mount your backup folder to the new system

3. Navigate to the backup folder:
   cd ~/backup_20260213_140530

4. (Optional) Customize what gets installed:
   nano setup-config.sh
   
   You can:
   - Add extra packages
   - Skip certain installation steps
   - Configure git/ssh settings
   - Add custom PPAs

5. Run the automated setup:
   chmod +x fresh-install-setup.sh
   ./fresh-install-setup.sh

6. What the script does:
   [Running for 15-30 minutes]
   ✓ Updates system packages
   ✓ Adds your PPAs
   ✓ Installs all your packages
   ✓ Installs Flatpak/Snap apps
   ✓ Downloads & installs Cinnamon extensions
   ✓ Restores all settings
   ✓ Configures Git & SSH (optional)
   ✓ Installs VS Code extensions
   ✓ Applies system tweaks (optional)

7. Log out and log back in

8. Your system now looks and behaves exactly like your old one!

EOF

# ============================================================================
# PART 3: Alternative - Settings Only Restore
# ============================================================================

echo ""
echo "PART 3: Alternative Method (Settings Only)"
echo "-----------------------------------------"
cat << 'EOF'

If you only want to restore settings without installing packages:

1. Navigate to backup folder:
   cd ~/backup_20260213_140530

2. Run the basic restore script:
   ./restore.sh

3. Manually install packages as needed:
   # Install specific packages:
   sudo apt install package1 package2

   # Or install all from list:
   xargs -a manually-installed-packages.txt sudo apt install -y

   # Install Flatpaks:
   while read app; do flatpak install -y flathub "$app"; done < flatpak-list.txt

4. Log out and log back in

EOF

# ============================================================================
# PART 4: Verifying Everything Works
# ============================================================================

echo ""
echo "PART 4: Post-Setup Verification"
echo "-------------------------------"
cat << 'EOF'

After setup, verify these items:

□ Desktop appearance matches (themes, icons, wallpaper)
□ Panel layout and applets are correct
□ File manager (Nemo) settings are correct
□ Terminal colors and fonts are correct
□ Applications are installed and working
□ VS Code extensions loaded
□ Git config is correct: git config --list
□ SSH key is set up (if configured)
□ Keyboard shortcuts work
□ Startup applications are configured
□ Themes and fonts are applied

Common fixes:
- If panels look wrong: Right-click panel → Troubleshoot → Restore default
- If extensions don't load: System Settings → Extensions → Reinstall
- If some settings missing: Run ./restore.sh again
- If themes missing: Copy from backup themes/ folder manually

EOF

# ============================================================================
# PART 5: Tips for Success
# ============================================================================

echo ""
echo "PART 5: Pro Tips"
echo "---------------"
cat << 'EOF'

□ Test the backup/restore process BEFORE you need it

□ Create backups regularly:
  - Before major updates
  - Before installing new software
  - Monthly for peace of mind

□ Keep multiple backups in different locations

□ Add custom marker to .bashrc for custom configs:
  echo "# User customizations" >> ~/.bashrc
  # Then add your custom stuff below

□ Review package lists before running fresh-install-setup.sh
  to remove packages you no longer need

□ Use setup-config.sh to add new packages/PPAs you want
  on every fresh install

□ Store backup folder in git for version control:
  cd backup_20260213_140530
  git init
  git add .
  git commit -m "Backup snapshot"
  git push to private repository

□ Keep a USB drive with latest Linux Mint ISO + your backup
  for emergency reinstalls

EOF

echo ""
echo "==================================================="
echo "Ready to set up your perfect Linux Mint system!"
echo "==================================================="
