# Waybar Theme Architecture

## Overview

The waybar style switcher supports two types of themes:

1. **CSS-Only Themes** - Just styling changes, works with existing `config.ctl` layouts
2. **Full Preset Themes** - CSS + module configuration to match the preview exactly

## Directory Structure

```
~/.config/waybar/themes/
├── theme-<name>.css          # CSS styling (required)
├── theme-<name>.png          # Preview image (optional)
└── presets/
    └── theme-<name>.preset.jsonc  # Module configuration (optional)
```

## How It Works

### CSS-Only Themes (Default Behavior)
- **File**: `theme-<name>.css`
- **Behavior**: Only changes the styling (colors, borders, spacing)
- **Modules**: Uses whatever modules are currently in `config.jsonc` (from `config.ctl`)
- **Use Case**: When you want to style existing layouts differently

### Full Preset Themes (Optional Enhancement)
- **Files**: 
  - `theme-<name>.css` (required)
  - `presets/theme-<name>.preset.jsonc` (optional)
- **Behavior**: Changes both styling AND module configuration
- **Modules**: Overrides `modules-left`, `modules-center`, `modules-right` from preset
- **Use Case**: When you want to match a theme's preview exactly (e.g., macOS Sequoia, Windows 10)

## Preset File Format

A preset file (`theme-<name>.preset.jsonc`) defines the module layout:

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

## Theme Selection Flow

When a user selects a theme:

1. **Apply CSS**: Update `theme.css` symlink → `theme-<name>.css`
2. **Check for Preset**: Look for `presets/theme-<name>.preset.jsonc`
3. **If Preset Exists**:
   - Backup current `config.jsonc` (optional)
   - Merge preset modules into `config.jsonc`
   - Or create a temporary layout file
4. **If No Preset**: 
   - Keep existing `config.jsonc` (from `config.ctl`)
   - Only CSS changes apply
5. **Restart Waybar**: Auto-reloads (if enabled)

## Integration with config.ctl

The `config.ctl` system remains the primary way to manage layouts:
- `config.ctl` defines available layouts
- Theme presets can override modules for specific themes
- User can still use `config.ctl` layouts with any CSS theme

## Benefits

✅ **Flexibility**: Themes can be CSS-only or full presets
✅ **Backward Compatible**: Existing `config.ctl` layouts still work
✅ **Preview Matching**: Themes can exactly match their previews
✅ **Hybrid Approach**: Use `config.ctl` layouts with theme CSS

## Example: macOS Sequoia Theme

**Files:**
- `themes/theme-macos-sequoia.css` - macOS styling
- `themes/presets/theme-macos-sequoia.preset.jsonc` - macOS module layout
- `themes/previews/macos-sequoia.png` - Preview image

**Result**: When selected, both styling AND module layout change to match macOS Sequoia.

## Example: Simple Color Theme

**Files:**
- `themes/theme-dark-blue.css` - Just color changes
- No preset file

**Result**: When selected, only colors change. Modules stay as defined in `config.ctl`.

