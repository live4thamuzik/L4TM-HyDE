#!/usr/bin/env bash

# Waybar Theme Selector - Thin wrapper around waybar.py
# This script provides a user-friendly Rofi menu interface for waybar.py's theme management

scrDir=$(dirname "$(realpath "$0")")

# Initialize HyDE environment
if [[ "${HYDE_SHELL_INIT}" -ne 1 ]]; then
    # Try to find and source hyde-shell
    if command -v hyde-shell &> /dev/null; then
        eval "$(hyde-shell init)"
    elif [ -f "${HOME}/.local/bin/hyde-shell" ]; then
        eval "$("${HOME}/.local/bin/hyde-shell" init)"
    elif [ -f "${HOME}/.local/share/bin/hyde-shell" ]; then
        eval "$("${HOME}/.local/share/bin/hyde-shell" init)"
    else
        # Fallback: try to source globalcontrol.sh if available
        if [ -f "${HOME}/.local/share/bin/globalcontrol.sh" ]; then
            source "${HOME}/.local/share/bin/globalcontrol.sh"
        fi
    fi
fi

# Use waybar.py for all theme operations
# Try multiple locations
if [ -n "${LIB_DIR}" ]; then
    WAYBAR_PY="${LIB_DIR}/hyde/waybar.py"
elif [ -f "${HOME}/.local/lib/hyde/waybar.py" ]; then
    WAYBAR_PY="${HOME}/.local/lib/hyde/waybar.py"
else
    WAYBAR_PY="${HOME}/L4TM-HyDE/Configs/.local/lib/hyde/waybar.py"
fi

# Check if waybar.py exists
if [ ! -f "${WAYBAR_PY}" ]; then
    notify-send -a "HyDE Alert" "ERROR: waybar.py not found at ${WAYBAR_PY}"
    exit 1
fi

# Get list of available themes
get_theme_list() {
    waybarDir="${HOME}/.config/waybar"
    if [ -d "${waybarDir}/themes" ]; then
        find "${waybarDir}/themes" -name "theme-*.css" -type f | \
            sed 's|.*/theme-\(.*\)\.css|\1|' | sort
    fi
}

# Get current theme - try multiple methods
get_current_theme() {
    # Method 1: Try new waybar.py CLI argument
    current=$(python3 "${WAYBAR_PY}" --get-current-theme 2>/dev/null | tr -d '[:space:]')
    if [ -n "${current}" ] && [ "${current}" != "None" ]; then
        echo "${current}"
        return
    fi
    
    # Method 2: Read directly from state file
    state_file="${HOME}/.local/state/hyde/staterc"
    if [ -f "${state_file}" ]; then
        current=$(grep "^WAYBAR_THEME_NAME=" "${state_file}" 2>/dev/null | cut -d'=' -f2- | tr -d '[:space:]')
        if [ -n "${current}" ]; then
            echo "${current}"
            return
        fi
    fi
    
    # Method 3: Try to detect from theme.css file
    theme_file="${HOME}/.config/waybar/theme.css"
    if [ -f "${theme_file}" ]; then
        # Check if theme.css is the default
        # Look for the comment "HyDE Default Theme" (with capital H, D, D, T)
        # Also check if file only contains color definitions (no actual CSS rules)
        if grep -qiE "HyDE Default Theme|Hyde Default Theme" "${theme_file}" 2>/dev/null; then
            echo "default"
            return
        fi
        # Alternative: check if file is very small and only has @define-color (default is minimal)
        # Default theme.css is typically < 500 bytes and only has color definitions
        file_size=$(wc -c < "${theme_file}" 2>/dev/null | tr -d '[:space:]')
        if [ -n "${file_size}" ] && [ "${file_size}" -lt 1000 ]; then
            # Check if it only has @define-color lines (no actual CSS selectors)
            if ! grep -qE "^[a-zA-Z#\[]" "${theme_file}" 2>/dev/null; then
                # Only has @define-color, likely default
                echo "default"
                return
            fi
        fi
        
        # Try to find matching theme by checking if theme.css contains unique content from theme files
        # Since theme.css may have color vars prepended, we check for unique CSS rules
        while IFS= read -r theme_name; do
            [ -z "${theme_name}" ] && continue
            theme_css="${HOME}/.config/waybar/themes/theme-${theme_name}.css"
            if [ -f "${theme_css}" ]; then
                # Get a unique line from the theme file (skip comments and color definitions)
                unique_line=$(grep -v "^[[:space:]]*/\*" "${theme_css}" | grep -v "^[[:space:]]*\*" | grep -v "@define-color" | grep -v "^[[:space:]]*$" | head -1)
                if [ -n "${unique_line}" ] && grep -qF "${unique_line}" "${theme_file}" 2>/dev/null; then
                    echo "${theme_name}"
                    return
                fi
            fi
        done < <(get_theme_list)
    fi
    
    # Default fallback
    echo "default"
}

# Show Rofi menu for theme selection
show_theme_menu() {
    # Get theme configuration from HyDE
    font_scale="${ROFI_WAYBAR_STYLE_SCALE:-10}"
    [[ "${font_scale}" =~ ^[0-9]+$ ]] || font_scale=${ROFI_SCALE:-10}

    font_name=${ROFI_WAYBAR_STYLE_FONT:-$ROFI_FONT}
    font_name=${font_name:-$(get_hyprConf "MENU_FONT")}
    font_name=${font_name:-$(get_hyprConf "FONT")}
    font_name=${font_name:-"JetBrainsMono Nerd Font"}

    font_override="* {font: \"${font_name} ${font_scale}\";}"

    hypr_border=${hypr_border:-"$(hyprctl -j getoption decoration:rounding | jq '.int')"}
    hypr_border=${hypr_border:-2}
    elem_border=$((hypr_border * 3))
    
    # Calculate columns for grid layout
    mon_data=$(hyprctl -j monitors)
    mon_x_res=$(jq '.[] | select(.focused==true) | if (.transform % 2 == 0) then .width else .height end' <<<"${mon_data}")
    mon_scale=$(jq '.[] | select(.focused==true) | .scale' <<<"${mon_data}" | sed "s/\.//")
    
    mon_x_res=${mon_x_res:-1920}
    mon_scale=${mon_scale:-1}
    mon_x_res=$((mon_x_res * 100 / mon_scale))
    
    elm_width=$(((28 + 8 + 5) * font_scale))
    max_avail=$((mon_x_res - (4 * font_scale)))
    col_count=$((max_avail / elm_width))
    [[ "${col_count}" -lt 2 ]] && col_count=2
    [[ "${col_count}" -gt 5 ]] && col_count=5
    
    r_override="window{width:100%;}
listview{columns:${col_count};spacing:5em;}
element{border-radius:${elem_border}px;orientation:vertical;} 
element-icon{size:28em;border-radius:0em;}
element-text{padding:1em;}"

    # Get current theme (trim whitespace and convert to lowercase for comparison)
    current_theme=$(get_current_theme | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    
    # Debug: uncomment to see what's detected
    # echo "DEBUG: current_theme='${current_theme}'" >&2
    
    # Build menu items with preview images
    waybarDir="${HOME}/.config/waybar"
    preview_dir="${waybarDir}/themes/previews"
    
    # Initialize current_display_name (will be set if we find a match)
    current_display_name="Default (HyDE)"
    
    # Start with "Default (HyDE)" option
    menu_items=""
    # Check if current theme is "default" (case-insensitive, handle empty)
    if [ "${current_theme}" = "default" ] || [ -z "${current_theme}" ]; then
        menu_items="Default (HyDE) (current)\n"
        current_display_name="Default (HyDE) (current)"
    else
        menu_items="Default (HyDE)\n"
    fi
    
    # Add theme options
    while IFS= read -r theme_name; do
        [ -z "${theme_name}" ] && continue
        theme_name=$(echo "${theme_name}" | tr -d '[:space:]')  # Trim whitespace
        
        # Format display name (capitalize, replace dashes with spaces)
        display_name=$(echo "${theme_name}" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2));}1')
        
        # Check for preview image
        preview_path=""
        for ext in png jpg jpeg; do
            if [ -f "${preview_dir}/${theme_name}.${ext}" ]; then
                preview_path="${preview_dir}/${theme_name}.${ext}"
                break
            fi
        done
        
        # Mark current theme (exact match, case-sensitive)
        if [ "${theme_name}" = "${current_theme}" ]; then
            current_display_name="${display_name} (current)"
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
    done < <(get_theme_list)
    
    if [ -z "${menu_items}" ]; then
        notify-send -a "HyDE Alert" "No waybar themes found"
        exit 1
    fi
    
    # Show Rofi menu
    selected=$(echo -en "${menu_items}" | rofi -dmenu \
        -theme-str "${font_override}" \
        -theme-str "${r_override}" \
        -theme "${ROFI_WAYBAR_STYLE_STYLE:-selector}" \
        -select "${current_display_name}")
    
    if [ -z "${selected}" ]; then
        exit 0
    fi
    
    # Extract selected theme name (remove icon data and "(current)" marker)
    selected_clean=$(echo "${selected}" | awk -F'\x00' '{print $1}' | sed 's/ (current)//' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    
    # Handle "Default (HyDE)" option FIRST - before any theme matching
    # Check multiple variations to be sure - MUST exit if default
    selected_lower=$(echo "${selected_clean}" | tr '[:upper:]' '[:lower:]')
    # Remove parentheses and extra spaces for matching
    selected_normalized=$(echo "${selected_lower}" | sed 's/[()]//g' | sed 's/[[:space:]]\+/ /g' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    
    # Debug: log what was selected (write to file and notify)
    debug_file="${HOME}/.cache/hyde/waybar-style-debug.log"
    mkdir -p "$(dirname "${debug_file}")"
    {
        echo "=== DEBUG: Waybar Style Selection ==="
        echo "selected='${selected}'"
        echo "selected_clean='${selected_clean}'"
        echo "selected_lower='${selected_lower}'"
        echo "selected_normalized='${selected_normalized}'"
        echo "====================================="
    } > "${debug_file}"
    
    # Also show via notify for immediate feedback
    notify-send -a "HyDE Debug" "Selected: '${selected_clean}'\nNormalized: '${selected_normalized}'" -t 3000
    
    # Check if it's default - be very explicit and EXIT IMMEDIATELY
    case "${selected_normalized}" in
        "default hyde"|"default"|"default hyde (current)"|"default (current)")
            notify-send -a "HyDE Debug" "Matched default case!" -t 2000
            set_default_theme
            exit 0
            ;;
        default*)
            # Anything starting with "default" should be default
            notify-send -a "HyDE Debug" "Matched default* pattern!" -t 2000
            set_default_theme
            exit 0
            ;;
    esac
    
    # If we get here, default check failed
    notify-send -a "HyDE Debug" "Default check FAILED!\nNormalized: '${selected_normalized}'" -t 5000
    
    # Map display name back to theme name
    # First, try to match by comparing display names
    exact_match=""
    while IFS= read -r theme_name; do
        [ -z "${theme_name}" ] && continue
        # Format theme name to display name (like we did when building menu)
        theme_display=$(echo "${theme_name}" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2));}1')
        # Check if display names match (case-insensitive)
        if [ "$(echo "${theme_display}" | tr '[:upper:]' '[:lower:]')" = "$(echo "${selected_clean}" | tr '[:upper:]' '[:lower:]')" ]; then
            exact_match="${theme_name}"
            break
        fi
        # Also try first word matching (e.g., "Aniks" should match "aniks-super-waybar")
        # BUT: Skip if selected is "Default" or "Default (HyDE)" - we already handled that
        if echo "${selected_lower}" | grep -qE "^default"; then
            # Already handled default, skip first-word matching
            continue
        fi
        theme_first_word=$(echo "${theme_display}" | awk '{print $1}' | tr '[:upper:]' '[:lower:]')
        selected_first_word=$(echo "${selected_clean}" | awk '{print $1}' | tr '[:upper:]' '[:lower:]')
        if [ "${theme_first_word}" = "${selected_first_word}" ]; then
            exact_match="${theme_name}"
            break
        fi
    done < <(get_theme_list)
    
    if [ -n "${exact_match}" ]; then
        # Use waybar.py to set theme - it handles everything
        if python3 "${WAYBAR_PY}" --set-theme "${exact_match}" 2>/dev/null; then
            # Success - waybar.py handled it
            # Update state file to ensure it's set
            state_file="${HOME}/.local/state/hyde/staterc"
            mkdir -p "$(dirname "${state_file}")"
            if [ -f "${state_file}" ]; then
                sed -i '/^WAYBAR_THEME_NAME=/d' "${state_file}"
            fi
            echo "WAYBAR_THEME_NAME=${exact_match}" >> "${state_file}"
        else
            # waybar.py doesn't have --set-theme yet, handle it manually
            set_theme_manually "${exact_match}"
        fi
    else
        # Fallback: try with lowercase name
        theme_name=$(echo "${selected_clean}" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
        if python3 "${WAYBAR_PY}" --set-theme "${theme_name}" 2>/dev/null; then
            # Update state file
            state_file="${HOME}/.local/state/hyde/staterc"
            mkdir -p "$(dirname "${state_file}")"
            if [ -f "${state_file}" ]; then
                sed -i '/^WAYBAR_THEME_NAME=/d' "${state_file}"
            fi
            echo "WAYBAR_THEME_NAME=${theme_name}" >> "${state_file}"
        else
            # waybar.py doesn't have --set-theme yet, handle it manually
            set_theme_manually "${theme_name}"
        fi
    fi
}

# Set theme manually (when waybar.py doesn't have --set-theme yet)
set_theme_manually() {
    local theme_name="$1"
    theme_file="${HOME}/.config/waybar/theme.css"
    theme_css="${HOME}/.config/waybar/themes/theme-${theme_name}.css"
    state_file="${HOME}/.local/state/hyde/staterc"
    
    if [ ! -f "${theme_css}" ]; then
        notify-send -a "HyDE Alert" "Theme file not found: theme-${theme_name}.css"
        return 1
    fi
    
    # Read theme file and check if it has color definitions
    if grep -q "@define-color" "${theme_css}"; then
        # Theme has color definitions, just copy it
        cp "${theme_css}" "${theme_file}"
    else
        # Theme needs HyDE color variables, prepend them
        {
            echo "/* HyDE Color Variables */"
            echo "@define-color bar-bg rgba(0, 0, 0, 0);"
            echo "@define-color main-bg #13131D;"
            echo "@define-color main-fg #FFFFFF;"
            echo "@define-color wb-act-bg #6AA9C9;"
            echo "@define-color wb-act-fg #EFEFF5;"
            echo "@define-color wb-hvr-bg #020817;"
            echo "@define-color wb-hvr-fg #ae00f3;"
            echo "@define-color wb-color @main-fg;"
            echo "@define-color wb-act-color @wb-act-fg;"
            echo "@define-color wb-hvr-color @wb-hvr-fg;"
            echo ""
        } > "${theme_file}"
        cat "${theme_css}" >> "${theme_file}"
    fi
    
    # Update state file
    mkdir -p "$(dirname "${state_file}")"
    if [ -f "${state_file}" ]; then
        sed -i '/^WAYBAR_THEME_NAME=/d' "${state_file}"
    fi
    echo "WAYBAR_THEME_NAME=${theme_name}" >> "${state_file}"
    
    # Try to use waybar.py --set-theme if available (it handles everything including restart)
    if python3 "${WAYBAR_PY}" --set-theme "${theme_name}" 2>/dev/null; then
        # Success - waybar.py handled theme, layout, and restart
        notify-send -a "HyDE Alert" "Waybar theme changed to: ${theme_name}"
        return 0
    fi
    
    # Fallback: manual theme setting (waybar.py doesn't have --set-theme)
    # Try to switch to matching layout if it exists
    layout_file="${HOME}/.config/waybar/layouts/${theme_name}.jsonc"
    if [ -f "${layout_file}" ]; then
        if python3 "${WAYBAR_PY}" --set "${theme_name}" 2>/dev/null; then
            # Layout switched via waybar.py (this will restart Waybar)
            notify-send -a "HyDE Alert" "Waybar theme changed to: ${theme_name}"
            return 0
        elif [ -f "${HOME}/.config/waybar/config.jsonc" ]; then
            # Fallback: copy layout manually
            cp "${layout_file}" "${HOME}/.config/waybar/config.jsonc"
        fi
    fi
    
    # Update waybar (only if --set didn't restart it)
    # Note: --update does NOT restart Waybar, it just updates files
    # Waybar will reload automatically via file watcher or user can restart manually
    python3 "${WAYBAR_PY}" --update 2>/dev/null || true
    
    notify-send -a "HyDE Alert" "Waybar theme changed to: ${theme_name}"
}

# Set default theme directly (bypasses waybar.py if it doesn't have --set-theme)
set_default_theme() {
    theme_file="${HOME}/.config/waybar/theme.css"
    state_file="${HOME}/.local/state/hyde/staterc"
    
    # Create default theme.css
    cat > "${theme_file}" << 'THEME_EOF'
/* HyDE Default Theme */
/* This file is managed by HyDE's theming system */
/* Colors are defined dynamically via wallbash */

@define-color bar-bg rgba(0, 0, 0, 0);

@define-color main-bg #13131D;
@define-color main-fg #FFFFFF;

@define-color wb-act-bg #6AA9C9;
@define-color wb-act-fg #EFEFF5;

@define-color wb-hvr-bg #020817;
@define-color wb-hvr-fg #ae00f3;

@define-color wb-color @main-fg;
@define-color wb-act-color @wb-act-fg;
@define-color wb-hvr-color @wb-hvr-fg;
THEME_EOF
    
    # Update state file
    mkdir -p "$(dirname "${state_file}")"
    if [ -f "${state_file}" ]; then
        # Remove existing WAYBAR_THEME_NAME line if it exists
        sed -i '/^WAYBAR_THEME_NAME=/d' "${state_file}"
    fi
    # Add WAYBAR_THEME_NAME=default to state file
    echo "WAYBAR_THEME_NAME=default" >> "${state_file}"
    
    # Try to use waybar.py --set-theme if available (it handles everything including restart)
    if python3 "${WAYBAR_PY}" --set-theme "default" 2>/dev/null; then
        # Success - waybar.py handled theme, layout, and restart
        notify-send -a "HyDE Alert" "Reverted to HyDE default waybar theme"
        return 0
    fi
    
    # Fallback: manually set default and use the same method as set_theme("default") does
    # set_theme("default") does:
    # 1. Writes default theme.css
    # 2. Calls write_style_file() to regenerate style.css (IMPORTANT: imports theme.css)
    # 3. Calls all update functions
    # 4. main() calls restart_waybar()
    # 
    # The key is that write_style_file() regenerates style.css to import theme.css
    # waybar.py --update does NOT regenerate style.css, so we need to do it manually
    
    # Regenerate style.css using Python (same as set_theme() does)
    # This is critical - without this, style.css won't import the new theme.css
    python3 << 'PYTHON_EOF'
import sys
import os
sys.path.insert(0, os.path.expanduser("~/.local/lib/hyde"))
from waybar import write_style_file, resolve_style_path, get_current_layout_from_config, xdg_config_home

# Get current layout (same as set_theme() does)
current_layout = get_current_layout_from_config()
if current_layout:
    style_filepath = os.path.join(str(xdg_config_home()), "waybar", "style.css")
    style_path = resolve_style_path(current_layout)
    write_style_file(style_filepath, style_path)
    print(f"Regenerated style.css from layout: {current_layout}")
else:
    print("Warning: Could not determine current layout, style.css may not be regenerated")
PYTHON_EOF
    
    # Now regenerate all waybar configs (same as waybar.py --update does)
    python3 "${WAYBAR_PY}" --update 2>/dev/null || true
    
    # Now restart waybar using the same method as set_layout() does
    # set_layout() calls restart_waybar() which does: kill_waybar() then run_waybar()
    killall waybar 2>/dev/null || true
    sleep 0.2
    
    # Now start waybar using the same method as run_waybar() in waybar.py
    UNIT_NAME="hyde-${XDG_SESSION_DESKTOP:-Hyprland}-bar.service"
    
    # Use hyde-shell app (same as waybar.py's run_waybar() does)
    if command -v hyde-shell &> /dev/null && [ -f "${HOME}/.local/bin/hyde-shell" ]; then
        "${HOME}/.local/bin/hyde-shell" app -u "${UNIT_NAME}" -t service -- waybar 2>/dev/null || true
    elif command -v hyde-shell &> /dev/null; then
        hyde-shell app -u "${UNIT_NAME}" -t service -- waybar 2>/dev/null || true
    else
        # Fallback: use systemctl
        systemctl --user restart "${UNIT_NAME}" 2>/dev/null || {
            # Last resort: start waybar directly
            waybar --config "${HOME}/.config/waybar/config.jsonc" --style "${HOME}/.config/waybar/style.css" & disown 2>/dev/null || true
        }
    fi
    
    notify-send -a "HyDE Alert" "Reverted to HyDE default waybar theme"
}

# Navigate to next/previous theme
navigate_theme() {
    local direction="$1"  # "next" or "prev"
    
    if [ "${direction}" = "next" ]; then
        python3 "${WAYBAR_PY}" --next-theme
    else
        python3 "${WAYBAR_PY}" --prev-theme
    fi
}

# Main
case "${1}" in
    --select|-s|"")
        # Debug: log that script was called
        debug_file="${HOME}/.cache/hyde/waybar-style-debug.log"
        mkdir -p "$(dirname "${debug_file}")"
        echo "Script called at $(date)" > "${debug_file}"
        echo "Args: $@" >> "${debug_file}"
        show_theme_menu
        ;;
    --next|-n)
        navigate_theme "next"
        ;;
    --prev|-p|--previous)
        navigate_theme "prev"
        ;;
    --list|-l)
        get_theme_list
        ;;
    --current|-c)
        get_current_theme
        ;;
    --apply|-a)
        if [ -z "${2}" ]; then
            echo "Usage: $0 --apply <theme-name>"
            exit 1
        fi
        python3 "${WAYBAR_PY}" --set-theme "${2}"
        ;;
    *)
        echo "Usage: $0 [--select|-s] [--list|-l] [--current|-c] [--next|-n] [--prev|-p] [--apply|-a <theme>]"
        echo ""
        echo "  --select, -s    Show menu to select waybar theme"
        echo "  --list, -l     List available themes"
        echo "  --current, -c  Show current theme"
        echo "  --next, -n     Switch to next theme"
        echo "  --prev, -p     Switch to previous theme"
        echo "  --apply, -a    Apply a specific theme"
        exit 0
        ;;
esac
