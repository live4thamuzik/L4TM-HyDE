# Waybar Theme Module Compatibility Guide

## ⚠️ Important: Module Mismatch Issue

Many Waybar themes were designed for specific module configurations. If your active `config.ctl` layout doesn't include the modules a theme expects, the theme's styling won't apply correctly.

## Current Active Layout

Your active layout (from `config.ctl` line 25) includes:
- `hyprland/workspaces`, `wlr/taskbar`
- `idle_inhibitor`, `clock`, `custom/updates`
- `backlight`, `pulseaudio`, `pulseaudio#microphone`, `tray`, `battery`
- `custom/keybindhint`, `custom/cliphist`, `custom/power`
- Padding modules: `custom/padd`, `custom/l_end`, `custom/r_end`

## Themes That Require Additional Modules

### Themes Requiring System Monitoring Modules

These themes style `#cpu`, `#memory`, `#disk`, `#temperature` modules:

- **beautiful-waybar-theme** - Requires: `cpu`, `memory`, `temperature`
- **dn-debugs-waybar-config** - Requires: `cpu`, `memory`, `disk`
- **frankydolls-win10-like-configuration** - Requires: `cpu`, `memory`, `disk`, `temperature`

**Solution:** Add these modules to your `config.ctl` layout:
```
( cpu memory disk temperature ) ( ... )|( ... )|( ... )
```

### Themes Requiring Network Module

These themes style `#network`:

- **beautiful-waybar-theme** - Requires: `network`
- **dn-debugs-waybar-config** - Requires: `network`
- **frankydolls-win10-like-configuration** - Requires: `network`

**Solution:** Add `network` to your `config.ctl` layout.

### Themes Requiring Custom Modules

- **beautiful-waybar-theme** - Requires: `custom/launcher`, `custom/weather`, `custom/vpn`, `custom/notification`, `custom/cava`
- **dn-debugs-waybar-config** - Requires: `custom/launcher`, `custom/media`, `custom/layout`, `custom/updater`, `custom/snip`
- **frankydolls-win10-like-configuration** - Requires: `custom/os_button`

**Note:** These custom modules require corresponding scripts or configurations. Check if they exist before adding.

### Themes That Work With Current Layout

These themes primarily style modules you already have:

- **aniks-super-waybar** - Works with: `workspaces`, `taskbar`, `clock`, `pulseaudio`, `battery`, `tray`
- **cjbassis-configuration** - Works with: `workspaces`, `clock`, `pulseaudio`, `battery`, `cpu`, `memory`, `disk` (but you may need to add cpu/memory/disk)

## How to Add Modules to config.ctl

1. Edit `~/.config/waybar/config.ctl`
2. Find your active layout line (currently line 25)
3. Add missing modules in the appropriate position:
   ```
   1|40|top|( hyprland/workspaces wlr/taskbar cpu memory network )|( idle_inhibitor clock custom/updates )|( backlight pulseaudio pulseaudio#microphone tray battery custom/keybindhint custom/cliphist custom/power )
   ```
4. Run `hyde-shell waybar --update` or press `CTRL+ALT+W` to regenerate config

## Module Definitions

Make sure module definitions exist in:
- `~/.config/waybar/modules/*.jsonc`
- Or are included via `~/.config/waybar/includes/includes.json`

Common modules that should be available:
- `cpu`, `memory`, `disk`, `temperature` - System monitoring
- `network` - Network status
- `backlight` - Screen brightness
- `pulseaudio` - Audio
- `battery` - Battery status
- `tray` - System tray

## Testing Themes

After adding modules:
1. Select a theme via `SUPER+SHIFT+B`
2. Check if modules appear and are styled correctly
3. If modules don't appear, verify they're in `config.ctl` and module definitions exist

## Recommended Layout for Theme Compatibility

For maximum theme compatibility, consider using a layout that includes:
```
( hyprland/workspaces wlr/taskbar )|( idle_inhibitor clock custom/updates )|( cpu memory network backlight pulseaudio pulseaudio#microphone tray battery custom/keybindhint custom/cliphist custom/power )
```

This adds `cpu`, `memory`, and `network` while keeping your existing modules.

