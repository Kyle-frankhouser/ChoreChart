# Configuration-as-Code Approach

This is a declarative, JSON-based system configuration that requires **no backup files**. Define your desired system state in a JSON file and apply it with a single command.

## 🎯 Quick Start

### Generate Config from Current System
```bash
./generate-config.sh
# Creates: system-config-generated.json
```

### Apply Configuration
```bash
./apply-config.sh system-config.json
```

That's it! No backup folders needed.

---

## 📝 How It Works

### Configuration File ([system-config.json](system-config.json))
A single JSON file that defines:
- Packages to install (APT, Flatpak, Snap)
- PPAs and repositories
- Cinnamon desktop settings (themes, panels, workspaces)
- Nemo file manager settings
- Terminal colors and fonts
- GTK themes and bookmarks
- VS Code extensions and settings
- Git configuration
- System performance tweaks

**Portable Variables**: Use `{HOME}` and `{USER}` placeholders for user-specific paths - they're automatically expanded when applied. See [VARIABLES.md](VARIABLES.md) for details.

### Apply Script ([apply-config.sh](apply-config.sh))
Reads the JSON and applies all settings:
- Installs packages
- Configures desktop appearance
- Sets up applications
- Applies system tweaks

### Generate Script ([generate-config.sh](generate-config.sh))
Creates a JSON config from your current system - perfect for bootstrapping your first config file.

---

## 🔄 Typical Workflow

### First Time Setup
```bash
# 1. Generate config from your current system
./generate-config.sh

# 2. Review and edit the generated file
nano system-config-generated.json

# 3. Rename it to your main config
mv system-config-generated.json my-config.json

# 4. Commit to git for version control
git add my-config.json
git commit -m "Initial system configuration"
```

### On a Fresh Install
```bash
# 1. Clone your config repo
git clone https://github.com/yourusername/mint-config.git
cd mint-config

# 2. Apply configuration
./apply-config.sh my-config.json

# 3. Log out and back in
```

### Making Changes
```bash
# 1. Edit the JSON file directly
nano my-config.json

# Add a package:
# "packages": ["git", "vim", "new-package"]

# 2. Apply the updated config
./apply-config.sh my-config.json

# 3. Commit changes
git commit -am "Added new-package"
```

---

## 📦 What Can Be Configured

### Packages & Software
```json
{
  "packages": {
    "apt": {
      "repositories": ["ppa:graphics-drivers/ppa"],
      "packages": ["git", "vim", "htop"]
    },
    "flatpak": {
      "enable": true,
      "packages": ["com.spotify.Client"]
    }
  }
}
```

### Desktop Appearance
```json
{
  "cinnamon": {
    "desktop": {
      "interface": {
        "gtk-theme": "Mint-Y-Dark-Aqua",
        "icon-theme": "Mint-Y-Aqua",
        "cursor-theme": "Bibata-Modern-Ice"
      }
    }
  }
}
```

### Terminal Colors
```json
{
  "terminal": {
    "profiles": {
      "default": {
        "background-color": "#2E3440",
        "foreground-color": "#D8DEE9",
        "font": "Monospace 11"
      }
    }
  }
}
```

### VS Code
```json
{
  "applications": {
    "vscode": {
      "install": true,
      "extensions": [
        "ms-python.python",
        "github.copilot"
      ],
      "settings": {
        "editor.fontSize": 14,
        "editor.formatOnSave": true
      }
    }
  }
}
```

### Git Configuration
```json
{
  "git": {
    "user": {
      "name": "Your Name",
      "email": "your.email@example.com"
    },
    "init": {
      "defaultBranch": "main"
    }
  }
}
```

### System Tweaks
```json
{
  "system": {
    "tweaks": {
      "swappiness": 10,
      "vfs_cache_pressure": 50,
      "inotify_max_user_watches": 524288
    }
  }
}
```

---

## 💡 Advantages of This Approach

✅ **No Backup Files** - Just one JSON file  
✅ **Version Control** - Track changes in git  
✅ **Portable** - Works on any Linux Mint system  
✅ **Declarative** - Define what you want, not how to get there  
✅ **Reviewable** - See exactly what will be changed  
✅ **Shareable** - Share configs with team or community  
✅ **Multiple Profiles** - Work config, home config, minimal config  

---

## 🎨 Multiple Configuration Profiles

Create different configs for different scenarios:

```bash
# Work laptop
./apply-config.sh config-work.json

# Home desktop
./apply-config.sh config-home.json

# Minimal install
./apply-config.sh config-minimal.json
```

Example structure:
```
mint-config/
├── apply-config.sh
├── generate-config.sh
├── config-base.json          # Common settings
├── config-work.json          # Work-specific
├── config-home.json          # Home-specific
└── config-gaming.json        # Gaming setup
```

---

## 🔧 Advanced Usage

### Dry Run (See What Would Change)
Edit `apply-config.sh` and add echo before commands to preview:
```bash
echo sudo apt install -y "$pkg"  # Preview instead of install
```

### Partial Application
Comment out sections in `apply-config.sh` to apply only specific parts:
```bash
# Skip packages, only apply settings
# STEP 3: Install APT Packages (commented out)
```

### Merge Configurations
Use `jq` to combine configs:
```bash
jq -s '.[0] * .[1]' config-base.json config-work.json > combined.json
./apply-config.sh combined.json
```

### Environment-Specific Settings
Use different JSON files per environment:
```bash
if [ "$HOSTNAME" = "work-laptop" ]; then
    ./apply-config.sh config-work.json
else
    ./apply-config.sh config-home.json
fi
```

---

## 🆚 Comparison: Config vs Backup Approach

| Feature | JSON Config | Backup/Restore |
|---------|-------------|----------------|
| File size | Small (~5KB) | Large (can be 100s of MB) |
| Version control | Perfect ✅ | Difficult ❌ |
| Human readable | Yes ✅ | No ❌ |
| Exact system clone | No ❌ | Yes ✅ |
| Custom themes/fonts | Manual download | Auto-included ✅ |
| Portability | Excellent ✅ | Good |
| Customization | Easy editing | Requires re-backup |

**Best Practice**: Use both!
- **JSON config** for standard settings and packages
- **Backup** for custom themes, fonts, and exact cloning

---

## 📚 Examples

### Minimal Developer Setup
```json
{
  "packages": {
    "apt": {
      "packages": ["git", "vim", "build-essential", "python3-pip"]
    }
  },
  "git": {
    "user": {
      "name": "Developer",
      "email": "dev@example.com"
    }
  },
  "cinnamon": {
    "desktop": {
      "interface": {
        "gtk-theme": "Mint-Y-Dark"
      }
    }
  }
}
```

### Gaming Setup
```json
{
  "packages": {
    "apt": {
      "repositories": ["ppa:graphics-drivers/ppa"],
      "packages": ["steam", "discord", "obs-studio"]
    }
  },
  "system": {
    "tweaks": {
      "swappiness": 1
    }
  }
}
```

---

## 🔍 Troubleshooting

### JSON Syntax Error
```bash
# Validate JSON
jq empty system-config.json

# Format JSON nicely
jq '.' system-config.json > formatted.json
```

### Setting Not Applying
- Some settings require logout
- Check if theme/icon is installed first
- Run `cinnamon --replace` to reload desktop

### Package Installation Fails
- Verify PPA is correct
- Check package name: `apt search package-name`
- May not be available for your Ubuntu version

---

## 🤝 Sharing Configurations

Share your config with the community:

1. Remove personal info (git email, etc.)
2. Add documentation in JSON comments (use description fields)
3. Upload to GitHub
4. Others can use: `curl -O https://raw.githubusercontent.com/user/repo/config.json`

---

## 📖 Full JSON Schema Reference

See [system-config.json](system-config.json) for a complete example with all available options.

Key sections:
- `metadata` - Config information
- `packages` - Software to install
- `cinnamon` - Desktop settings
- `nemo` - File manager
- `terminal` - Terminal appearance
- `gtk` - GTK themes and bookmarks
- `applications` - App-specific configs
- `git` - Git configuration
- `system` - System tweaks
- `fonts` - Font downloads

---

**Created for Linux Mint - Configuration as Code**
