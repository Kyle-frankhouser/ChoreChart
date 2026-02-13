# Panel Configuration Guide

The JSON configuration system now captures and restores your **complete panel layout**, including applet positions and panel properties.

## 📐 What Gets Captured

### Panel Properties
- **enabled-panels**: Which panels are active and where they're positioned
- **height**: Height of each panel in pixels
- **autohide**: Whether panels auto-hide
- **show-delay**: Delay before showing hidden panels
- **hide-delay**: Delay before hiding panels

### Applet Configuration
- **enabled-applets**: Complete list of all applets with their positions
- Each applet includes: panel, zone (left/center/right), order, name, and instance

## 🎯 Understanding Applet Format

Each applet is defined as:
```
panel1:left:0:menu@cinnamon.org:0
│      │    │  │                 │
│      │    │  │                 └─ Instance ID
│      │    │  └─────────────────── Applet UUID
│      │    └────────────────────── Order in zone
│      └─────────────────────────── Zone (left/center/right)
└────────────────────────────────── Panel ID
```

## ✏️ Customizing Panel Layout

### Move Applet to Different Zone

To move an applet (e.g., menu from left to center):

**Before:**
```json
"panel1:left:0:menu@cinnamon.org:0"
```

**After:**
```json
"panel1:center:0:menu@cinnamon.org:0"
```

Just change `left` → `center` or `right`!

### Reorder Applets

Change the order number to rearrange within a zone:

```json
"panel1:right:0:calendar@cinnamon.org:9",
"panel1:right:1:power@cinnamon.org:8",
"panel1:right:2:sound@cinnamon.org:7"
```

Lower numbers appear first (leftmost in right zone, rightmost in left zone).

### Remove an Applet

Simply delete the line from the `enabled-applets` array.

### Add an Applet

Add a new line with the applet UUID. Common applets:

```json
"panel1:left:0:menu@cinnamon.org:0",
"panel1:left:1:show-desktop@cinnamon.org:1",
"panel1:center:0:grouped-window-list@cinnamon.org:2",
"panel1:right:0:systray@cinnamon.org:3",
"panel1:right:1:notifications@cinnamon.org:4",
"panel1:right:2:calendar@cinnamon.org:5",
"panel1:right:3:power@cinnamon.org:6",
"panel1:right:4:sound@cinnamon.org:7",
"panel1:right:5:network@cinnamon.org:8",
"panel1:right:6:removable-drives@cinnamon.org:9"
```

Make sure to increment instance IDs (last number) to be unique.

## 🛠️ Panel Properties

### Change Panel Height

```json
{
  "panels": {
    "height": ["1:40"]
  }
}
```

Format: `"panelId:heightInPixels"`

Common heights: 24 (small), 32 (medium), 40 (default), 48 (large)

### Enable Auto-hide

```json
{
  "panels": {
    "autohide": ["1:true"]
  }
}
```

### Panel Position

```json
{
  "panels": {
    "enabled-panels": ["1:0:bottom"]
  }
}
```

Format: `"panelId:monitor:position"`
- Position: `top`, `bottom`, `left`, `right`
- Monitor: `0` for primary, `1` for secondary, etc.

## 📊 Viewing Your Layout

Use the included viewer to see your current panel layout:

```bash
./view-panel-layout.sh system-config-generated.json
```

Output shows:
```
  ┌─────────────────────────────────────────────────┐
  │ LEFT: show-desktop@cinnamon.org                 │
  │ CENTER: menu@cinnamon.org, grouped-window-list  │
  │ RIGHT: systray, calendar, power                 │
  └─────────────────────────────────────────────────┘
```

## 💡 Common Customizations

### Centered Taskbar (Windows-like)
Move window list and menu to center:
```json
"panel1:center:0:menu@cinnamon.org:0",
"panel1:center:1:grouped-window-list@cinnamon.org:2"
```

### Minimal Panel (macOS-like)
Keep only essentials:
```json
"panel1:left:0:show-desktop@cinnamon.org:1",
"panel1:center:0:grouped-window-list@cinnamon.org:2",
"panel1:right:0:calendar@cinnamon.org:3"
```

### Full-featured Panel
All common applets:
```json
"panel1:left:0:menu@cinnamon.org:0",
"panel1:left:1:show-desktop@cinnamon.org:1",
"panel1:center:0:grouped-window-list@cinnamon.org:2",
"panel1:right:0:systray@cinnamon.org:3",
"panel1:right:1:notifications@cinnamon.org:4",
"panel1:right:2:removable-drives@cinnamon.org:5",
"panel1:right:3:network@cinnamon.org:6",
"panel1:right:4:sound@cinnamon.org:7",
"panel1:right:5:power@cinnamon.org:8",
"panel1:right:6:calendar@cinnamon.org:9"
```

## 🔄 Workflow

1. **Generate** your current config:
   ```bash
   ./generate-config.sh
   ```

2. **View** the panel layout:
   ```bash
   ./view-panel-layout.sh system-config-generated.json
   ```

3. **Edit** the JSON to customize:
   ```bash
   nano system-config-generated.json
   ```

4. **Apply** the configuration:
   ```bash
   ./apply-config.sh system-config-generated.json
   ```

5. **Reload** Cinnamon to see changes:
   ```bash
   cinnamon --replace
   ```

## ⚠️ Important Notes

- **Instance IDs** should be unique across all applets
- **Orders** don't need to be sequential (0, 2, 5 works fine)
- Changes apply immediately when you run apply-config.sh
- Panel changes may require logging out or `cinnamon --replace`
- Don't remove essential applets unless you know what you're doing!

## 🧪 Testing Changes

Before applying to a fresh system:
1. Generate a config from your current setup
2. Make small edits to the JSON
3. Apply it to see the changes
4. If something breaks, just re-generate from your current system
5. Or restore from backup with `./restore.sh`

## 📋 Finding Applet UUIDs

To find available applet UUIDs:
```bash
ls ~/.local/share/cinnamon/applets/
ls /usr/share/cinnamon/applets/
```

Or browse online: https://cinnamon-spices.linuxmint.com/applets

## 🎨 Example Layouts

See the examples directory (if created) or check CONFIG-GUIDE.md for pre-made panel configurations you can copy.

---

**Pro Tip**: Keep multiple config files for different layouts:
- `config-work.json` - Productive, minimal
- `config-home.json` - Full-featured
- `config-presentation.json` - Clean, distraction-free
