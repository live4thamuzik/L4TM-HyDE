#!/usr/bin/env bash

# Waybar Style Switcher
# Allows switching between different waybar theme styles (islands, bubbles, powerline, etc.)

scrDir=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1091
source "$scrDir/globalcontrol.sh"

confDir="${confDir:-$HOME/.config}"
waybarDir="${confDir}/waybar"
themeFile="${waybarDir}/theme.css"

# Check if waybar directory exists
if [ ! -d "${waybarDir}" ]; then
    echo "ERROR: Waybar config directory not found: ${waybarDir}"
    exit 1
fi

# Get list of available theme styles
get_theme_styles() {
    # Check both waybar directory and themes subdirectory
    find "${waybarDir}" -maxdepth 2 \( -name "theme-*.css" -o -path "*/themes/theme-*.css" \) -type f | \
        sort | \
        while read -r theme; do
            basename "${theme}" .css | sed 's/^theme-//'
        done
}

# Get current theme style
get_current_style() {
    if [ -L "${themeFile}" ]; then
        # It's a symlink, get the target
        target=$(readlink "${themeFile}")
        basename "${target}" .css | sed 's/^theme-//'
    elif [ -f "${themeFile}" ]; then
        # It's a regular file, check if it matches a theme pattern
        for style in $(get_theme_styles); do
            if [ -f "${waybarDir}/theme-${style}.css" ] && cmp -s "${themeFile}" "${waybarDir}/theme-${style}.css" 2>/dev/null; then
                echo "${style}"
                return
            elif [ -f "${waybarDir}/themes/theme-${style}.css" ] && cmp -s "${themeFile}" "${waybarDir}/themes/theme-${style}.css" 2>/dev/null; then
                echo "${style}"
                return
            fi
        done
        echo "default"
    else
        echo "default"
    fi
}

# Show rofi menu to select style
show_style_menu() {
    font_scale="${ROFI_WAYBAR_STYLE_SCALE:-10}"
    [[ "${font_scale}" =~ ^[0-9]+$ ]] || font_scale=${ROFI_SCALE:-10}

    font_name=${ROFI_WAYBAR_STYLE_FONT:-$ROFI_FONT}
    font_name=${font_name:-$(get_hyprConf "MENU_FONT")}
    font_name=${font_name:-$(get_hyprConf "FONT")}
    font_name=${font_name:-"JetBrainsMono Nerd Font"}

    font_override="* {font: \"${font_name}\" ${font_scale};}"

    # shellcheck disable=SC2154
    elem_border=$((hypr_border * 3))
    
    # Calculate columns for grid layout (similar to wallpaper selector)
    mon_data=$(hyprctl -j monitors)
    mon_x_res=$(jq '.[] | select(.focused==true) | if (.transform % 2 == 0) then .width else .height end' <<<"${mon_data}")
    mon_scale=$(jq '.[] | select(.focused==true) | .scale' <<<"${mon_data}" | sed "s/\.//")
    
    # Add fallback size
    mon_x_res=${mon_x_res:-1920}
    mon_scale=${mon_scale:-1}
    mon_x_res=$((mon_x_res * 100 / mon_scale))
    
    # Calculate column count based on element width
    elm_width=$(((28 + 8 + 5) * font_scale))
    max_avail=$((mon_x_res - (4 * font_scale)))
    col_count=$((max_avail / elm_width))
    [[ "${col_count}" -lt 2 ]] && col_count=2
    [[ "${col_count}" -gt 5 ]] && col_count=5
    
    r_override="window{width:100%;}
    listview{columns:${col_count};spacing:5em;}
    element{border-radius:${elem_border}px;
    orientation:vertical;} 
    element-icon{size:28em;border-radius:0em;}
    element-text{padding:1em;}"

    current_style=$(get_current_style)

    # Build menu items with preview images
    menu_items=""
    preview_dir="${waybarDir}/themes/previews"
    
    while read -r style; do
        if [ -n "${style}" ]; then
            # Capitalize first letter
            display_name=$(echo "${style}" | sed 's/^./\U&/')
            
            # Look for preview image
            preview_path=""
            # Check multiple possible locations/extensions
            for ext in png jpg jpeg; do
                if [ -f "${preview_dir}/${style}.${ext}" ]; then
                    preview_path="${preview_dir}/${style}.${ext}"
                    break
                elif [ -f "${waybarDir}/theme-${style}.${ext}" ]; then
                    preview_path="${waybarDir}/theme-${style}.${ext}"
                    break
                fi
            done
            
            # Build menu entry with icon if preview exists
            if [ "${style}" = "${current_style}" ]; then
                if [ -n "${preview_path}" ]; then
                    menu_items="${menu_items}${display_name} (current)\x00icon\x1f${preview_path}\n"
                else
                    menu_items="${menu_items}${display_name} (current)\n"
                fi
            else
                if [ -n "${preview_path}" ]; then
                    menu_items="${menu_items}${display_name}\x00icon\x1f${preview_path}\n"
                else
                    menu_items="${menu_items}${display_name}\n"
                fi
            fi
        fi
    done < <(get_theme_styles)

    if [ -z "${menu_items}" ]; then
        notify-send -a "HyDE Alert" "No waybar styles found in ${waybarDir}"
        exit 1
    fi

    # Show rofi menu
    selected=$(echo -en "${menu_items}" | rofi -dmenu \
        -theme-str "${font_override}" \
        -theme-str "${r_override}" \
        -theme "${ROFI_WAYBAR_STYLE_STYLE:-selector}" \
        -select "${current_style}")

    if [ -z "${selected}" ]; then
        exit 0
    fi

    # Extract style name (remove " (current)" if present and any icon data)
    selected_style=$(echo "${selected}" | awk -F'\x00' '{print $1}' | awk '{print $1}' | tr '[:upper:]' '[:lower:]')

    # Apply selected style
    apply_style "${selected_style}"
}

# Apply a style by creating/updating symlink
apply_style() {
    local style_name="$1"
    local target_file=""
    local preset_file=""
    
    # Check both locations for theme file
    if [ -f "${waybarDir}/theme-${style_name}.css" ]; then
        target_file="${waybarDir}/theme-${style_name}.css"
        symlink_target="theme-${style_name}.css"
    elif [ -f "${waybarDir}/themes/theme-${style_name}.css" ]; then
        target_file="${waybarDir}/themes/theme-${style_name}.css"
        symlink_target="themes/theme-${style_name}.css"
    else
        notify-send -a "HyDE Alert" "Style not found: theme-${style_name}.css"
        exit 1
    fi

    # Check for preset file
    if [ -f "${waybarDir}/themes/presets/theme-${style_name}.preset.jsonc" ]; then
        preset_file="${waybarDir}/themes/presets/theme-${style_name}.preset.jsonc"
    fi

    # Backup current theme.css if it's not a symlink
    if [ -f "${themeFile}" ] && [ ! -L "${themeFile}" ]; then
        cp "${themeFile}" "${themeFile}.backup.$(date +%s)"
    fi

    # Remove old symlink or file
    rm -f "${themeFile}"

    # Create new symlink
    ln -s "${symlink_target}" "${themeFile}"

    # Apply preset if it exists
    if [ -n "${preset_file}" ]; then
        apply_preset "${preset_file}" "${style_name}"
    fi

    # Notify user
    if [ -n "${preset_file}" ]; then
        notify-send -a "HyDE Alert" "Waybar style changed to: ${style_name} (with preset)"
    else
        notify-send -a "HyDE Alert" "Waybar style changed to: ${style_name}"
    fi

    # Waybar will auto-reload thanks to "reload_style_on_change": true
}

# Apply a preset module configuration
apply_preset() {
    local preset_file="$1"
    local style_name="$2"
    local config_file="${waybarDir}/config.jsonc"
    
    # Backup current config
    if [ -f "${config_file}" ]; then
        cp "${config_file}" "${config_file}.backup.$(date +%s)"
    fi
    
    # Check if preset file is valid JSONC
    if ! command -v jq &> /dev/null; then
        notify-send -a "HyDE Alert" "Warning: jq not found, cannot apply preset modules"
        return
    fi
    
    # Extract modules from preset
    local modules_left modules_center modules_right
    
    # Use Python to merge preset into config (preserves JSONC format better)
    if command -v python3 &> /dev/null; then
        python3 - "$preset_file" "$config_file" << 'PYEOF'
import json
import re
import sys

preset_file = sys.argv[1]
config_file = sys.argv[2]

# Read preset file
with open(preset_file, "r") as f:
    preset_content = f.read()

# Remove comments for parsing
preset_clean = re.sub(r'//.*?$', '', preset_content, flags=re.MULTILINE)
preset = json.loads(preset_clean)

# Extract modules from preset
modules_left = preset.get("modules-left")
modules_center = preset.get("modules-center")
modules_right = preset.get("modules-right")

# Read current config
with open(config_file, "r") as f:
    config_content = f.read()

# Remove comments for parsing
config_clean = re.sub(r'//.*?$', '', config_content, flags=re.MULTILINE)
config = json.loads(config_clean)

# Update modules arrays if they exist in preset
if modules_left is not None:
    config["modules-left"] = modules_left
if modules_center is not None:
    config["modules-center"] = modules_center
if modules_right is not None:
    config["modules-right"] = modules_right

# Write back with proper formatting
# Use json.dumps with indent to format, but preserve as JSONC
output = json.dumps(config, indent=4)

# Try to preserve some original formatting/comments by reading original and merging
# Simple approach: just write the updated JSON (waybar handles JSONC)
with open(config_file, "w") as f:
    # Write header comment if original had it
    if "generated by" in config_content.lower():
        f.write("//   --// waybar config generated by wbarconfgen.sh //--   //\n")
    f.write(output)
    f.write("\n")
PYEOF
        if [ $? -ne 0 ]; then
            notify-send -a "HyDE Alert" "Error applying preset modules"
            return
        fi
    else
        notify-send -a "HyDE Alert" "Warning: Python3 not found, cannot apply preset modules"
        return
    fi
}

# Navigate to next/previous style
navigate_style() {
    local direction="$1"  # "next" or "prev"
    local styles
    local current_style
    local current_index
    local new_index
    
    # Get list of styles
    readarray -t styles < <(get_theme_styles)
    
    if [ ${#styles[@]} -eq 0 ]; then
        notify-send -a "HyDE Alert" "No waybar styles found"
        exit 1
    fi
    
    # Get current style
    current_style=$(get_current_style)
    
    # Find current index
    current_index=-1
    for i in "${!styles[@]}"; do
        if [ "${styles[$i]}" = "${current_style}" ]; then
            current_index=$i
            break
        fi
    done
    
    # If current style not found, start at first style
    if [ $current_index -eq -1 ]; then
        current_index=0
    fi
    
    # Calculate new index
    if [ "${direction}" = "next" ]; then
        new_index=$(( (current_index + 1) % ${#styles[@]} ))
    else
        new_index=$(( (current_index - 1 + ${#styles[@]}) % ${#styles[@]} ))
    fi
    
    # Apply new style
    apply_style "${styles[$new_index]}"
}

# Main
case "${1}" in
    --select|-s)
        show_style_menu
        ;;
    --list|-l)
        get_theme_styles
        ;;
    --current|-c)
        get_current_style
        ;;
    --next|-n)
        navigate_style "next"
        ;;
    --prev|-p|--previous)
        navigate_style "prev"
        ;;
    --apply|-a)
        if [ -z "${2}" ]; then
            echo "Usage: $0 --apply <style-name>"
            exit 1
        fi
        apply_style "${2}"
        ;;
    *)
        echo "Usage: $0 [--select|-s] [--list|-l] [--current|-c] [--next|-n] [--prev|-p] [--apply|-a <style>]"
        echo ""
        echo "  --select, -s    Show menu to select waybar style"
        echo "  --list, -l     List available styles"
        echo "  --current, -c  Show current style"
        echo "  --next, -n     Switch to next style"
        echo "  --prev, -p     Switch to previous style"
        echo "  --apply, -a    Apply a specific style"
        exit 0
        ;;
esac
