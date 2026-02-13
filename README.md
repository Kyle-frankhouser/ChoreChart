# Linux Mint Cinnamon Automated Setup & Backup Tool

This comprehensive tool helps you backup your complete Linux Mint Cinnamon environment and restore it on a fresh installation with a single script. Perfect for setting up new machines or recovering from reinstalls!

**Two Approaches Available:**

1. **📁 Backup/Restore** - Clone your exact system with all files and settings
2. **⚙️ Configuration-as-Code** - Define your system in a JSON file (no backup files needed!)

> **New!** See [CONFIG-GUIDE.md](CONFIG-GUIDE.md) for the configuration-as-code approach that uses a single JSON file instead of backup folders.

## 🎯 Quick Start

### Approach 1: Backup & Restore (Traditional)

**Creating a Backup:**
```bash
./backup.sh
```

**Fresh Install:**
```bash
cd backup_YYYYMMDD_HHMMSS
./fresh-install-setup.sh
```

### Approach 2: Configuration-as-Code (New!)

**Generate config from current system:**
```bash
./generate-config.sh
```

**Apply config on fresh install:**
```bash
./apply-config.sh system-config.json
```

**See [CONFIG-GUIDE.md](CONFIG-GUIDE.md) for full details on the configuration approach.**

> **💡 Pro Tip**: Generated configs use `{HOME}` and `{USER}` variables for portability - see [VARIABLES.md](VARIABLES.md)

## 📦 What Gets Backed Up

The enhanced backup script saves:

### Desktop Environment
- **Cinnamon Settings**: Desktop configuration, panels, applets, extensions, themes
- **Panel Layout**: Complete panel and applet configuration (positions, zones, order)
- **Applet Settings**: Individual applet customizations (calendar date/time format, menu preferences, etc.)
- **Nemo Settings**: File manager preferences
- **GTK Themes**: GTK 2.0, 3.0, and 4.0 theme settings
- **Custom Themes & Icons**: User-installed themes and icon packs
- **Custom Fonts**: User-installed fonts
- **Desktop Settings**: Monitor configuration, wallpapers
- **Cinnamon Extensions & Applets**: Full backup with UUIDs for automated reinstall
- **Terminal Settings**: Terminal color schemes and preferences
- **Plank Dock**: If you use Plank dock

### Applications & Packages
- **Package Lists**: All installed packages and manually installed packages
- **PPAs**: Custom repositories you've added
- **Flatpak Apps**: All installed Flatpak applications
- **Snap Apps**: All installed Snap packages (if using Snap)
- **VS Code**: Extensions and settings.json
- **Application Launchers**: Custom desktop shortcuts
- **Autostart Applications**: Programs that run on login

### Developer Tools
- **Git Configuration**: Global git config (.gitconfig)
- **Bash Customizations**: Custom .bashrc additions
- **VS Code Settings**: Extensions and user settings

## 📋 Detailed Usage

### Step 1: Create a Backup on Your Current System

1. **Make the backup script executable:**
   ```bash
   chmod +x backup.sh
   ```

2. **Run the backup script:**
   ```bash
   ./backup.sh
   ```

3. **A new timestamped folder will be created** (e.g., `backup_20260212_143052`) containing:
   - All your settings files (dconf, configs, themes)
   - Package lists (APT, Flatpak, Snap)
   - PPAs and repositories
   - VS Code extensions and settings
   - Git configuration
   - Extension/applet UUIDs
   - A ready-to-use `fresh-install-setup.sh` script

### Step 2: Transfer to New Computer

1. **Copy the entire backup folder** to your new computer via:
   - USB drive
   - Network transfer (scp, rsync, etc.)
   - Cloud storage
   - External hard drive

### Step 3: Run Automated Setup (Recommended)

The `fresh-install-setup.sh` script automates the entire setup process:

1. **Navigate to the backup folder:**
   ```bash
   🛠️ Manual Package Installation (Optional)

If you used `restore.sh` instead of `fresh-install-setup.sh`, you can install packages manually:

### Option 1: Use fresh-install-setup.sh (Recommended)
The automated setup script handles all package installation.

### Option 2: Install Only Manually Installed Packages
```bash
xargs -a manually-installed-packages.txt sudo apt install -y
```

### Option 3: Install Flatpaks
```bash
while read app; do flatpak install -y flathub "$app"; done < flatpak-list.txt
```

### Option 4: Install VS Code Extensions
```bash
while read ext; do code --install-extension "$ext"; done < vscode-extensions.txt
```

### Option 5: Review and Install Selectively
Open the list files and install only what you need:
```bash
sudo apt install package1 package2 package3
```

## 🎨 Cinnamon Extensions and Applets

The `fresh-install-setup.sh` script automatically downloads and installs extensions/applets from Cinnamon Spices using the UUIDs saved in:
- `spices-extensions.txt`
- `spices-applets.txt`

If you need to manually reinstall:
1. Open **System Settings** → **Extensions** (or **Applets**)
2. Download from the Spices interface
3. Or manually install from the backed up folders in `local/share/cinnamon/`
   cd backup_YYYYMMDD_HHMMSS
   ```

2. **Run the restore script:**
   ```bash
   chmod +x restore.sh
   ./restore.sh
   ```

3. **Manually install packages** as needed (see section below)

## Installing Packages on the New Computer

The backup includes package lists but doesn't automatically install packages. To install packages:

### Option 1: Install All Packages (not recommended)
```bash
sudo dpkg --set-selections < package-list.txt
sudo apt-get dselect-upgrade
```

### Option 2: Install Only Manually Installed Packages (recommended)
```bash
xargs -a manually-installed-packages.txt sudo apt install -y
```

### Option 3: Review and Install Selectively
Open `manually-installed-packages.txt` and install only the packages you need:
```bash
sudo apt install package1 package2 package3
```⚙️ Customization

### Customizing the Setup Process

Edit `setup-config.sh` in your backup folder to customize:
- Extra packages to install beyond the package list
- Additional Flatpaks or PPAs
- Git and SSH configuration
- Which setup steps to run
- Post-install commands

### Adding Custom System Tweaks

Edit `system-tweaks.sh` to add your preferred system optimizations:
- Swappiness settings
- File watcher limits
- Network optimizations
- Service configurations

### Backing Up Bash Customizations
� Which Approach Should I Use?

| Use Case | Recommended Approach |
|----------|---------------------|
| Exact system clone (themes, fonts, custom files) | **Backup/Restore** |
| Version-controlled setup | **Config-as-Code** |
| Share setup with others | **Config-as-Code** |
| Multiple system profiles (work/home/minimal) | **Config-as-Code** |
| Migrate custom themes and extensions | **Backup/Restore** |
| Quick iteration on settings | **Config-as-Code** |
| Complete system recovery | **Backup/Restore** |

**Best Practice**: Use both! Maintain a JSON config for standard settings, and create backups for complete system clones.

## �
Add this line to your `~/.bashrc` before your custom additions:
```bash
# User customizations
```

Everything after this marker will be backed up to `bashrc-custom` and restored automatically.

## 📁 Backup Contents Reference

After running `backup.sh`, your backup folder contains:

| File | Description |
|------|-------------|
| `fresh-install-setup.sh` | **Main automated setup script** |
| `restore.sh` | Settings-only restore script (no package installation) |
| `setup-config.sh` | Configuration file for customizing setup |
| `system-tweaks.sh` | Optional system optimizations |
| `cinnamon-settings.dconf` | Cinnamon desktop settings |
| `nemo-settings.dconf` | File manager settings |
| `gnome-terminal-settings.dconf` | Terminal settings |
| `manually-installed-packages.txt` | Packages you manually installed |
| `package-list.txt` | All installed packages |
| `ppas.list` | Custom PPAs you've added |
| `flatpak-list.txt` | Installed Flatpak apps |
| `snap-list.txt` | Installed Snap packages |
| `spices-extensions.txt` | Cinnamon extension UUIDs |
| `spices-applets.txt` | Cinnamon applet UUIDs |
| `vscode-extensions.txt` | VS Code extensions |
| `vscode-settings.json` | VS Code settings |
| `gitconfig` | Git global configuration |
| `bashrc-custom` | Custom bash additions |
| `config/`, `themes/`, `icons/`, `fonts/` | Various config and asset directories |

## 💡 Tips & Best Practices

- **Test Your Backup**: Run the backup script before you actually need it
- **Regular Backups**: Create backups before major system changes
- **Keep Multiple Backups**: Store backups in different locations (external drive, cloud)
- **Version Control**: Consider keeping your backup folder in a private git repository
- **Sync Between Computers**: Use this to keep multiple machines in sync
- **USB Drive Setup**: Keep your latest backup on a USB drive for emergency reinstalls
- **Review Package Lists**: Before running setup, review what will be installed
- **Selective Restore**: You can manually copy specific folders if you only want certain settings

## 🚫 What's NOT Backed Up

For security and practical reasons, these items are intentionally excluded:

- Personal documents, downloads, photos, videos
- Browser bookmarks and extensions (use browser sync instead)
- Email data (backup separately)
- VPN configurations (may contain credentials)
- Password managers (backup separately)
- SSH private keys (for security - generate new ones)
- Database files
- Virtual machine images
- Docker containers/volumes

**Important**: Manually backup your critical data separately!

## 🔧 Troubleshooting

### Package Installation Fails
- Some packages may no longer be available or have different names
- Review the log file created during setup
- Manually install problematic packages later

### Cinnamon Extensions Won't Load
- Extensions may need to be compatible with your Cinnamon version
- Try reinstalling from System Settings → Extensions
- Check extension folders have correct permissions

### Settings Not Applying
- Make sure to log out and log back in
- Try restarting Cinnamon: `cinnamon --replace`
- Some settings may require a full reboot

### VS Code Extensions Fail to Install
- Ensure VS Code is installed and working first
- Run manually: `code --install-extension <extension-id>`

## 📝 Advanced Usage

### Schedule Automatic Backups

Add to crontab to backup weekly:
```bash
crontab -e
# Add this line:
0 2 * * 0 /home/yourusername/Documents/mintbackup/backup.sh
```

### Backup to Remote Server

Use rsync to automatically sync backups:
```bash
rsync -avz backup_YYYYMMDD_HHMMSS/ user@server:/path/to/backups/
```

### Create a Bootable USB with Backup

1. Create a live USB of Linux Mint
2. Copy your latest backup folder to the USB drive
3. After fresh install, run setup directly from USB

## 🤝 Contributing

Feel free to customize these scripts for your needs! Some ideas:
- Add support for other applications
- Backup additional configuration files
- Create installation profiles (minimal, full, developer, etc.)
- Add support for other desktop environmentsbefore major system changes
- **Sync Between Computers**: Run backup on one computer, restore on another to keep settings in sync
- **Selective Restore**: You can manually copy specific folders from the backup if you only want to restore certain settings

## What's NOT Backed Up

- Application data (documents, downloads, photos, etc.)
- Browser bookmarks and extensions (use browser sync instead)
- Email data (backup separately)
- VPN configurations (may contain sensitive data)
- Password managers (backup separately)
- SSH keys and GPG keys (handle with care)

For these items, use dedicated backup tools or manual backup methods.

## Troubleshooting

### Settings Don't Appear After Restore
- Make sure you logged out and back in
- Try restarting the computer
- Run `cinnamon --replace` to restart Cinnamon

### Themes Don't Show Up
- Update the icon cache: `gtk-update-icon-cache`
- Rebuild font cache: `fc-cache -f`
- Check that theme files have correct permissions

### Permissions Issues
Make sure the backup and restore scripts are executable:
```bash
chmod +x backup.sh
chmod +x restore.sh
```

## Safety

- The restore script will ask for confirmation before overwriting settings
- Your original backup files remain untouched during restore
- Consider backing up your target computer's settings before restoring

## 📚 Additional Documentation

- **[CONFIG-GUIDE.md](CONFIG-GUIDE.md)** - Complete guide to configuration-as-code approach
- **[PANELS.md](PANELS.md)** - Panel layout and applet positioning
- **[APPLETS.md](APPLETS.md)** - Applet-specific settings (calendar, menu, etc.)
- **[VARIABLES.md](VARIABLES.md)** - Using portable path variables
- **[QUICKSTART.md](QUICKSTART.md)** - Quick reference card
- **[WORKFLOW-EXAMPLE.sh](WORKFLOW-EXAMPLE.sh)** - Example workflows

## License

Free to use and modify for personal use.
