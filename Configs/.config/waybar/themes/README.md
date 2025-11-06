# Waybar Theme Styles

This directory contains different waybar theme style files that can be switched on the fly.

## Available Styles

- **theme-islands.css** - Default rounded island style (solid background blocks)
- **theme-bubbles.css** - Individual rounded modules (floating bubbles)
- **theme-powerline.css** - Powerline character separators (requires config.jsonc update)

## Usage

### Via Menu
Right-click the HyDE menu button in waybar → Waybar → Select Theme Style

### Via Keybind
Press `SUPER+Shift+B` to open the style selector menu

### Via Command
```bash
hyde-shell waybar-style-select --select
```

## How It Works

The switcher uses a symlink approach:
- `theme.css` in `~/.config/waybar/` is a symlink to one of the theme files
- When you switch styles, the symlink is updated
- Waybar automatically reloads thanks to `"reload_style_on_change": true`

## Creating Custom Styles

### CSS-Only Themes (Simple)

1. Create a new file `theme-<your-style-name>.css` in this directory
2. Include color definitions using `@define-color`
3. Add styling rules for modules and endcaps
4. The style will automatically appear in the selector menu
5. Works with existing `config.ctl` layouts

### Full Preset Themes (Advanced)

To match a theme's preview exactly, create both:

1. **CSS File**: `theme-<your-style-name>.css` (styling)
2. **Preset File**: `presets/theme-<your-style-name>.preset.jsonc` (module layout)

**Preset Format:**
```jsonc
{
  "modules-left": ["hyprland/workspaces", "wlr/taskbar"],
  "modules-center": ["clock"],
  "modules-right": ["pulseaudio", "battery", "tray"]
}
```

When a user selects a theme with a preset:
- CSS styling is applied (via symlink)
- Module configuration is updated in `config.jsonc`
- Waybar auto-reloads to show the exact preview look

## Adding Preview Images

To show preview images in the selector menu (like theme and wallpaper selectors), add preview images:

**Option 1 (Recommended):** Place preview images in the `previews/` subdirectory:
- `previews/<style-name>.png` (or `.jpg`, `.jpeg`)
- Example: `previews/islands.png`, `previews/bubbles.png`

**Option 2:** Place preview images directly in the waybar themes directory:
- `theme-<style-name>.png` (or `.jpg`, `.jpeg`)
- Example: `theme-islands.png`, `theme-bubbles.png`

The script will automatically detect and display preview images in the rofi menu, giving users a visual preview of each style before selecting it.

## Powerline Style Notes

If using the powerline style, you need to update your `config.jsonc` to use powerline characters in the endcap modules:

```jsonc
"custom/l_end": {
    "format": "",  // Use powerline character
    "interval": "once",
    "tooltip": false
},
"custom/r_end": {
    "format": "",  // Use powerline character
    "interval": "once",
    "tooltip": false
}
```

Common powerline characters:
- ` ` (left) and ` ` (right) - rounded
- ` ` (left) and ` ` (right) - sharp arrows

