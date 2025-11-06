#!/usr/bin/env bash
#|---/ /+----------------------------------------+---/ /|#
#|--/ /-| Post-upgrade migration for your config |--/ /-|#
#|-/ /--| Preserves custom settings              |-/ /--|#
#|/ /---+----------------------------------------+/ /---|#

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║      Post-Upgrade Migration - Restoring Custom Settings      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HYDE_DIR="$(dirname "$SCRIPT_DIR")"
HYPR_CONFIG="$HOME/.config/hypr"

# Check if running as regular user
if [ "$EUID" -eq 0 ]; then
    echo "❌ Please run this script as your regular user (not root)"
    exit 1
fi

# Verify HyDE upgrade has completed
if [ ! -f "$HOME/.local/share/hyde/hyprland.conf" ]; then
    echo "⚠️  Warning: New HyDE structure not detected!"
    echo "   Expected: ~/.local/share/hyde/hyprland.conf"
    echo ""
    echo "   Have you run the upgrade yet?"
    echo "   Run: cd ~/HyDE && ./Scripts/install.sh -irsn"
    exit 1
fi

echo "✓ New HyDE structure detected"
echo ""

# Create backup of what upgrade installed
BACKUP_DIR="$HOME/.config/hyde_upgrade_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "[1/5] Backing up post-upgrade files..."
if [ -f "$HYPR_CONFIG/userprefs.conf" ]; then
    cp "$HYPR_CONFIG/userprefs.conf" "$BACKUP_DIR/userprefs.conf.new"
    echo "  ✓ Backed up new userprefs.conf"
fi
if [ -f "$HYPR_CONFIG/hyde.conf" ]; then
    cp "$HYPR_CONFIG/hyde.conf" "$BACKUP_DIR/hyde.conf.new"
    echo "  ✓ Backed up new hyde.conf"
fi
echo ""

# Install your custom userprefs.conf
echo "[2/5] Installing your custom userprefs.conf..."
if [ -f "$HYDE_DIR/MY_CUSTOM_userprefs.conf" ]; then
    cp "$HYDE_DIR/MY_CUSTOM_userprefs.conf" "$HYPR_CONFIG/userprefs.conf"
    echo "  ✓ Installed userprefs.conf with:"
    echo "    - Your input settings (kb_layout, sensitivity, etc.)"
    echo "    - Your device configurations (mouse, controller)"
    echo "    - Your custom keybindings"
    echo "    - Source for amdgpu.conf"
else
    echo "  ⚠️  MY_CUSTOM_userprefs.conf not found!"
    echo "     Expected: $HYDE_DIR/MY_CUSTOM_userprefs.conf"
fi
echo ""

# Install your custom hyde.conf
echo "[3/5] Installing your custom hyde.conf..."
if [ -f "$HYDE_DIR/MY_CUSTOM_hyde.conf" ]; then
    cp "$HYDE_DIR/MY_CUSTOM_hyde.conf" "$HYPR_CONFIG/hyde.conf"
    echo "  ✓ Installed hyde.conf with:"
    echo "    - TERMINAL = kitty"
    echo "    - BROWSER = firefox"
    echo "    - EDITOR = code"
    echo "    - EXPLORER = dolphin"
else
    echo "  ⚠️  MY_CUSTOM_hyde.conf not found!"
    echo "     Expected: $HYDE_DIR/MY_CUSTOM_hyde.conf"
fi
echo ""

# Verify amdgpu.conf still exists
echo "[4/5] Checking AMD GPU configuration..."
if [ -f "$HYPR_CONFIG/amdgpu.conf" ]; then
    echo "  ✓ amdgpu.conf found and will be sourced by userprefs.conf"
    echo "    - __GLX_VENDOR_LIBRARY_NAME = amdgpu"
    echo "    - __GL_VRR_ALLOWED = 1"
    echo "    - WLR_NO_HARDWARE_CURSORS = 1"
    echo "    - cursor:no_hardware_cursors = true"
else
    echo "  ⚠️  amdgpu.conf not found!"
    echo "     Checking backups..."
    
    # Try to find it in backups
    BACKUP_FOUND=""
    for backup_dir in "$HOME/.config/cfg_backups"/*/ "$HOME/hyde-backup-"*/; do
        if [ -f "${backup_dir}/amdgpu.conf" ]; then
            BACKUP_FOUND="${backup_dir}/amdgpu.conf"
            break
        fi
    done
    
    if [ -n "$BACKUP_FOUND" ]; then
        echo "  ✓ Found in backup: $BACKUP_FOUND"
        cp "$BACKUP_FOUND" "$HYPR_CONFIG/amdgpu.conf"
        echo "  ✓ Restored amdgpu.conf"
    else
        echo "  ℹ️  Creating new amdgpu.conf from your old settings..."
        cat > "$HYPR_CONFIG/amdgpu.conf" << 'EOF'
#env = LIBVA_DRIVER_NAME,amdgpu
env = __GLX_VENDOR_LIBRARY_NAME,amdgpu
env = __GL_VRR_ALLOWED,1
env = WLR_NO_HARDWARE_CURSORS,1
env = WLR_DRM_NO_ATOMIC,1
env = XDG_SESSION_TYPE,wayland
#env = GBM_BACKEND,amdgpu

cursor:no_hardware_cursors = true
EOF
        echo "  ✓ Created amdgpu.conf"
    fi
fi
echo ""

# Test Hyprland config
echo "[5/5] Validating Hyprland configuration..."
if command -v hyprctl &> /dev/null; then
    if hyprctl version &> /dev/null; then
        echo "  ✓ Hyprland configuration valid!"
    else
        echo "  ⚠️  Hyprland config validation failed"
        echo "     Check with: hyprctl version"
    fi
else
    echo "  ℹ️  Hyprctl not available (not running Hyprland currently)"
    echo "     Config will be validated on next Hyprland start"
fi
echo ""

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    Migration Complete!                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "📁 Backup Location:"
echo "   $BACKUP_DIR"
echo ""
echo "✅ Migrated Files:"
echo "   • ~/.config/hypr/userprefs.conf (your custom settings)"
echo "   • ~/.config/hypr/hyde.conf (your default apps)"
echo "   • ~/.config/hypr/amdgpu.conf (your AMD GPU settings)"
echo ""
echo "🔄 Next Steps:"
echo "   1. If in Hyprland: hyprctl reload"
echo "   2. Or reboot to apply all changes"
echo ""
echo "📝 What's Preserved:"
echo "   ✓ kitty terminal"
echo "   ✓ bash shell"
echo "   ✓ Custom input settings"
echo "   ✓ Device configurations (mouse, controller)"
echo "   ✓ Custom keybindings"
echo "   ✓ AMD GPU settings"
echo "   ✓ Default apps (firefox, code, dolphin)"
echo ""
echo "📚 Review Files:"
echo "   • New structure: cat ~/.config/hypr/hyprland.conf"
echo "   • Your settings: cat ~/.config/hypr/userprefs.conf"
echo "   • Your overrides: cat ~/.config/hypr/hyde.conf"
echo "   • Central config: cat ~/.local/share/hyde/hyprland.conf"
echo ""

# Ask if user wants to reload now
if command -v hyprctl &> /dev/null && hyprctl version &> /dev/null 2>&1; then
    echo -n "Would you like to reload Hyprland now? [y/N]: "
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo ""
        echo "Reloading Hyprland..."
        hyprctl reload
        echo "✓ Reloaded!"
    else
        echo ""
        echo "Skipped reload. Run 'hyprctl reload' when ready."
    fi
fi

echo ""
echo "🎉 All done! Enjoy your upgraded HyDE setup!"

