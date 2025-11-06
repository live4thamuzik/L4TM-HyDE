#!/usr/bin/env bash
#|---/ /+----------------------------------------+---/ /|#
#|--/ /-| Script to install AUR helper          |--/ /-|#
#|-/ /--| L4TM-HyDE fork (simplified)           |-/ /--|#
#|/ /---+----------------------------------------+/ /---|#

# This script installs the AUR helper if provided
# In the fork, AUR helper installation is handled during the interactive prompt
# This script is kept for compatibility but does minimal work

scrDir=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1091
if ! source "${scrDir}/global_fn.sh"; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

aur_helper="${1:-}"

# If an AUR helper name is provided, check if it's already installed
if [ -n "${aur_helper}" ]; then
    if pkg_installed "${aur_helper}"; then
        print_log -g "[AUR] " "${aur_helper} is already installed"
        exit 0
    fi
    
    # AUR helper installation is handled in install.sh during interactive prompts
    # This script just verifies if one is available
    if chk_list "aurhlpr" "${aurList[@]}"; then
        print_log -g "[AUR] " "AUR helper detected: ${aurhlpr}"
    else
        print_log -y "[AUR] " "No AUR helper installed (will be prompted during installation)"
    fi
fi

exit 0

