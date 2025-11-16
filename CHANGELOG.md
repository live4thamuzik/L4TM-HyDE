# Changelog - L4TM-HyDE

All notable changes to this project will be documented in this file.

## [1.0.2] - 2025-11-05

### Fixed
- Power button menu now uses correct 2x2 grid layout
- Lock button functionality in both Waybar and SUPER+Backspace menus

## [1.0.1] - 2025-10-19

### Fixed
- **Power Management System**
  - Fixed wlogout layout with proper lock, logout, suspend, hibernate actions
  - Fixed keybinding conflicts with existing HyDE shortcuts
  - Added comprehensive power management keybindings
  - Resolved Super key functionality issues
  - Updated all power-related documentation

### Updated
- **Keybindings Documentation**
  - Created comprehensive KEYBINDINGS.md with all shortcuts
  - Updated README.md with essential keybindings section
  - Fixed waybar configuration integration
  - Added power management shortcuts reference

## [1.0.0] - 2025-10-19

### Added
- **Enhanced GPU Detection** (`Scripts/gpu_detection.sh`)
  - Support for NVIDIA, AMD, and Intel GPUs
  - Automatic driver installation for all GPU types
  - Smart GPU prioritization (dedicated over integrated)
  - Multi-GPU support for hybrid systems
  
- **Bash Prompt Management** (`Scripts/bash_prompt_manager.sh`)
  - Unified management for bash prompts
  - oh-my-posh and starship support
  - Automatic installation and configuration
  - User-friendly prompt selection
  
- **oh-my-posh Integration**
  - `Scripts/install_oh_my_posh.sh` - AUR and GitHub installation
  - `Scripts/setup_oh_my_posh.sh` - Configuration and theme setup
  - Themes installed to `~/oh-my-posh/themes/`
  - Automatic bashrc integration
  
- **Configuration Preservation System**
  - Dolphin file manager settings backup/restore
  - Hyprland modular configuration backup/restore
  - Protection markers (`.hyde.bkp`) to prevent overwrites
  - Automatic backup during installation
  - Automatic restoration after configuration

- **Modular Hyprland Configuration**
  - Incorporated user's clean, modular Hyprland structure
  - Separate files for different components:
    - `hyprland.conf` - Main configuration
    - `userprefs.conf` - User customizations
    - `keybindings.conf` - All keybindings
    - `windowrules.conf` - Window management
    - `animations.conf` - Animation settings
    - `monitors.conf` - Monitor configuration
    - `amdgpu.conf` - AMD GPU settings
    - `hypridle.conf` - Idle daemon
    - `hyprlock.conf` - Lock screen
    - `pyprland.toml` - PyPrland plugins
    - `shaders.conf` - Shader effects
    - `workflows.conf` - Workflow automation

### Changed
- **`Scripts/install.sh`**
  - Added GPU detection for all types (not just NVIDIA)
  - Added configuration backup for Dolphin and Hyprland
  - Added bash prompt management
  - Updated help text for better clarity
  
- **`Scripts/global_fn.sh`**
  - Added bash to shell list (`shlList`)
  - Integrated GPU detection functions
  - Improved error handling
  
- **`Scripts/restore_shl.sh`**
  - Added bash prompt selection (oh-my-posh/starship)
  - Automatic oh-my-posh installation offer
  - Graceful handling when shells not installed
  - Better user experience with clear prompts
  
- **`Scripts/restore_cfg.sh`**
  - Added Dolphin configuration functions
  - Added Hyprland configuration functions
  - Integrated automatic restoration
  - Better logging and user feedback
  
- **`Scripts/restore_cfg.lst`**
  - Added Dolphin configuration entries
  - Added Hyprland modular configuration entries
  
- **`Scripts/pkg_core.lst`**
  - Added: bash, bash-completion, alacritty
  - Commented out: uwsm, vim (using nvim)
  - Added shell options: zsh, fish
  - Added prompt tools: starship, starship-git
  
- **`Configs/.local/share/hyde/keybindings.conf`**
  - Updated to match user's actual keybindings
  - Correct application assignments (kitty, cursor, dolphin, brave)
  - Added BlueMail email client shortcut
  - Added Remmina RDP client shortcut
  - Added game launcher binding (Alt+Shift+Space)
  - Accurate descriptions for all bindings

### Removed
- **uwsm** - Unnecessary Wayland session manager complexity
- **vim** - User prefers nvim
- **Auto-overwrite system** - User configs are now preserved
- **Complex waybar Python watchers** - Simplified to direct config

### Fixed
- GPU detection now supports AMD (not just NVIDIA)
- Shell selection works with bash as default
- Configuration overwrites prevented with backup system
- Keybinding descriptions match actual implementation
- oh-my-posh themes properly copied to home directory

### Improved
- **User Experience**
  - Clearer prompts and feedback
  - Better error messages
  - Configuration preservation (no more lost settings)
  - Modular configuration (easier to customize)
  
- **Hardware Support**
  - Proper AMD GPU detection and driver installation
  - Intel GPU support
  - NVIDIA GPU support maintained
  - Multi-GPU system support
  
- **Shell Support**
  - bash (default) with oh-my-posh or starship
  - zsh with starship
  - fish with starship
  
- **Configuration Management**
  - Modular Hyprland structure (easier to work with)
  - User settings preserved across updates
  - Protection system prevents accidental overwrites
  - Automatic backup and restore

## [0.9.0] - Initial Fork

### Forked from
Original HyDE by [prasanthrangan](https://github.com/prasanthrangan)
Currently maintained by [kRHYME7](https://github.com/kRHYME7)

### Goals
- Simplify installation and configuration
- Remove unnecessary complexity (uwsm, complex waybar)
- Add proper bash support
- Preserve user configurations
- Improve hardware detection
- Create modular, maintainable structure

---

**Note**: Version numbers follow semantic versioning (MAJOR.MINOR.PATCH)

