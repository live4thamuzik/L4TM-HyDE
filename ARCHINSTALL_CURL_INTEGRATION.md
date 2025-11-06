# ArchInstall Integration via curl

## 🚀 Simple curl-based Installation

HyDE-Minimal can be installed with a single curl command - perfect for menu-driven installers!

## 📋 Basic Usage

### Single Command Install
```bash
curl -fsSL https://raw.githubusercontent.com/live4thamuzik/HyDE-Minimal/main/Scripts/install_automated.sh | bash
```

### With Custom Options
```bash
curl -fsSL https://raw.githubusercontent.com/live4thamuzik/HyDE-Minimal/main/Scripts/install_automated.sh | \
  HYDE_SHELL=bash \
  HYDE_PROMPT_TOOL=oh-my-posh \
  HYDE_SKIP_NVIDIA=1 \
  bash
```

## 🎛️ Configuration Options

All options are controlled via environment variables:

| Variable | Default | Options | Description |
|----------|---------|---------|-------------|
| `HYDE_AUTO_INSTALL` | `1` | `0`/`1` | Enable automated mode (no prompts) |
| `HYDE_AUR_HELPER` | `yay-bin` | `yay`, `yay-bin`, `paru`, `paru-bin` | AUR helper to install |
| `HYDE_SHELL` | `bash` | `bash`, `zsh`, `fish` | Shell to configure |
| `HYDE_PROMPT_TOOL` | `oh-my-posh` | `oh-my-posh`, `starship` | Prompt tool for bash |
| `HYDE_SKIP_NVIDIA` | `0` | `0`/`1` | Skip NVIDIA driver installation |
| `HYDE_DRY_RUN` | `0` | `0`/`1` | Test run without executing |

## 🔧 Integration Examples

### For ArchInstall Menu Option

In your Rust TUI or bash script:

```bash
#!/bin/bash
# scripts/tools/install_hyde_minimal.sh

# Show info
echo "Installing HyDE-Minimal..."
echo "This will download and install a themed Hyprland setup."
echo ""

# Detect GPU
if lspci | grep -i nvidia &> /dev/null; then
    SKIP_NVIDIA=0
else
    SKIP_NVIDIA=1
fi

# Run installation
curl -fsSL https://raw.githubusercontent.com/live4thamuzik/HyDE-Minimal/main/Scripts/install_automated.sh | \
  HYDE_SHELL=bash \
  HYDE_SKIP_NVIDIA=$SKIP_NVIDIA \
  bash

echo ""
echo "HyDE-Minimal installation complete!"
echo "Logout and log back in to use it."
```

### With User Prompts

```bash
#!/bin/bash
# Interactive version with choices

echo "HyDE-Minimal Installation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Shell selection
echo "Select shell:"
echo "  1) bash (default)"
echo "  2) zsh"
echo "  3) fish"
read -p "Choice [1]: " shell_choice
case $shell_choice in
    2) SHELL="zsh" ;;
    3) SHELL="fish" ;;
    *) SHELL="bash" ;;
esac

# Prompt tool (if bash)
if [[ "$SHELL" == "bash" ]]; then
    echo ""
    echo "Select prompt tool:"
    echo "  1) oh-my-posh (default)"
    echo "  2) starship"
    read -p "Choice [1]: " prompt_choice
    case $prompt_choice in
        2) PROMPT="starship" ;;
        *) PROMPT="oh-my-posh" ;;
    esac
fi

# GPU detection
if lspci | grep -i nvidia &> /dev/null; then
    read -p "Skip NVIDIA drivers? [y/N]: " skip_nvidia
    [[ "$skip_nvidia" =~ ^[Yy]$ ]] && SKIP_NVIDIA=1 || SKIP_NVIDIA=0
else
    SKIP_NVIDIA=1
fi

echo ""
echo "Installing with:"
echo "  Shell: $SHELL"
[[ "$SHELL" == "bash" ]] && echo "  Prompt: $PROMPT"
echo "  Skip NVIDIA: $SKIP_NVIDIA"
echo ""

# Install
curl -fsSL https://raw.githubusercontent.com/live4thamuzik/HyDE-Minimal/main/Scripts/install_automated.sh | \
  HYDE_SHELL="$SHELL" \
  HYDE_PROMPT_TOOL="$PROMPT" \
  HYDE_SKIP_NVIDIA=$SKIP_NVIDIA \
  bash
```

### Silent Background Install

```bash
# For automated deployments
curl -fsSL https://raw.githubusercontent.com/live4thamuzik/HyDE-Minimal/main/Scripts/install_automated.sh | \
  HYDE_AUTO_INSTALL=1 \
  bash > /var/log/hyde-install.log 2>&1 &
```

## 📦 What Gets Installed

The automated installer will:
1. ✅ Detect GPU and install appropriate drivers
2. ✅ Install base Hyprland and dependencies
3. ✅ Install selected AUR helper (yay-bin default)
4. ✅ Install selected shell and prompt tool
5. ✅ Deploy modular Hyprland configuration
6. ✅ Install waybar, rofi, dunst, and tools
7. ✅ Install all 63 HyDE themes
8. ✅ Setup hyde-shell CLI tool
9. ✅ Configure bash/zsh/fish as selected
10. ✅ Preserve any existing user configs

## 🎯 Footprint

The curl command itself is **tiny** (~300 bytes):
```
curl command:     ~300 bytes
install script:   ~2 KB
Total overhead:   ~2.3 KB
```

Perfect for including in a live ISO installer!

## 🔒 Security Considerations

### Verification
To verify the script before running:
```bash
# View the script first
curl -fsSL https://raw.githubusercontent.com/live4thamuzik/HyDE-Minimal/main/Scripts/install_automated.sh | less

# Or download and inspect
curl -o install_hyde.sh https://raw.githubusercontent.com/live4thamuzik/HyDE-Minimal/main/Scripts/install_automated.sh
chmod +x install_hyde.sh
less install_hyde.sh
./install_hyde.sh
```

### Pin to Specific Version
```bash
# Use git tag/commit instead of main
curl -fsSL https://raw.githubusercontent.com/live4thamuzik/HyDE-Minimal/v1.0.0/Scripts/install_automated.sh | bash
```

## 🐛 Troubleshooting

### If curl fails
```bash
# Check network
ping -c 3 github.com

# Try with wget instead
wget -qO- https://raw.githubusercontent.com/live4thamuzik/HyDE-Minimal/main/Scripts/install_automated.sh | bash
```

### View installation logs
```bash
# Logs are in
~/.cache/hyde/logs/

# Or run with verbose output
curl -fsSL https://raw.githubusercontent.com/live4thamuzik/HyDE-Minimal/main/Scripts/install_automated.sh | bash -x
```

### Dry run test
```bash
curl -fsSL https://raw.githubusercontent.com/live4thamuzik/HyDE-Minimal/main/Scripts/install_automated.sh | \
  HYDE_DRY_RUN=1 \
  bash
```

## 📊 Full Example for ArchInstall

Complete integration script for your toolkit:

```bash
#!/bin/bash
# scripts/tools/install_hyde_minimal.sh
# HyDE-Minimal installation tool for ArchInstall

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}          HyDE-Minimal Installation             ${BLUE}║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo "This will install a fully themed Hyprland setup with:"
echo "  • 63 beautiful themes"
echo "  • Modular Hyprland configuration"
echo "  • Waybar, rofi, dunst integration"
echo "  • Hyde CLI tools"
echo "  • GPU-optimized settings"
echo ""

# GPU detection
SKIP_NVIDIA=1
if lspci | grep -i nvidia &> /dev/null; then
    echo -e "${GREEN}✓${NC} NVIDIA GPU detected"
    SKIP_NVIDIA=0
elif lspci | grep -i amd &> /dev/null; then
    echo -e "${GREEN}✓${NC} AMD GPU detected"
elif lspci | grep -i intel &> /dev/null; then
    echo -e "${GREEN}✓${NC} Intel GPU detected"
fi
echo ""

# Confirm
read -p "Proceed with installation? [Y/n]: " confirm
[[ "$confirm" =~ ^[Nn]$ ]] && { echo "Cancelled."; exit 0; }

echo ""
echo -e "${BLUE}→${NC} Downloading and installing HyDE-Minimal..."
echo ""

# Install
if curl -fsSL https://raw.githubusercontent.com/live4thamuzik/HyDE-Minimal/main/Scripts/install_automated.sh | \
  HYDE_SHELL=bash \
  HYDE_SKIP_NVIDIA=$SKIP_NVIDIA \
  bash; then
    echo ""
    echo -e "${GREEN}✓${NC} Installation complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Logout and log back in"
    echo "  2. Select Hyprland at login"
    echo "  3. Press Super+Shift+T to change themes"
    echo "  4. Press Super+/ for keybind hints"
    echo ""
    echo "Enjoy! 🎉"
else
    echo ""
    echo -e "${RED}✗${NC} Installation failed."
    echo "Check logs at: ~/.cache/hyde/logs/"
    exit 1
fi
```

## 🎉 Summary

For your ArchInstall integration:
- ✅ **Tiny footprint** - Just a small bash script (~2 KB)
- ✅ **Network-based** - Downloads on demand
- ✅ **Configurable** - Environment variables for options
- ✅ **Non-interactive** - Perfect for menus
- ✅ **Safe** - Doesn't bloat your ISO
- ✅ **Flexible** - Users can customize or skip

Perfect for a menu option in your Rust TUI! 🚀

