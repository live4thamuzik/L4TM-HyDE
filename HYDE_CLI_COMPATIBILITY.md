# HyDE CLI Tool Compatibility

## ✅ Yes, L4TM-HyDE is fully compatible with both CLI tools!

This fork supports both `hyde-shell` (included by default) and `Hyde` CLI (optional installation).

## 🔧 Two CLI Systems Available

### 1. hyde-shell (Default - Always Included)

`hyde-shell` is the command-line interface for managing HyDE. It provides easy access to all HyDE features and scripts. This is included by default in L4TM-HyDE.

### 2. Hyde CLI (Optional - Install During Setup or Later)

`Hyde` (capital H) is a comprehensive CLI tool from [Hyde-cli](https://github.com/kRHYME7/Hyde-cli) that provides structured subcommands. It's optional and can be installed:
- **During installation:** Interactive prompt will ask if you want it
- **Later:** Install manually with `yay -S hyde-cli-git`

See [README.md](README.md#optional-hyde-cli) for installation instructions.

## 📋 Available Commands

### Core Commands
```bash
hyde-shell reload          # Reload HyDE configuration
hyde-shell wallbash        # Execute wallbash (theme colors)
hyde-shell version         # Show version information
hyde-shell pyinit          # Initialize Python environment
hyde-shell validate        # Validate configuration
```

### Theme Management

**With hyde-shell (default):**
```bash
hyde-shell theme.import    # Import themes from gallery
hyde-shell theme           # Theme selector (switch between installed themes)
hyde-shell wallbash        # Wallbash color management
```

**With Hyde CLI (optional):**
```bash
Hyde theme import          # Import themes from gallery
Hyde theme                 # Theme management commands
Hyde wallbash              # Wallbash commands
```

### Completions
```bash
hyde-shell completions bash    # Bash completions
hyde-shell completions zsh     # Zsh completions
hyde-shell completions fish    # Fish completions
```

## 🎯 All HyDE Scripts Available

The CLI provides access to all HyDE scripts:
- `animations.sh` - Animation presets
- `themeselect.sh` - Theme switching
- `wallbashtoggle.sh` - Wallbash modes
- `swwwallpaper.sh` - Wallpaper management
- `volumecontrol.sh` - Volume control
- `brightnesscontrol.sh` - Brightness control
- `gamelauncher.sh` - Game launcher
- `screenshot.sh` - Screenshot tool
- `rofilaunch.sh` - Rofi menus
- `gamemode.sh` - Gaming mode
- `workflows.sh` - Workflow switching
- And many more...

## 🔄 HyDE-Minimal Compatibility Changes

### What Was Modified
**`Configs/.local/bin/hyde-shell`** - Updated `hyde-logout()` function:
- ✅ Now checks if uwsm is installed before using it
- ✅ Falls back to direct Hyprland exit (default for HyDE-Minimal)
- ✅ Fully backward compatible with uwsm if user installs it
- ✅ No errors if uwsm is not present

### Why This Works
- hyde-shell uses path-based script detection
- All scripts are in `.local/lib/hyde/`
- HyDE-Minimal preserves all core scripts
- Only uwsm-specific code made optional

## 💡 Usage Examples

### Theme Management
```bash
# Switch themes interactively
hyde-shell theme

# Or use keybinding: Super + Shift + T
```

### Wallpaper Management
```bash
# Select wallpaper
hyde-shell swwwallselect.sh

# Next wallpaper
hyde-shell swwwallpaper.sh -n

# Or use keybinding: Super + Alt + Right
```

### Animations
```bash
# Change animation preset
hyde-shell animations.sh

# Or use keybinding: Super + Alt + A
```

### Wallbash (Color Themes)
```bash
# Toggle wallbash mode
hyde-shell wallbashtoggle.sh -m

# Or use keybinding: Super + Shift + R
```

## 🎨 All 63 Themes Work

All HyDE themes are fully compatible:
- Theme switching via `hyde-shell theme`
- Wallbash color integration
- Waybar theme support
- Hyprland theme support
- All theme scripts functional

## 🛠️ Python Tools

hyde-shell includes Python-based tools:
- `amdgpu.py` - AMD GPU monitoring
- `bookmarks.py` - Bookmark manager
- `cava.py` - Audio visualizer
- `configuration.py` - Config management
- `weather.py` - Weather widget
- And more...

All work perfectly with HyDE-Minimal!

## 🚀 Performance

hyde-shell performance in HyDE-Minimal:
- ✅ **Faster** - No uwsm overhead
- ✅ **Lighter** - Direct Hyprland integration
- ✅ **Simpler** - Fewer dependencies
- ✅ **Same features** - All commands available

## 📁 Script Locations

All scripts are in standard locations:
```
~/.local/bin/
├── hyde-shell          # Main CLI
├── hydectl             # Control daemon
├── hyde-ipc            # IPC communication
└── hyq                 # Query tool

~/.local/lib/hyde/
├── [150+ scripts]      # All HyDE scripts
└── pyutils/            # Python utilities

~/.local/share/hyde/
├── keybindings.conf    # Keybinds reference
├── config-registry.toml # Config registry
└── [theme data]        # Theme information
```

## 🔗 Integration with Keybindings

Most hyde commands are already bound to keys:
- **Super + Shift + T** - Theme selector
- **Super + Shift + W** - Wallpaper selector
- **Super + Shift + R** - Wallbash toggle
- **Super + Shift + A** - Animation selector
- **Super + Alt + Right** - Next wallpaper
- **Super + Alt + Left** - Previous wallpaper
- **Super + Alt + G** - Game mode toggle

## ⚙️ Configuration

hyde-shell respects HyDE-Minimal configurations:
- Reads from `~/.config/hypr/`
- Uses modular configuration structure
- Respects `userprefs.conf`
- Preserves user customizations

## 🐛 Troubleshooting

### If hyde-shell is not found:
```bash
# Ensure scripts are in PATH
echo $PATH | grep ".local/bin"

# If not, add to ~/.bashrc:
export PATH="$HOME/.local/bin:$PATH"
```

### If Python tools don't work:
```bash
# Initialize Python environment
hyde-shell pyinit
```

### If completions don't work:
```bash
# For bash, add to ~/.bashrc:
eval "$(hyde-shell completions bash)"

# For zsh, add to ~/.zshrc:
eval "$(hyde-shell completions zsh)"

# For fish:
hyde-shell completions fish | source
```

## ✨ New in HyDE-Minimal

Additional features that work with hyde-shell:
- ✅ AMD GPU detection and monitoring
- ✅ Enhanced game launcher
- ✅ Better bash integration
- ✅ oh-my-posh theme support
- ✅ Simplified configuration

## 📊 Compatibility Summary

| Feature | Original HyDE | L4TM-HyDE | Status |
|---------|--------------|-----------|--------|
| hyde-shell CLI | ✅ | ✅ | Full compatibility (default) |
| Hyde CLI (capital H) | ✅ | ⚠️ | Optional (install during setup or later) |
| Theme switching | ✅ | ✅ | All 63 themes work |
| Theme importing | ✅ | ✅ | `hyde-shell theme.import` or `Hyde theme import` |
| Wallbash | ✅ | ✅ | Full support |
| Python tools | ✅ | ✅ | All functional |
| Scripts access | ✅ | ✅ | All 150+ scripts |
| Shell completions | ✅ | ✅ | bash/zsh/fish |
| uwsm integration | ✅ | ⚠️ | Optional (not required) |
| Direct Hyprland | ⚠️ | ✅ | Improved (default) |

## 🎉 Conclusion

**L4TM-HyDE is 100% compatible with both CLI systems!**

**Default (hyde-shell):**
- ✅ Always included, no installation needed
- ✅ All features work: themes, wallpapers, wallbash, animations, workflows
- ✅ All scripts and tools accessible
- ✅ Python utilities functional
- ✅ Shell completions available

**Optional (Hyde CLI):**
- ⚠️ Install during setup (interactive prompt) or later with `yay -S hyde-cli-git`
- ✅ Provides structured commands: `Hyde theme import`, `Hyde wallpaper`, etc.
- ✅ Works alongside hyde-shell (both can be used)
- ✅ Same functionality, different interface

**Key Differences from Original:**
- uwsm is optional instead of required (simpler, more direct)
- Hyde CLI is optional instead of required (keeps fork minimal by default)
- All functionality preserved, just more flexible!

