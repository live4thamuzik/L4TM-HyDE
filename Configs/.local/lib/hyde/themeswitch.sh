#!/usr/bin/env bash
# shellcheck disable=SC2154

#// set variables

scrDir="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
source "${scrDir}/globalcontrol.sh"
[ -z "${HYDE_THEME}" ] && echo "ERROR: unable to detect theme" && exit 1
get_themes

#// define functions

Theme_Change() {
    local x_switch=$1

    # shellcheck disable=SC2154
    for i in "${!thmList[@]}"; do
        if [ "${thmList[i]}" == "${HYDE_THEME}" ]; then
            if [ "${x_switch}" == 'n' ]; then
                setIndex=$(((i + 1) % ${#thmList[@]}))
            elif [ "${x_switch}" == 'p' ]; then
                setIndex=$((i - 1))
            fi
            themeSet="${thmList[setIndex]}"
            break
        fi
    done
}

toml_write() {
    # Use kwriteconfig6 to write to config files in toml format
    local config_file=$1
    local group=$2
    local key=$3
    local value=$4

    if ! kwriteconfig6 --file "${config_file}" --group "${group}" --key "${key}" "${value}" 2>/dev/null; then
        if ! grep -q "^\[${group}\]" "${config_file}"; then
            echo -e "\n[${group}]\n${key}=${value}" >>"${config_file}"
        elif ! grep -q "^${key}=" "${config_file}"; then
            sed -i "/^\[${group}\]/a ${key}=${value}" "${config_file}"
        fi
    fi
}

#// evaluate options
quiet=false
while getopts "qnps:" option; do
    case $option in

    n) # set next theme
        Theme_Change n
        export xtrans="grow"
        ;;

    p) # set previous theme
        Theme_Change p
        export xtrans="outer"
        ;;

    s) # set selected theme
        themeSet="$OPTARG" ;;
    q)
        quiet=true
        ;;
    *) # invalid option
        echo "... invalid option ..."
        echo "$(basename "${0}") -[option]"
        echo "n : set next theme"
        echo "p : set previous theme"
        echo "s : set input theme"
        exit 1
        ;;
    esac
done

#// update control file

# shellcheck disable=SC2076
[[ ! " ${thmList[*]} " =~ " ${themeSet} " ]] && themeSet="${HYDE_THEME}"

set_conf "HYDE_THEME" "${themeSet}"
print_log -sec "theme" -stat "apply" "${themeSet}"

export reload_flag=1
# shellcheck disable=SC1091
source "${scrDir}/globalcontrol.sh"

#// hypr
if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    hyprctl keyword misc:disable_autoreload 1 -q
fi
# shellcheck disable=SC2154
sed '1d' "${HYDE_THEME_DIR}/hypr.theme" >"${confDir}/hypr/themes/theme.conf" # Useless and already handled by swwwallbash.sh but kept for robustness
# shellcheck disable=SC2154
if [ "${enableWallDcol}" -eq 0 ]; then
    gtkTheme="$(get_hyprConf "GTK_THEME")"
else
    gtkTheme="Wallbash-Gtk"
fi
gtkIcon="$(get_hyprConf "ICON_THEME")"
cursorTheme="$(get_hyprConf "CURSOR_THEME")"
font_name="$(get_hyprConf "FONT")"
monospace_font_name="$(get_hyprConf "MONOSPACE_FONT")"

# legacy and directory resolution
if [ -d /run/current-system/sw/share/themes ]; then
    export themesDir=/run/current-system/sw/share/themes
fi

if [ ! -d "${themesDir}/${gtkTheme}" ] && [ -d "$HOME/.themes/${gtkTheme}" ]; then
    cp -rns "$HOME/.themes/${gtkTheme}" "${themesDir}/${gtkTheme}"
fi

#// qt5ct

toml_write "${confDir}/qt5ct/qt5ct.conf" "Appearance" "icon_theme" "${gtkIcon}"
toml_write "${confDir}/qt5ct/qt5ct.conf" "Fonts" "general" "\"${font_name},10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,\""
toml_write "${confDir}/qt5ct/qt5ct.conf" "Fonts" "fixed" "\"${monospace_font_name},9,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,\""

# // qt6ct

toml_write "${confDir}/qt6ct/qt6ct.conf" "Appearance" "icon_theme" "${gtkIcon}"
toml_write "${confDir}/qt6ct/qt6ct.conf" "Fonts" "general" "\"${font_name},10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,\""
toml_write "${confDir}/qt6ct/qt6ct.conf" "Fonts" "fixed" "\"${monospace_font_name},9,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,\""

# // kde plasma

toml_write "${confDir}/kdeglobals" "Icons" "Theme" "${gtkIcon}"
toml_write "${confDir}/kdeglobals" "UISettings" "ColorScheme" "${gtkTheme}"
toml_write "${confDir}/kdeglobals" "General" "TerminalApplication" "${TERMINAL}"

# For KDE stuff

toml_write "${confDir}/kdeglobals" "KDE" "widgetStyle" "kvantum"
toml_write "${confDir}/kdeglobals" "Colors:View" "BackgroundNormal" "#00000000"

# // gtk2

sed -i -e "/^gtk-theme-name=/c\gtk-theme-name=\"${gtkTheme}\"" \
    -e "/^include /c\include \"$HOME/.gtkrc-2.0.mime\"" \
    -e "/^gtk-cursor-theme-name=/c\gtk-cursor-theme-name=\"${cursorTheme}\"" \
    -e "/^gtk-icon-theme-name=/c\gtk-icon-theme-name=\"${gtkIcon}\"" "$HOME/.gtkrc-2.0"

#// gtk3

sed -i -e "/^gtk-theme-name=/c\gtk-theme-name=\"${gtkTheme}\"" \
    -e "/^gtk-icon-theme-name=/c\gtk-icon-theme-name=\"${gtkIcon}\"" "$confDir/gtk-3.0/settings.ini"

#// gtk4
if [ -d "${themesDir}/${gtkTheme}/gtk-4.0" ]; then
    gtk4Theme="${gtkTheme}"
else
    gtk4Theme="Wallbash-Gtk"
    print_log -sec "theme" -stat "use" "'Wallbash-Gtk' as gtk4 theme"
fi
rm -rf "${confDir}/gtk-4.0"
ln -s "${themesDir}/${gtk4Theme}/gtk-4.0" "${confDir}/gtk-4.0"

#// flatpak GTK

if pkg_installed flatpak; then
    flatpak \
        --user override \
        --filesystem="${themesDir}":ro \
        --filesystem="$HOME/.themes":ro \
        --filesystem="$HOME/.icons":ro \
        --filesystem="$HOME/.local/share/icons":ro \
        --env=GTK_THEME="${gtk4Theme}" \
        --env=ICON_THEME="${gtkIcon}"

    flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo &

fi
# // xsettingsd

sed -i -e "/^Net\/ThemeName /c\Net\/ThemeName \"${gtkTheme}\"" \
    -e "/^Net\/IconThemeName /c\Net\/IconThemeName \"${gtkIcon}\"" \
    -e "/^Gtk\/CursorThemeName /c\Gtk\/CursorThemeName \"${cursorTheme}\"" \
    "$confDir/xsettingsd/xsettingsd.conf"

# // Legacy themes using ~/.themes also fixed GTK4 not following xdg

if [ ! -L "$HOME/.themes/${gtkTheme}" ] && [ -d "${themesDir}/${gtkTheme}" ]; then
    print_log -sec "theme" -warn "linking" "${gtkTheme} to ~/.themes to fix GTK4 not following xdg"
    mkdir -p "$HOME/.themes"
    rm -rf "$HOME/.themes/${gtkTheme}"
    ln -snf "${themesDir}/${gtkTheme}" "$HOME/.themes/"
fi

#// wallpaper
if [ "$quiet" = true ]; then
    "${scrDir}/swwwallpaper.sh" -s "$(readlink "${HYDE_THEME_DIR}/wall.set")" >/dev/null 2>&1
else
    "${scrDir}/swwwallpaper.sh" -s "$(readlink "${HYDE_THEME_DIR}/wall.set")"
fi
