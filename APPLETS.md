# Applet Configuration Guide

## Overview

The configuration system now captures and restores **individual applet settings** for all your panel applets. This includes custom date/time formats, menu preferences, and any other applet-specific customizations.

## What Gets Captured

### Automatically Captured Settings

When you run `./generate-config.sh`, the system captures:

1. **Panel layout** - Which applets are enabled and where they're positioned
2. **Applet-specific settings** - Individual configuration for each applet instance

### Applet Configs Location

Applet settings are stored in: `~/.config/cinnamon/spices/<applet-name>/<instance-id>.json`

## Example: Calendar Applet

The calendar applet is one of the most commonly customized. Here's what gets captured:

```json
{
  "cinnamon": {
    "applets": {
      "configs": {
        "calendar@cinnamon.org:13": {
          "use-custom-format": true,
          "custom-format": " %-m/%d/%Y    \\n %-I:%M:%S %p    ",
          "custom-tooltip-format": "%A, %b %-d %Y %-I:%M:%S %p",
          "show-events": true,
          "show-week-numbers": false,
          "keyOpen": "<Super>c"
        }
      }
    }
  }
}
```

### Calendar Format Options

Common date/time format codes:
- `%Y` - Year (4 digits)
- `%m` - Month (01-12)
- `%d` - Day (01-31)
- `%-m`, `%-d` - Month/day without leading zero
- `%H` - Hour 24-hour (00-23)
- `%I` - Hour 12-hour (01-12)
- `%M` - Minute (00-59)
- `%S` - Second (00-59)
- `%p` - AM/PM
- `%A` - Full weekday name
- `%a` - Abbreviated weekday name
- `%B` - Full month name
- `%b` - Abbreviated month name
- `\\n` - New line

**Example formats:**
- `%-m/%d/%Y %-I:%M %p` → `2/13/2026 3:45 PM`
- `%A, %B %-d` → `Thursday, February 13`
- `%Y-%m-%d %H:%M` → `2026-02-13 15:45`

## Other Commonly Configured Applets

### Menu Applet
- Menu icon and label
- Popup dimensions
- Sidebar visibility
- Icon sizes
- Hover behavior

### Grouped Window List
- Window grouping behavior
- Thumbnail settings
- Icon sizes
- Label display

### Sound/Network/Power
- Show percentages
- Icon preferences
- Notification settings

### Transparent Panels Extension
- Transparency levels
- Opacity settings
- Corner settings

## How It Works

### Capture Process

When you run `./generate-config.sh`:

1. Scans `~/.config/cinnamon/spices/` for all applet configs
2. Extracts only the `value` fields (actual settings, not UI metadata)
3. Stores them in JSON with format: `"applet-name:instance-id": {...}`
4. Skips buttons and sections (non-setting UI elements)

### Restore Process

When you run `./apply-config.sh`:

1. Creates applet directories if needed
2. If config file exists: Merges new values into existing structure
3. If config file missing: Builds from system schema + your values
4. Preserves full applet config structure required by Cinnamon

## Manual Editing

You can manually edit applet settings in your JSON config:

```bash
# Edit your config
nano system-config.json

# Find the applet you want to change
# For example, change calendar date format:
"calendar@cinnamon.org:13": {
  "custom-format": "%A %B %-d, %-I:%M %p"
}

# Apply the changes
./apply-config.sh system-config.json

# Restart Cinnamon to see changes
cinnamon --replace &
```

## Troubleshooting

### Config not applying?

1. **Restart Cinnamon**: Most applet changes require restarting the shell
   ```bash
   cinnamon --replace &
   ```

2. **Check instance ID**: Make sure the instance ID in your config matches the enabled-applets list
   ```bash
   gsettings get org.cinnamon enabled-applets | grep calendar
   ```

3. **Verify config file**: Check if the config was written
   ```bash
   cat ~/.config/cinnamon/spices/calendar@cinnamon.org/13.json
   ```

### Finding Applet Names

```bash
# List all your applet configs
ls ~/.config/cinnamon/spices/

# See enabled applets with instance IDs
gsettings get org.cinnamon enabled-applets
```

### View Current Settings

```bash
# See all applet configs in generated JSON
jq '.cinnamon.applets.configs | keys' system-config-generated.json

# View specific applet settings
jq '.cinnamon.applets.configs."calendar@cinnamon.org:13"' system-config-generated.json
```

## Complete Workflow Example

```bash
# 1. Customize your calendar in Cinnamon Settings
# Right-click panel → Applets → Calendar → Configure

# 2. Generate config to capture changes
./generate-config.sh

# 3. View what was captured
jq '.cinnamon.applets.configs."calendar@cinnamon.org:13"' system-config-generated.json

# 4. Copy to your main config
cp system-config-generated.json my-system-config.json

# 5. On a new machine, apply it
./apply-config.sh my-system-config.json

# 6. Restart Cinnamon
cinnamon --replace &
```

## Version Control Tips

```bash
# Track applet changes over time
git diff system-config.json | grep -A5 "applets"

# See calendar format changes
git log -p -- system-config.json | grep custom-format
```

## See Also

- [PANELS.md](PANELS.md) - Panel layout and positioning
- [CONFIG-GUIDE.md](CONFIG-GUIDE.md) - General configuration guide
- [VARIABLES.md](VARIABLES.md) - Using variables in configs
