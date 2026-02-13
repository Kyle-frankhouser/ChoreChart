#!/bin/bash

# Generate JSON Configuration from Current System
# This script reads your current system settings and creates a system-config.json file

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_FILE="${1:-$SCRIPT_DIR/system-config-generated.json}"

echo -e "${BLUE}=== Generating JSON Configuration from Current System ===${NC}\n"

# Install jq if needed
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}Installing jq...${NC}"
    sudo apt update && sudo apt install -y jq
fi

# Start building JSON
cat > "$OUTPUT_FILE" << 'EOF'
{
  "metadata": {
    "name": "My Linux Mint Configuration",
    "description": "Declarative system configuration",
    "version": "1.0",
EOF

echo "    \"created\": \"$(date +%Y-%m-%d)\"," >> "$OUTPUT_FILE"
echo "    \"author\": \"$USER\"" >> "$OUTPUT_FILE"
echo "  }," >> "$OUTPUT_FILE"

# Packages section
echo "  \"packages\": {" >> "$OUTPUT_FILE"
echo "    \"apt\": {" >> "$OUTPUT_FILE"
echo "      \"repositories\": [" >> "$OUTPUT_FILE"

# Extract PPAs
if [ -d "/etc/apt/sources.list.d" ]; then
    ppas=$(grep -rh "^deb .*ppa\.launchpad" /etc/apt/sources.list.d/ 2>/dev/null | \
           sed 's/deb http.*\/\(.*\)\/ubuntu.*/ppa:\1/' | \
           sort -u)
    
    first=true
    while IFS= read -r ppa; do
        if [ -n "$ppa" ]; then
            if [ "$first" = false ]; then echo "," >> "$OUTPUT_FILE"; fi
            echo -n "        \"$ppa\"" >> "$OUTPUT_FILE"
            first=false
        fi
    done <<< "$ppas"
fi

echo "" >> "$OUTPUT_FILE"
echo "      ]," >> "$OUTPUT_FILE"

# Manually installed packages (limit to most common ones to keep file manageable)
echo "      \"packages\": [" >> "$OUTPUT_FILE"
common_packages=$(apt-mark showmanual | grep -E "^(git|curl|wget|vim|neovim|htop|build-essential|python3-pip|nodejs|npm|docker|code|vlc|gimp|inkscape|obs-studio|timeshift|gparted)$" 2>/dev/null || true)

first=true
while IFS= read -r pkg; do
    if [ -n "$pkg" ]; then
        if [ "$first" = false ]; then echo "," >> "$OUTPUT_FILE"; fi
        echo -n "        \"$pkg\"" >> "$OUTPUT_FILE"
        first=false
    fi
done <<< "$common_packages"

echo "" >> "$OUTPUT_FILE"
echo "      ]" >> "$OUTPUT_FILE"
echo "    }," >> "$OUTPUT_FILE"

# Flatpak packages
echo "    \"flatpak\": {" >> "$OUTPUT_FILE"
if command -v flatpak &> /dev/null; then
    echo "      \"enable\": true," >> "$OUTPUT_FILE"
    echo "      \"packages\": [" >> "$OUTPUT_FILE"
    
    flatpaks=$(flatpak list --app --columns=application 2>/dev/null || true)
    first=true
    while IFS= read -r app; do
        if [ -n "$app" ]; then
            if [ "$first" = false ]; then echo "," >> "$OUTPUT_FILE"; fi
            echo -n "        \"$app\"" >> "$OUTPUT_FILE"
            first=false
        fi
    done <<< "$flatpaks"
    
    echo "" >> "$OUTPUT_FILE"
    echo "      ]" >> "$OUTPUT_FILE"
else
    echo "      \"enable\": false," >> "$OUTPUT_FILE"
    echo "      \"packages\": []" >> "$OUTPUT_FILE"
fi
echo "    }," >> "$OUTPUT_FILE"

# Snap packages
echo "    \"snap\": {" >> "$OUTPUT_FILE"
echo "      \"enable\": false," >> "$OUTPUT_FILE"
echo "      \"packages\": []" >> "$OUTPUT_FILE"
echo "    }" >> "$OUTPUT_FILE"
echo "  }," >> "$OUTPUT_FILE"

# Cinnamon settings
echo "  \"cinnamon\": {" >> "$OUTPUT_FILE"
echo "    \"desktop\": {" >> "$OUTPUT_FILE"
echo "      \"interface\": {" >> "$OUTPUT_FILE"

gtk_theme=$(gsettings get org.cinnamon.desktop.interface gtk-theme | tr -d "'")
icon_theme=$(gsettings get org.cinnamon.desktop.interface icon-theme | tr -d "'")
cursor_theme=$(gsettings get org.cinnamon.desktop.interface cursor-theme | tr -d "'")
cursor_size=$(gsettings get org.cinnamon.desktop.interface cursor-size)
clock_show_date=$(gsettings get org.cinnamon.desktop.interface clock-show-date)
clock_show_seconds=$(gsettings get org.cinnamon.desktop.interface clock-show-seconds)

cat >> "$OUTPUT_FILE" << EOF
        "cursor-blink-time": 1200,
        "cursor-size": $cursor_size,
        "gtk-theme": "$gtk_theme",
        "icon-theme": "$icon_theme",
        "cursor-theme": "$cursor_theme",
        "clock-show-date": $clock_show_date,
        "clock-show-seconds": $clock_show_seconds
EOF

echo "      }," >> "$OUTPUT_FILE"
echo "      \"wm\": {" >> "$OUTPUT_FILE"
echo "        \"preferences\": {" >> "$OUTPUT_FILE"

wm_theme=$(gsettings get org.cinnamon.desktop.wm.preferences theme | tr -d "'")
num_workspaces=$(gsettings get org.cinnamon.desktop.wm.preferences num-workspaces)
workspace_names=$(gsettings get org.cinnamon.desktop.wm.preferences workspace-names)

# Convert gsettings array format to JSON array
# @as [] becomes [], ['a', 'b'] stays as is
workspace_names=$(echo "$workspace_names" | sed "s/@as \\[\\]/[]/" | sed "s/@as //")

cat >> "$OUTPUT_FILE" << EOF
          "theme": "$wm_theme",
          "num-workspaces": $num_workspaces,
          "workspace-names": $workspace_names
EOF

echo "        }" >> "$OUTPUT_FILE"
echo "      }," >> "$OUTPUT_FILE"
echo "      \"background\": {" >> "$OUTPUT_FILE"

bg_uri=$(gsettings get org.cinnamon.desktop.background picture-uri | tr -d "'")
bg_options=$(gsettings get org.cinnamon.desktop.background picture-options | tr -d "'")

# Replace home directory with variable placeholder
bg_uri=$(echo "$bg_uri" | sed "s|file://$HOME|file://{HOME}|g")

cat >> "$OUTPUT_FILE" << EOF
        "picture-uri": "$bg_uri",
        "picture-options": "$bg_options"
EOF

echo "      }" >> "$OUTPUT_FILE"
echo "    }," >> "$OUTPUT_FILE"

# Settings daemon
echo "    \"settings-daemon\": {" >> "$OUTPUT_FILE"
echo "      \"peripherals\": {" >> "$OUTPUT_FILE"
echo "        \"keyboard\": {" >> "$OUTPUT_FILE"

kb_delay=$(gsettings get org.cinnamon.settings-daemon.peripherals.keyboard delay 2>/dev/null || echo "250")
kb_repeat=$(gsettings get org.cinnamon.settings-daemon.peripherals.keyboard repeat-interval 2>/dev/null || echo "30")

cat >> "$OUTPUT_FILE" << EOF
          "delay": $kb_delay,
          "repeat-interval": $kb_repeat
EOF

echo "        }," >> "$OUTPUT_FILE"
echo "        \"mouse\": {" >> "$OUTPUT_FILE"

mouse_double=$(gsettings get org.cinnamon.settings-daemon.peripherals.mouse double-click 2>/dev/null || echo "400")
mouse_speed=$(gsettings get org.cinnamon.settings-daemon.peripherals.mouse speed 2>/dev/null || echo "0.0")

cat >> "$OUTPUT_FILE" << EOF
          "double-click": $mouse_double,
          "speed": $mouse_speed
EOF

echo "        }" >> "$OUTPUT_FILE"
echo "      }" >> "$OUTPUT_FILE"
echo "    }," >> "$OUTPUT_FILE"

# Extensions (from enabled-extensions, not just directories)
echo "    \"extensions\": [" >> "$OUTPUT_FILE"
enabled_exts=$(gsettings get org.cinnamon enabled-extensions 2>/dev/null || echo "[]")
# Convert gsettings array to newline-separated list
enabled_exts=$(echo "$enabled_exts" | sed "s/^\[//; s/\]$//; s/', '/\n/g; s/'//g")

first=true
while IFS= read -r ext; do
    if [ -n "$ext" ] && [ "$ext" != "[]" ]; then
        if [ "$first" = false ]; then echo "," >> "$OUTPUT_FILE"; fi
        echo -n "      \"$ext\"" >> "$OUTPUT_FILE"
        first=false
    fi
done <<< "$enabled_exts"
echo "" >> "$OUTPUT_FILE"
echo "    ]," >> "$OUTPUT_FILE"

# Keyboard shortcuts
echo "    \"keybindings\": {" >> "$OUTPUT_FILE"

# Media keys
echo "      \"media-keys\": {" >> "$OUTPUT_FILE"
first=true
for key in $(gsettings list-keys org.cinnamon.desktop.keybindings.media-keys 2>/dev/null); do
    val=$(gsettings get org.cinnamon.desktop.keybindings.media-keys "$key" 2>/dev/null)
    # Only include non-empty bindings
    if [ "$val" != "@as []" ] && [ "$val" != "['']" ] && [ -n "$val" ]; then
        # Convert gsettings format to JSON
        val_json=$(echo "$val" | sed "s/'/\"/g")
        if [ "$first" = false ]; then echo "," >> "$OUTPUT_FILE"; fi
        echo -n "        \"$key\": $val_json" >> "$OUTPUT_FILE"
        first=false
    fi
done
echo "" >> "$OUTPUT_FILE"
echo "      }," >> "$OUTPUT_FILE"

# Window manager keys
echo "      \"wm\": {" >> "$OUTPUT_FILE"
first=true
for key in $(gsettings list-keys org.cinnamon.desktop.keybindings.wm 2>/dev/null); do
    val=$(gsettings get org.cinnamon.desktop.keybindings.wm "$key" 2>/dev/null)
    # Only include non-empty bindings
    if [ "$val" != "@as []" ] && [ "$val" != "['']" ] && [ -n "$val" ]; then
        # Convert gsettings format to JSON
        val_json=$(echo "$val" | sed "s/'/\"/g")
        if [ "$first" = false ]; then echo "," >> "$OUTPUT_FILE"; fi
        echo -n "        \"$key\": $val_json" >> "$OUTPUT_FILE"
        first=false
    fi
done
echo "" >> "$OUTPUT_FILE"
echo "      }" >> "$OUTPUT_FILE"
echo "    }," >> "$OUTPUT_FILE"

# Panel configuration
echo "    \"panels\": {" >> "$OUTPUT_FILE"

# Convert gsettings arrays to JSON arrays (single quotes to double quotes)
panels_enabled=$(gsettings get org.cinnamon panels-enabled | sed "s/'/\"/g")
panels_height=$(gsettings get org.cinnamon panels-height 2>/dev/null | sed "s/'/\"/g" || echo '[]')
panels_autohide=$(gsettings get org.cinnamon panels-autohide 2>/dev/null | sed "s/'/\"/g" || echo '[]')
panels_show=$(gsettings get org.cinnamon panels-show-delay 2>/dev/null | sed "s/'/\"/g" || echo '[]')
panels_hide=$(gsettings get org.cinnamon panels-hide-delay 2>/dev/null | sed "s/'/\"/g" || echo '[]')

cat >> "$OUTPUT_FILE" << EOF
      "enabled-panels": $panels_enabled,
      "height": $panels_height,
      "autohide": $panels_autohide,
      "show-delay": $panels_show,
      "hide-delay": $panels_hide
EOF

echo "    }," >> "$OUTPUT_FILE"

# Applets configuration
echo "    \"applets\": {" >> "$OUTPUT_FILE"
echo "      \"enabled-applets\": [" >> "$OUTPUT_FILE"

# Get and parse enabled-applets
enabled_applets=$(gsettings get org.cinnamon enabled-applets)
# Remove brackets and split by comma
enabled_applets=$(echo "$enabled_applets" | sed "s/^\[//; s/\]$//")

first=true
while IFS= read -r line; do
    # Remove quotes and whitespace
    applet=$(echo "$line" | sed "s/^[[:space:]]*'//; s/'[[:space:]]*$//; s/'[[:space:]]*,[[:space:]]*$//")
    if [ -n "$applet" ]; then
        if [ "$first" = false ]; then echo "," >> "$OUTPUT_FILE"; fi
        echo -n "        \"$applet\"" >> "$OUTPUT_FILE"
        first=false
    fi
done <<< "$(echo "$enabled_applets" | tr ',' '\n')"

echo "" >> "$OUTPUT_FILE"
echo "      ]," >> "$OUTPUT_FILE"

# Capture applet-specific configurations
echo "      \"configs\": {" >> "$OUTPUT_FILE"
if [ -d "$HOME/.config/cinnamon/spices" ]; then
    first_applet=true
    for applet_dir in "$HOME/.config/cinnamon/spices"/*; do
        if [ -d "$applet_dir" ]; then
            applet_name=$(basename "$applet_dir")
            for config_file in "$applet_dir"/*.json; do
                if [ -f "$config_file" ]; then
                    instance_id=$(basename "$config_file" .json)
                    if [ "$first_applet" = false ]; then echo "," >> "$OUTPUT_FILE"; fi
                    echo -n "        \"${applet_name}:${instance_id}\": " >> "$OUTPUT_FILE"
                    # Extract only the value fields from the config, skipping buttons and sections
                    jq 'to_entries | map(select(.value | type == "object" and has("value") and .type != "button" and .type != "section")) | map({key: .key, value: .value.value}) | from_entries' "$config_file" >> "$OUTPUT_FILE"
                    first_applet=false
                fi
            done
        fi
    done
fi
echo "" >> "$OUTPUT_FILE"
echo "      }" >> "$OUTPUT_FILE"
echo "    }" >> "$OUTPUT_FILE"
echo "  }," >> "$OUTPUT_FILE"

# Nemo settings
echo "  \"nemo\": {" >> "$OUTPUT_FILE"
echo "    \"preferences\": {" >> "$OUTPUT_FILE"

default_viewer=$(gsettings get org.nemo.preferences default-folder-viewer | tr -d "'")
show_hidden=$(gsettings get org.nemo.preferences show-hidden-files)

cat >> "$OUTPUT_FILE" << EOF
      "default-folder-viewer": "$default_viewer",
      "show-hidden-files": $show_hidden,
      "show-location-entry": false,
      "executable-text-activation": "ask"
EOF

echo "    }," >> "$OUTPUT_FILE"
echo "    \"list-view\": {" >> "$OUTPUT_FILE"
echo "      \"default-visible-columns\": [\"name\", \"size\", \"type\", \"date_modified\"]," >> "$OUTPUT_FILE"
echo "      \"default-zoom-level\": \"standard\"" >> "$OUTPUT_FILE"
echo "    }" >> "$OUTPUT_FILE"
echo "  }," >> "$OUTPUT_FILE"

# Terminal settings (simplified)
echo "  \"terminal\": {" >> "$OUTPUT_FILE"
echo "    \"profiles\": {" >> "$OUTPUT_FILE"
echo "      \"default\": {" >> "$OUTPUT_FILE"
echo "        \"background-color\": \"#2E3440\"," >> "$OUTPUT_FILE"
echo "        \"foreground-color\": \"#D8DEE9\"," >> "$OUTPUT_FILE"
echo "        \"use-system-font\": false," >> "$OUTPUT_FILE"
echo "        \"font\": \"Monospace 11\"," >> "$OUTPUT_FILE"
echo "        \"cursor-shape\": \"block\"," >> "$OUTPUT_FILE"
echo "        \"scrollback-lines\": 10000" >> "$OUTPUT_FILE"
echo "      }" >> "$OUTPUT_FILE"
echo "    }" >> "$OUTPUT_FILE"
echo "  }," >> "$OUTPUT_FILE"

# GTK settings
echo "  \"gtk\": {" >> "$OUTPUT_FILE"
echo "    \"gtk-3\": {" >> "$OUTPUT_FILE"
echo "      \"Settings\": {" >> "$OUTPUT_FILE"
cat >> "$OUTPUT_FILE" << EOF
        "gtk-application-prefer-dark-theme": 1,
        "gtk-theme-name": "$gtk_theme",
        "gtk-icon-theme-name": "$icon_theme",
        "gtk-font-name": "Sans 10",
        "gtk-cursor-theme-name": "$cursor_theme",
        "gtk-cursor-theme-size": $cursor_size
EOF
echo "      }" >> "$OUTPUT_FILE"
echo "    }," >> "$OUTPUT_FILE"

# GTK Bookmarks
echo "    \"bookmarks\": [" >> "$OUTPUT_FILE"
if [ -f "$HOME/.config/gtk-3.0/bookmarks" ]; then
    first=true
    while IFS= read -r bookmark; do
        if [ -n "$bookmark" ]; then
            # Replace home directory with variable placeholder
            bookmark_var=$(echo "$bookmark" | sed "s|$HOME|{HOME}|g")
            if [ "$first" = false ]; then echo "," >> "$OUTPUT_FILE"; fi
            echo -n "      \"$bookmark_var\"" >> "$OUTPUT_FILE"
            first=false
        fi
    done < "$HOME/.config/gtk-3.0/bookmarks"
fi
echo "" >> "$OUTPUT_FILE"
echo "    ]" >> "$OUTPUT_FILE"
echo "  }," >> "$OUTPUT_FILE"

# Applications
echo "  \"applications\": {" >> "$OUTPUT_FILE"
echo "    \"vscode\": {" >> "$OUTPUT_FILE"

if command -v code &> /dev/null; then
    echo "      \"install\": true," >> "$OUTPUT_FILE"
    echo "      \"extensions\": [" >> "$OUTPUT_FILE"
    
    extensions=$(code --list-extensions 2>/dev/null || true)
    first=true
    while IFS= read -r ext; do
        if [ -n "$ext" ]; then
            if [ "$first" = false ]; then echo "," >> "$OUTPUT_FILE"; fi
            echo -n "        \"$ext\"" >> "$OUTPUT_FILE"
            first=false
        fi
    done <<< "$extensions"
    
    echo "" >> "$OUTPUT_FILE"
    echo "      ]," >> "$OUTPUT_FILE"
    echo "      \"settings\": {}" >> "$OUTPUT_FILE"
else
    echo "      \"install\": false," >> "$OUTPUT_FILE"
    echo "      \"extensions\": []," >> "$OUTPUT_FILE"
    echo "      \"settings\": {}" >> "$OUTPUT_FILE"
fi

echo "    }" >> "$OUTPUT_FILE"
echo "  }," >> "$OUTPUT_FILE"

# Git configuration
echo "  \"git\": {" >> "$OUTPUT_FILE"

git_user_name=$(git config --global user.name 2>/dev/null || echo "")
git_user_email=$(git config --global user.email 2>/dev/null || echo "")
git_editor=$(git config --global core.editor 2>/dev/null || echo "vim")
git_branch=$(git config --global init.defaultBranch 2>/dev/null || echo "main")
git_rebase=$(git config --global pull.rebase 2>/dev/null || echo "false")

cat >> "$OUTPUT_FILE" << EOF
    "user": {
      "name": "$git_user_name",
      "email": "$git_user_email"
    },
    "core": {
      "editor": "$git_editor"
    },
    "init": {
      "defaultBranch": "$git_branch"
    },
    "pull": {
      "rebase": $git_rebase
    }
EOF

echo "  }," >> "$OUTPUT_FILE"

# System tweaks
echo "  \"system\": {" >> "$OUTPUT_FILE"
echo "    \"tweaks\": {" >> "$OUTPUT_FILE"
echo "      \"swappiness\": 10," >> "$OUTPUT_FILE"
echo "      \"vfs_cache_pressure\": 50," >> "$OUTPUT_FILE"
echo "      \"inotify_max_user_watches\": 524288" >> "$OUTPUT_FILE"
echo "    }," >> "$OUTPUT_FILE"
echo "    \"autostart\": []" >> "$OUTPUT_FILE"
echo "  }," >> "$OUTPUT_FILE"

# Software Sources/Mirrors
echo "  \"mirrors\": {" >> "$OUTPUT_FILE"
if [ -f "/etc/apt/sources.list.d/official-package-repositories.list" ]; then
    mint_mirror=$(grep "^deb.*mint/packages" /etc/apt/sources.list.d/official-package-repositories.list | head -1 | awk '{print $2}' || echo "")
    ubuntu_mirror=$(grep "^deb.*ubuntu.*noble main" /etc/apt/sources.list.d/official-package-repositories.list | head -1 | awk '{print $2}' || echo "")
    
    cat >> "$OUTPUT_FILE" << EOF
    "mint": "$mint_mirror",
    "ubuntu": "$ubuntu_mirror"
EOF
else
    echo "    \"mint\": \"\"," >> "$OUTPUT_FILE"
    echo "    \"ubuntu\": \"\"" >> "$OUTPUT_FILE"
fi
echo "  }," >> "$OUTPUT_FILE"

# Fonts
echo "  \"fonts\": {" >> "$OUTPUT_FILE"
echo "    \"download\": []" >> "$OUTPUT_FILE"
echo "  }" >> "$OUTPUT_FILE"

# Close JSON
echo "}" >> "$OUTPUT_FILE"

# Validate and format
if command -v jq &> /dev/null; then
    jq '.' "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"
fi

echo -e "\n${GREEN}✓ Configuration generated successfully!${NC}"
echo -e "${BLUE}Output file: ${OUTPUT_FILE}${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Review and edit the generated file"
echo -e "  2. Rename it to system-config.json (or keep separate configs)"
echo -e "  3. Apply with: ${BLUE}./apply-config.sh${NC}"
echo ""
