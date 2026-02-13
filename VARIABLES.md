# Configuration Variables

The JSON configuration files support variable placeholders for portable configurations across different users and systems.

## Supported Variables

| Variable | Expands To | Example |
|----------|------------|---------|
| `{HOME}` | User's home directory | `/home/username` |
| `{USER}` | Current username | `kyle` |

## Usage

### In JSON Configuration

Use placeholders anywhere you have user-specific paths:

```json
{
  "cinnamon": {
    "desktop": {
      "background": {
        "picture-uri": "file://{HOME}/Pictures/wallpaper.jpg"
      }
    }
  },
  "gtk": {
    "bookmarks": [
      "file://{HOME}/Documents",
      "file://{HOME}/Projects",
      "file://{HOME}/Downloads"
    ]
  }
}
```

### Automatic Substitution

**When Generating (`generate-config.sh`)**
- All instances of `/home/yourusername` are automatically replaced with `{HOME}`
- This makes configs portable across different users

**When Applying (`apply-config.sh`)**
- `{HOME}` is expanded to the current user's home directory (`$HOME`)
- `{USER}` is expanded to the current username (`$USER`)

## Examples

### System Paths (No Variables Needed)
These paths are the same for all users:
```json
{
  "picture-uri": "file:///usr/share/backgrounds/linuxmint/wallpaper.jpg"
}
```

### User-Specific Paths (Use Variables)
These paths are different for each user:
```json
{
  "picture-uri": "file://{HOME}/.local/share/backgrounds/my-wallpaper.jpg",
  "bookmarks": [
    "file://{HOME}/Documents",
    "file://{HOME}/code/projects"
  ]
}
```

### Mixed Paths
You can mix system and user paths:
```json
{
  "bookmarks": [
    "file://{HOME}/Documents",
    "file:///usr/share/backgrounds",
    "file://{HOME}/Projects"
  ]
}
```

## Benefits

✅ **Portability** - Share configs between different users  
✅ **Version Control** - No personal paths in git  
✅ **Multi-Machine** - Same config works across all your computers  
✅ **Privacy** - No usernames hardcoded in shared configs  

## Manual Editing

When manually editing JSON configs, remember to use `{HOME}` instead of:
- ❌ `/home/kyle/...`
- ❌ `~/...` (this is shell syntax, not valid in JSON paths)
- ✅ `file://{HOME}/...` (correct!)

## Technical Details

The variable expansion happens in [apply-config.sh](apply-config.sh) using `sed`:
```bash
path=$(echo "$path" | sed "s|{HOME}|$HOME|g")
path=$(echo "$path" | sed "s|{USER}|$USER|g")
```

This means:
- Variables are case-sensitive: `{HOME}` works, `{home}` does not
- Use curly braces: `{HOME}` not `$HOME` or `HOME`
- Variables work in any string value in the JSON

## Future Variables

You can easily add more variables by editing both scripts:

**In generate-config.sh:**
```bash
config=$(echo "$config" | sed "s|/etc/myapp|{SYSCONFIG}|g")
```

**In apply-config.sh:**
```bash
path=$(echo "$path" | sed "s|{SYSCONFIG}|/etc/myapp|g")
```

Common candidates:
- `{XDG_CONFIG_HOME}` - `~/.config`
- `{XDG_DATA_HOME}` - `~/.local/share`
- `{HOSTNAME}` - Machine name
- `{DISTRO}` - Linux distribution name
