# Linux Mint Fresh Install Quick Reference

## 🎯 TWO APPROACHES

### 📁 Backup/Restore (Complete Clone)
Backs up everything including custom files, themes, fonts

### ⚙️ Config-as-Code (JSON Definition)  
Single JSON file, no backup folders needed
**→ See CONFIG-GUIDE.md for details**

---

## 🚀 QUICK START - Backup/Restore

### On Your Current System:
```bash
./backup.sh
```

### On Fresh Install:
```bash
cd backup_YYYYMMDD_HHMMSS
./fresh-install-setup.sh
# Then log out and log back in
```

---

## 📝 What Each Script Does

### Backup/Restore Scripts
| Script | Purpose |
|--------|---------|
| **backup.sh** | Creates a complete backup of your system |
| **fresh-install-setup.sh** | Full automated setup on fresh install |
| **restore.sh** | Restore settings only (no package install) |
| **system-tweaks.sh** | Optional performance optimizations |
| **setup-config.sh** | Customize what gets installed |

### Config-as-Code Scripts
| Script | Purpose |
|--------|---------|
| **generate-config.sh** | Generate JSON from current system |
| **apply-config.sh** | Apply JSON config to system |
| **system-config.json** | Declarative system definition |

---

## 🎯 Common Scenarios

### Scenario 1: New Computer Setup
```bash
# 1. Copy backup folder to new computer
# 2. Run automated setup
./fresh-install-setup.sh
```

### Scenario 2: Just Restore Settings
```bash
# If packages are already installed
./restore.sh
```

### Scenario 3: Selective Install
```bash
# Edit setup-config.sh first to customize
# Then run:
./fresh-install-setup.sh
```

### Scenario 4: Sync Settings Between Computers
```bash
# On computer A:
./backup.sh
rsync -avz backup_*/ user@computerB:~/

# On computer B:
./restore.sh
```

---

## 📦 Key Files in Backup

- **manually-installed-packages.txt** - Your installed programs
- **ppas.list** - Custom software repositories
- **flatpak-list.txt** - Flatpak applications
- **vscode-extensions.txt** - VS Code extensions
- **spices-extensions.txt** - Cinnamon extensions UUIDs
- **cinnamon-settings.dconf** - Desktop appearance & behavior

---

## ⚠️ Important Notes

1. **Always log out after restore** - Settings need a fresh session
2. **Internet required** - Setup downloads packages and extensions
3. **Takes 15-30 minutes** - Depending on package count
4. **Don't use sudo** - Script will ask when needed
5. **Check logs** - Setup creates a log file for troubleshooting

---

## 🔧 Troubleshooting

**Problem**: Package won't install
**Solution**: Skip it and install manually later

**Problem**: Extension won't load
**Solution**: System Settings → Extensions → Reinstall

**Problem**: Settings not applying
**Solution**: Log out and back in, or run `cinnamon --replace`

---

## 💾 Backup Storage Tips

- Keep on USB drive for emergencies
- Store in cloud (Dropbox, Google Drive, etc.)
- Git repository for version control
- External hard drive for long-term storage

---

## 🎨 Customization

Edit these files before running setup:
- **setup-config.sh** - Choose what to install
- **system-tweaks.sh** - Performance optimizations
- **ppas.list** - Add/remove repositories
- **manually-installed-packages.txt** - Add/remove packages

---

**Created by: mintbackup tool**
**Documentation: See README.md for full details**
