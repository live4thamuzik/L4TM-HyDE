# Archinstall Integration - Current Limitations & Solutions

## 🚨 Current Issues for Archinstall Integration

### 1. **Interactive Prompts**
**Problem**: Scripts use interactive prompts that don't work well in automated environments
- AUR helper selection
- Shell selection  
- Prompt tool selection
- oh-my-zsh installation prompts

**Impact**: Would hang during archinstall automated installation

### 2. **Timing Issues**
**Problem**: Scripts expect to run post-installation with a logged-in user
- Requires `$HOME` to be set
- Needs user context
- Assumes system is fully booted

**Impact**: Won't work during archinstall's chroot phase

### 3. **Dependencies**
**Problem**: Circular dependency issues
- Scripts need packages that they're trying to install
- Git clone requires git to be installed
- AUR helpers need base-devel

**Impact**: Installation order matters

### 4. **File System Expectations**
**Problem**: Scripts assume certain paths exist
- `~/.config/` directories
- `~/.local/` directories
- `/tmp/` access

**Impact**: May fail in chroot environment

## ✅ Solutions for Better Integration

### Option 1: Environment Variables (Quick Fix)

Add to scripts to support non-interactive mode:

```bash
# In install.sh
# Check for automation mode
HYDE_AUTO_INSTALL="${HYDE_AUTO_INSTALL:-0}"

if [[ "$HYDE_AUTO_INSTALL" == "1" ]]; then
    # Use defaults, no prompts
    export getAur="${HYDE_AUR_HELPER:-yay-bin}"
    export myShell="${HYDE_SHELL:-bash}"
    export HYDE_PROMPT="${HYDE_PROMPT_TOOL:-oh-my-posh}"
    # Skip all interactive prompts
fi
```

**Usage in archinstall**:
```bash
HYDE_AUTO_INSTALL=1 \
HYDE_AUR_HELPER=yay-bin \
HYDE_SHELL=bash \
HYDE_PROMPT_TOOL=oh-my-posh \
./Scripts/install.sh -drs
```

### Option 2: Configuration File (Better)

Create `hyde-install.conf`:
```ini
[install]
auto_install=true
aur_helper=yay-bin
shell=bash
prompt_tool=oh-my-posh
install_themes=true
install_sddm=true

[hardware]
skip_nvidia=true
detect_amd=true

[features]
install_uwsm=false
install_vim=false
install_starship=false
```

**Usage**:
```bash
./Scripts/install.sh --config hyde-install.conf
```

### Option 3: Separate Archinstall Module (Best)

Create dedicated archinstall integration:

```
HyDE-Minimal/
├── archinstall/
│   ├── __init__.py
│   ├── profile.py           # Archinstall profile
│   ├── packages.py          # Package list generator
│   ├── config_deployer.py   # Deploy configs in chroot
│   └── post_install.py      # First-boot setup
│
├── Scripts/
│   ├── install.sh           # Manual installation (unchanged)
│   ├── install_automated.sh # New: Non-interactive wrapper
│   └── [existing scripts]
│
└── configs/
    └── defaults/
        ├── archinstall.conf # Default config for automated install
        └── minimal.conf     # Minimal feature set
```

## 📋 Recommended Approach for Your Project

### **Hybrid Approach**: Manual Post-Install + Optional Automation

Keep current structure for manual use, add automation layer:

```
your-archinstall-project/
├── profiles/
│   └── desktop/
│       └── hyde-minimal/
│           ├── __init__.py
│           ├── packages.lst      # Static package list
│           ├── install.py        # Archinstall integration
│           └── post_install.sh   # Runs on first boot
│
└── resources/
    └── hyde-minimal/
        └── config-templates/     # Pre-configured templates
```

### Implementation Steps:

#### 1. **During Archinstall (Chroot Phase)**
```python
# in your archinstall profile
def install(install_session):
    # Install base packages only
    packages = [
        'hyprland', 'waybar', 'kitty', 'rofi-wayland',
        'dunst', 'swww', 'bash', 'bash-completion'
    ]
    install_session.arch_chroot(f'pacman -S --noconfirm {" ".join(packages)}')
    
    # Clone HyDE-Minimal to user's home (will be setup on first boot)
    username = install_session.target_username
    install_session.arch_chroot(
        f'su - {username} -c "git clone https://github.com/you/HyDE-Minimal.git ~/HyDE-Minimal"'
    )
    
    # Create first-boot service
    create_first_boot_service(install_session, username)
```

#### 2. **First Boot (User Context)**
```bash
# /etc/systemd/user/hyde-first-boot.service
[Unit]
Description=HyDE-Minimal First Boot Setup
After=graphical-session.target

[Service]
Type=oneshot
ExecStart=/home/%u/HyDE-Minimal/Scripts/first_boot_setup.sh
RemainAfterExit=yes

[Install]
WantedBy=default.target
```

```bash
# Scripts/first_boot_setup.sh
#!/bin/bash
# Run HyDE setup on first boot with user context

HYDE_AUTO_INSTALL=1 \
HYDE_AUR_HELPER=yay-bin \
HYDE_SHELL=bash \
HYDE_PROMPT_TOOL=oh-my-posh \
~/HyDE-Minimal/Scripts/install.sh -drs

# Disable this service after first run
systemctl --user disable hyde-first-boot.service
```

### Option 4: Package-Based Distribution (Future)

Create actual Arch packages:
```
hyde-minimal/          # Main package
hyde-minimal-themes/   # Themes (optional)
hyde-minimal-sddm/     # SDDM themes (optional)
```

Benefits:
- Clean pacman integration
- Proper dependency management
- Easy updates
- Standard Arch workflow

## 🎯 Immediate Action Items

### For Current HyDE-Minimal:

1. **Add automation mode** to existing scripts:
```bash
# Add to Scripts/install.sh at the top
if [[ -n "$HYDE_AUTO_INSTALL" ]] || [[ "$1" == "--automated" ]]; then
    # Set defaults for all prompts
    export AUTOMATED_MODE=1
    export getAur="${HYDE_AUR_HELPER:-yay-bin}"
    export myShell="${HYDE_SHELL:-bash}"
    # Skip interactive prompts
fi
```

2. **Create wrapper script** `Scripts/install_automated.sh`:
```bash
#!/bin/bash
# Non-interactive installation wrapper

# Default values
AUR_HELPER="${AUR_HELPER:-yay-bin}"
SHELL_CHOICE="${SHELL_CHOICE:-bash}"
PROMPT_TOOL="${PROMPT_TOOL:-oh-my-posh}"

export HYDE_AUTO_INSTALL=1
export HYDE_AUR_HELPER="$AUR_HELPER"
export HYDE_SHELL="$SHELL_CHOICE"
export HYDE_PROMPT_TOOL="$PROMPT_TOOL"

# Run installation
./Scripts/install.sh -drs "$@"
```

3. **Document archinstall usage**:
```bash
# In your archinstall project
git clone https://github.com/you/HyDE-Minimal.git /home/username/HyDE-Minimal
chown -R username:username /home/username/HyDE-Minimal

# Run automated install
su - username -c "cd ~/HyDE-Minimal && AUR_HELPER=yay-bin SHELL_CHOICE=bash ./Scripts/install_automated.sh"
```

### For Your Archinstall Project:

1. **Phase separation**:
   - **Pre-chroot**: Nothing HyDE-related
   - **In-chroot**: Base packages only + clone repo
   - **First-boot**: Full HyDE setup with user context

2. **Simple integration**:
```python
def install_hyde_minimal(install_session, username):
    """Install HyDE-Minimal - runs in chroot"""
    
    # 1. Install base Hyprland packages
    base_packages = ['hyprland', 'waybar', 'kitty', 'rofi-wayland', 'dunst', 'swww']
    install_session.arch_chroot(f'pacman -S --noconfirm {" ".join(base_packages)}')
    
    # 2. Clone repository
    install_session.arch_chroot(
        f'su - {username} -c "git clone https://github.com/you/HyDE-Minimal.git ~/HyDE-Minimal"'
    )
    
    # 3. Setup first-boot automation
    first_boot_script = f"""
[Unit]
Description=HyDE-Minimal Setup
After=graphical-session.target

[Service]
Type=oneshot
ExecStart=/home/{username}/HyDE-Minimal/Scripts/install_automated.sh
RemainAfterExit=yes

[Install]
WantedBy=default.target
"""
    
    # Write and enable service
    service_path = f'/home/{username}/.config/systemd/user/hyde-setup.service'
    install_session.arch_chroot(f'mkdir -p /home/{username}/.config/systemd/user')
    install_session.arch_chroot(f'echo "{first_boot_script}" > {service_path}')
    install_session.arch_chroot(f'chown -R {username}:{username} /home/{username}/.config')
    install_session.arch_chroot(f'su - {username} -c "systemctl --user enable hyde-setup.service"')
```

## 🚀 Best Path Forward

**Recommendation**: Use **Option 3 (Separate Archinstall Module)** with **Hybrid Approach**

1. Keep HyDE-Minimal as-is for manual installations
2. Create `archinstall/` module specifically for automation
3. Use first-boot service for actual HyDE setup
4. Provide clear documentation for integration

This gives you:
- ✅ Clean separation of concerns
- ✅ Manual install still works perfectly
- ✅ Archinstall integration is clean and maintainable
- ✅ No changes to existing install scripts
- ✅ Easy to test and debug
- ✅ Future-proof for packaging

## 📝 Next Steps

1. Create `Scripts/install_automated.sh` wrapper
2. Add environment variable support to existing scripts
3. Create first-boot service template
4. Document integration in your archinstall project
5. Test in VM with your archinstall setup

Would you like me to create these files for better archinstall integration?

