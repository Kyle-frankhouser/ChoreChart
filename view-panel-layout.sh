#!/bin/bash

# View Panel Layout
# Shows a visual representation of your panel configuration from JSON

CONFIG_FILE="${1:-system-config-generated.json}"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Usage: $0 [config-file.json]"
    echo "Config file not found: $CONFIG_FILE"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "jq is required. Install with: sudo apt install jq"
    exit 1
fi

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              Panel Configuration Viewer                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Panel properties
echo -e "${YELLOW}Panel Properties:${NC}"
jq -r '.cinnamon.panels | 
  "  Enabled Panels: \(.["enabled-panels"] | join(", "))\n" +
  "  Height: \(.height | join(", "))\n" +
  "  Autohide: \(.autohide | join(", "))\n" +
  "  Show Delay: \(.["show-delay"] | join(", "))\n" +
  "  Hide Delay: \(.["hide-delay"] | join(", "))"' "$CONFIG_FILE"

echo ""
echo -e "${YELLOW}Panel Layout:${NC}"

# Parse and display applets
declare -A left_applets
declare -A center_applets  
declare -A right_applets

# Read applets
while IFS= read -r applet; do
    if [ -n "$applet" ]; then
        # Parse: panel1:left:0:menu@cinnamon.org:0
        IFS=':' read -r panel zone order name instance <<< "$applet"
        
        # Store in appropriate array
        case $zone in
            left)
                left_applets[$order]="$name"
                ;;
            center)
                center_applets[$order]="$name"
                ;;
            right)
                right_applets[$order]="$name"
                ;;
        esac
    fi
done < <(jq -r '.cinnamon.applets["enabled-applets"][]' "$CONFIG_FILE")

# Display layout
echo ""
echo "  ┌─────────────────────────────────────────────────────────────────────┐"
echo -n "  │ LEFT: "

# Sort and display left applets
if [ ${#left_applets[@]} -gt 0 ]; then
    first=true
    for key in $(echo "${!left_applets[@]}" | tr ' ' '\n' | sort -n); do
        if [ "$first" = false ]; then echo -n ", "; fi
        echo -n "${left_applets[$key]}"
        first=false
    done
else
    echo -n "(none)"
fi
echo " │"

echo -n "  │ CENTER: "
# Sort and display center applets
if [ ${#center_applets[@]} -gt 0 ]; then
    first=true
    for key in $(echo "${!center_applets[@]}" | tr ' ' '\n' | sort -n); do
        if [ "$first" = false ]; then echo -n ", "; fi
        echo -n "${center_applets[$key]}"
        first=false
    done
else
    echo -n "(none)"
fi
echo " │"

echo -n "  │ RIGHT: "
# Sort and display right applets
if [ ${#right_applets[@]} -gt 0 ]; then
    first=true
    for key in $(echo "${!right_applets[@]}" | tr ' ' '\n' | sort -n); do
        if [ "$first" = false ]; then echo -n ", "; fi
        echo -n "${right_applets[$key]}"
        first=false
    done
else
    echo -n "(none)"
fi
echo " │"

echo "  └─────────────────────────────────────────────────────────────────────┘"

echo ""
echo -e "${GREEN}Total applets: $((${#left_applets[@]} + ${#center_applets[@]} + ${#right_applets[@]}))${NC}"
echo ""
echo -e "${BLUE}Tip: To move applets, edit the zone in enabled-applets${NC}"
echo -e "${BLUE}     Format: panel:zone:order:applet@name:instance${NC}"
echo ""
