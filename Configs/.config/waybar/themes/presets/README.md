# Theme Presets

This directory contains module configuration presets for waybar themes.

## What Are Presets?

Presets are optional module configurations that can be applied alongside CSS themes to match the exact look of a theme's preview.

## When to Use Presets

- **CSS-Only Theme**: Just `theme-<name>.css` - works with existing `config.ctl` layouts
- **Full Preset Theme**: `theme-<name>.css` + `presets/theme-<name>.preset.jsonc` - matches preview exactly

## Preset File Format

Create a file named `theme-<name>.preset.jsonc` with this structure:

```jsonc
{
  "modules-left": [
    "hyprland/workspaces",
    "wlr/taskbar"
  ],
  "modules-center": [
    "clock"
  ],
  "modules-right": [
    "pulseaudio",
    "battery",
    "tray"
  ]
}
```

## How It Works

When a user selects a theme:
1. CSS is applied (via symlink)
2. If preset exists, modules are updated in `config.jsonc`
3. Waybar auto-reloads

## Example: macOS Sequoia Theme

**Files:**
- `../theme-macos-sequoia.css` - macOS styling
- `theme-macos-sequoia.preset.jsonc` - macOS module layout

**Result**: Both styling and modules change to match macOS Sequoia preview.

## Notes

- Presets are optional - themes work fine without them
- Presets only update `modules-left`, `modules-center`, `modules-right`
- Module definitions still come from `includes.json`
- Presets merge with existing `config.jsonc`, preserving other settings

