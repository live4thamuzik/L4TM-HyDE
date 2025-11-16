# L4TM-HyDE

A personalized fork of [HyDE](https://github.com/HyDE-Project/HyDE) that installs Hyprland configured just like the maintainer's system - minimal but complete, with full `hyde-cli` and `hyde-shell` theming support, plus all your `.dots` configurations.

## What's Different from HyDE

### ✅ Kept (Core Value)
- **63 themes** - Full theming system with `hyde-shell` and `wallbash`
- **Hyprland features** - PyPrland, workflows, shader system, hyprlock/hypridle
- **Package management** - Core packages and install scripts
- **SDDM themes** - All SDDM themes preserved
- **Theme switching** - Full theme management system

### ❌ Removed (Complexity Reduction)
- **uwsm** - Unnecessary Wayland session manager
- **AUR integration** - Removed AUR helper scripts and complexity
- **Complex waybar system** - No more Python watchers or auto-overwrites
- **Auto-config overwrites** - Your configs stay your configs

### 🆕 Improved
- **Multi-GPU Support** - Automatic detection and driver installation for AMD, NVIDIA, and Intel
- **Shell Options** - bash (default), zsh, fish - no forced zsh
- **Terminal Options** - kitty (default), alacritty - no forced alacritty
- **Prompt Tools** - oh-my-posh (default for bash), starship - choice of prompt tools
- **Configuration Preservation** - Automatically backs up and protects your custom configs
- **Modular Hyprland** - Clean, organized config file structure

## Prerequisites

- **Arch Linux** base installation with system already configured
- **GPU drivers** already installed (handled by archinstall or user)
- User account with sudo privileges
- Internet connection

> **Note:** This fork assumes your system is already set up (including GPU drivers). It focuses on desktop environment configuration and theming, not system-level setup.

## Quick Start

```bash
git clone https://github.com/live4thamuzik/L4TM-HyDE.git
cd L4TM-HyDE
./Scripts/install.sh -i
```

### Installation Options

```bash
./Scripts/install.sh          # Full installation (packages + configs + services)
./Scripts/install.sh -i       # Install packages only
./Scripts/install.sh -r       # Restore configs only
./Scripts/install.sh -s       # Enable services only
./Scripts/install.sh -n       # Skip NVIDIA drivers (AMD/Intel only)
./Scripts/install.sh -t       # Dry run (test without executing)
```

## Key Features

### Essential Keybindings

- **Super + Delete** - Exit Hyprland
- **Super + Backspace** - Power menu
- **Super + L** - Lock screen
- **Super + A** - Application launcher
- **Super + T** - Terminal
- **Super + C** - Code editor (Cursor)
- **Super + slash** - Keybinds help

See [KEYBINDINGS.md](KEYBINDINGS.md) for complete reference.

### Shell & Terminal Options

- **Shells**: bash (default), zsh, fish
- **Terminals**: kitty (default), alacritty
- **Prompts**: oh-my-posh (default for bash), starship

### GPU Support

- **NVIDIA** - Automatic detection and driver installation
- **AMD** - Automatic detection and Mesa driver installation
- **Intel** - Automatic detection and driver installation
- **Mixed setups** - Supports systems with multiple GPUs

### Configuration Structure

- **Hyprland**: `~/.config/hypr/` (modular structure, matches maintainer's setup)
- **Waybar**: `~/.config/waybar/` (simple, direct configuration)
- **All `.dots`**: Complete configuration files from `Configs/` directory
- **No auto-overwrites** - Your configs are preserved
- **HyDE Theming**: Full `hyde-shell` and optional `hyde-cli` support with all 63 themes

## Differences Summary

| Feature | Original HyDE | L4TM-HyDE |
|---------|--------------|------------|
| **Shell** | zsh (forced) | bash (default), zsh, fish |
| **Terminal** | alacritty | kitty (default), alacritty |
| **Prompt** | starship only | oh-my-posh, starship |
| **Session Manager** | uwsm | None (direct Hyprland) |
| **Waybar** | Complex Python system | Simple, direct config |
| **GPU Support** | NVIDIA-focused | AMD, NVIDIA, Intel |
| **Config Management** | Auto-overwrites | User configs preserved |
| **Hyprland Structure** | Single large file | Modular, organized files |

## Perfect For

- **Archinstall integration** - Clean, minimal setup that matches the maintainer's system
- **Users who want themes without complexity** - Full HyDE theming system with `hyde-shell`
- **Bash/kitty/nvim users** (no more zsh/alacritty forcing)
- **AMD GPU users** - Proper AMD support out of the box
- **Custom configuration lovers** - Your configs stay yours
- **HyDE enthusiasts** - All 63 themes, `hyde-cli` support, and complete `.dots` included

## Themes

All 63 HyDE themes are available:

- Use `hyde-shell theme.import` to import themes from the gallery
- Use `hyde-shell theme` to switch between installed themes
- Use `hyde-shell wallbash` for dynamic wallpaper integration

### Optional: Hyde CLI

This fork defaults to `hyde-shell` commands only. However, you can optionally install the original HyDE's `Hyde` CLI (capital H) for a more structured command interface:

**During Installation:**
- The installer will prompt you to install Hyde CLI
- Choose "Yes" if you want it, or "No" to use hyde-shell only (default)

**Install Later:**
```bash
# If you have an AUR helper (yay, paru, etc.)
yay -S hyde-cli-git

# Or install manually from: https://github.com/kRHYME7/Hyde-cli
```

**With Hyde CLI installed, you can use:**
- `Hyde theme import` - Import themes from gallery
- `Hyde theme` - Theme management commands
- `Hyde wallpaper` - Wallpaper commands
- `Hyde waybar` - Waybar commands
- And more structured commands

**Without Hyde CLI (default):**
- `hyde-shell theme.import` - Import themes
- `hyde-shell theme` - Switch themes
- `hyde-shell wallbash` - Dynamic wallpaper colors

## Documentation

- **[KEYBINDINGS.md](KEYBINDINGS.md)** - Complete keybinding reference
- **[CHANGELOG.md](CHANGELOG.md)** - Version history and changes
- **[HYDE_CLI_COMPATIBILITY.md](HYDE_CLI_COMPATIBILITY.md)** - CLI command reference

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Test your changes
4. Submit a pull request

## Credits

- Original HyDE by [prasanthrangan](https://github.com/prasanthrangan)
- Current HyDE maintainer: [kRHYME7](https://github.com/kRHYME7)
- L4TM-HyDE fork and enhancements by [l4tm](https://github.com/live4thamuzik)
- Community contributions welcome

## License

Same license as original HyDE project
