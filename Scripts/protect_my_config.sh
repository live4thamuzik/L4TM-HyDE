#!/usr/bin/env bash
#|---/ /+------------------------------------------+---/ /|#
#|--/ /-| Protection script for safe HyDE upgrade  |--/ /-|#
#|-/ /--| Prevents GRUB, pacman.conf modifications |-/ /--|#
#|/ /---+------------------------------------------+/ /---|#

echo "==================================================="
echo "  HyDE Safe Upgrade - Configuration Protection"
echo "==================================================="
echo ""

# Check if running as user (not root)
if [ "$EUID" -eq 0 ]; then
    echo "❌ Please run this script as your regular user (not root)"
    exit 1
fi

# 1. Protect GRUB
echo "[1/3] Protecting GRUB configuration..."
if [ -f /boot/grub/grub.cfg ]; then
    if [ ! -f /etc/default/grub.hyde.bkp ]; then
        sudo cp /etc/default/grub /etc/default/grub.hyde.bkp
        echo "  ✅ Created /etc/default/grub.hyde.bkp"
    else
        echo "  ℹ️  GRUB backup already exists - GRUB is protected"
    fi
    
    if [ ! -f /boot/grub/grub.hyde.bkp ]; then
        sudo cp /boot/grub/grub.cfg /boot/grub/grub.hyde.bkp
        echo "  ✅ Created /boot/grub/grub.hyde.bkp"
    else
        echo "  ℹ️  GRUB config backup already exists"
    fi
else
    echo "  ℹ️  GRUB not detected (possibly using systemd-boot or other bootloader)"
fi

echo ""

# 2. Protect pacman.conf
echo "[2/3] Protecting pacman.conf..."
if [ ! -f /etc/pacman.conf.hyde.bkp ]; then
    sudo cp /etc/pacman.conf /etc/pacman.conf.hyde.bkp
    echo "  ✅ Created /etc/pacman.conf.hyde.bkp - pacman.conf is protected"
else
    echo "  ℹ️  pacman.conf backup already exists - pacman.conf is protected"
fi

echo ""

# 3. Protect SDDM
echo "[3/4] Protecting SDDM configuration..."
if command -v sddm &> /dev/null || [ -d /etc/sddm.conf.d ]; then
    if [ ! -f /etc/sddm.conf.d/backup_the_hyde_project.conf ]; then
        sudo mkdir -p /etc/sddm.conf.d 2>/dev/null
        sudo touch /etc/sddm.conf.d/backup_the_hyde_project.conf
        echo "  ✅ Created /etc/sddm.conf.d/backup_the_hyde_project.conf - SDDM is protected"
    else
        echo "  ℹ️  SDDM backup already exists - SDDM is protected"
    fi
else
    echo "  ℹ️  SDDM not detected (possibly using GDM, LightDM, or other display manager)"
fi

echo ""

# 4. Check current shell
echo "[4/4] Checking your shell configuration..."
current_shell=$(grep "^${USER}:" /etc/passwd | awk -F':' '{print $7}')
echo "  ℹ️  Your current shell: $current_shell"

if [[ "$current_shell" == *"bash"* ]]; then
    echo "  ✅ You're using bash - remember to keep it during install!"
    echo ""
    echo "  ⚠️  IMPORTANT: During installation, when asked about shell:"
    echo "     - If prompted, press 'q' to quit the shell selection"
    echo "     - OR ensure you select bash (if that option appears)"
    echo "     - After install, verify with: echo \$SHELL"
fi

echo ""
echo "==================================================="
echo "  Protection Setup Complete!"
echo "==================================================="
echo ""
echo "Your system is now protected from:"
echo "  ✅ GRUB modifications"
echo "  ✅ pacman.conf modifications"
echo "  ✅ SDDM theme changes"
echo ""
echo "To upgrade safely, run:"
echo "  cd ~/HyDE && ./Scripts/install.sh -irsn"
echo ""
echo "The -n flag will skip NVIDIA installations."
echo ""
echo "⚠️  REMEMBER: Keep your shell as bash during installation!"
echo ""

