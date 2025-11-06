# Waybar Theme Selection Notes

## Selected Themes from [Waybar Examples Wiki](https://github.com/Alexays/Waybar/wiki/Examples)

All themes listed below have been adapted to work with HyDE's dynamic theming system. Original creators and repositories:

1. **mechabar** - Created by [sejjy](https://github.com/sejjy/mechabar) | [Wiki Link](https://github.com/Alexays/Waybar/wiki/Examples#-mechabar)
2. **beautiful-waybar-theme** - Created by [Zilero232](https://github.com/Zilero232/arch-install-kit) | [Wiki Link](https://github.com/Alexays/Waybar/wiki/Examples#-beautiful-waybar-theme)
3. **cjbassis-configuration** - Created by [cjbassi](https://github.com/cjbassi/config) | [Wiki Link](https://github.com/Alexays/Waybar/wiki/Examples#cjbassis-configuration)
4. **macos-15-sequoia-configuration** - Created by [kamlendras](https://github.com/kamlendras/waybar-macos-sequoia) | [Wiki Link](https://github.com/Alexays/Waybar/wiki/Examples#macos-15-sequoia-configuration)
5. **aniks-super-waybar** - Created by [Anik200](https://github.com/Anik200/dotfiles) | [Wiki Link](https://github.com/Alexays/Waybar/wiki/Examples#aniks-super-waybar)
6. **whiteshadows-configuration** - Created by [elifouts](https://github.com/elifouts/Dotfiles) | [Wiki Link](https://github.com/Alexays/Waybar/wiki/Examples#whiteshadows-configuration)
7. **woioeows-configuration** - Created by [woioeow](https://github.com/woioeow/hyprland-dotfiles) | [Wiki Link](https://github.com/Alexays/Waybar/wiki/Examples#woioeows-configuration)
8. **frankydolls-win10-like-configuration** - Created by [TheFrankyDoll](https://github.com/TheFrankyDoll/win10-style-waybar) | [Wiki Link](https://github.com/Alexays/Waybar/wiki/Examples#frankydolls-win10-like-configuration)
9. **dn-debugs-waybar-config** - Created by [DN-debug](https://github.com/DN-debug/waybar-examples) | [Wiki Link](https://github.com/Alexays/Waybar/wiki/Examples#dn-debugs-waybar-config)
10. **notscripters-configuration** - Created by [notscripter](https://gitlab.com/notscripter/dotfiles) | [Wiki Link](https://github.com/Alexays/Waybar/wiki/Examples#notscripters-configuration)

**Note:** All styles have been modified to use HyDE's color variables (`@define-color` system) and integrated into the dynamic theming system. Original CSS files and configurations can be found in the respective repositories above.

## Currently Available Modules

Based on `config.ctl` and `includes.json`, you currently have:

### Core Modules
- `hyprland/workspaces`
- `hyprland/window`
- `wlr/taskbar`
- `clock`
- `idle_inhibitor`

### System Modules
- `cpu`
- `memory`
- `battery`
- `backlight`
- `network`
- `pulseaudio`
- `pulseaudio#microphone`
- `tray`
- `privacy`

### Custom Modules
- `custom/power`
- `custom/cliphist`
- `custom/wbar`
- `custom/theme`
- `custom/wallchange`
- `custom/keybindhint`
- `custom/updates`
- `custom/cpuinfo`
- `custom/gpuinfo`
- `custom/sensorsinfo`
- `custom/spotify`
- `custom/hyprsunset`
- `custom/weather`
- `custom/notifications`
- `custom/hyde-menu`

### Advanced Modules
- `mpris` (media player)
- `keyboard-state`
- `power-profiles-daemon`
- `custom/bluetooth`
- `custom/swaync`
- `custom/dunst`
- `group/*` modules (for grouping)

## Potentially Needed Modules (Based on Common Waybar Themes)

These modules are commonly used in waybar themes but may not be in your current config.ctl:

### System Monitoring
- **`temperature`** - CPU/GPU temperature monitoring
- **`disk`** - Disk usage monitoring
- **`load`** - System load average
- **`user`** - Current user display

### Media/Controls
- **`mpd`** - Music Player Daemon support (if you use MPD)
- **`cava`** - Audio visualizer (already have custom/cava)

### Networking
- **`network#bandwidthUpBytes`** - Upload bandwidth (seen in khing layout)
- **`network#bandwidthDownBytes`** - Download bandwidth (seen in khing layout)

### Custom Modules (Theme-Specific)
These might be needed depending on the themes:
- **`custom/separator`** - Separator elements
- **`custom/launcher`** - Application launcher button
- **`custom/notifications`** - Notification center (already have)
- **`custom/spotify`** - Spotify controls (already have)
- **`custom/mediaplayer`** - Generic media player (already have)

## Notes for config.ctl Updates

When adding these themes, you may need to:

1. **Add new modules to config.ctl** if themes require modules not currently listed
2. **Create module definitions** in `~/.config/waybar/modules/` for any custom modules
3. **Update includes.json** to include new module files
4. **Check for module dependencies** - some themes may require external scripts or tools

## Theme-Specific Considerations

### macOS 15 Sequoia Configuration
- May use macOS-style icons and spacing
- Might require specific icon themes
- Could use custom modules for macOS-like features

### Windows 10-like Configuration
- May use Windows-style taskbar positioning
- Could require specific window management modules
- Might need custom window grouping

### mechabar
- Appears to be a modern, clean design
- May use grouping modules extensively

## Action Items

Before adding themes:
1. ✅ Check each theme's GitHub/dotfiles link for required modules
2. ✅ Note any custom modules or scripts needed
3. ✅ Verify module configurations are compatible with Hyprland
4. ✅ Test each theme after adding to ensure modules work
5. ✅ Add missing modules to config.ctl if needed
6. ✅ Create preview images for each theme (screenshots from the wiki)

## Preview Images

Remember to add preview images for each theme:
- Place in `previews/` directory as `<theme-name>.png`
- Or in themes directory as `theme-<theme-name>.png`
- Use screenshots from the wiki or take your own

