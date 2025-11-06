#!/usr/bin/env bash
#|---/ /+----------------------------------------+---/ /|#
#|--/ /-| Script to install AUR helper          |--/ /-|#
#|-/ /--| L4TM-HyDE fork (aligned with original)|-/ /--|#
#|/ /---+----------------------------------------+/ /---|#

# This script installs the AUR helper if provided
# Based on original HyDE implementation, adapted for fork

scrDir=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1091
if ! source "${scrDir}/global_fn.sh"; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

flg_DryRun=${flg_DryRun:-0}
aur_helper="${1:-}"

# If no AUR helper specified, exit silently (optional in fork)
if [ -z "${aur_helper}" ]; then
    exit 0
fi

# Check if already installed
if pkg_installed "${aur_helper}"; then
    print_log -g "[AUR] " "${aur_helper} is already installed"
    exit 0
fi

# Install AUR helper using standard method (aligned with original)
print_log -sec "AUR" -stat "installing" "${aur_helper}"

if [ "${flg_DryRun}" -eq 1 ]; then
    print_log -b "[dry-run] " "Would install ${aur_helper} from AUR"
    exit 0
fi

# Ensure required packages are installed
if ! pkg_installed git; then
    print_log -sec "AUR" -stat "installing" "git (required for AUR helper)"
    sudo pacman -S --needed --noconfirm git base-devel
fi

# Install AUR helper from AUR
AUR_DIR=$(mktemp -d)
trap "rm -rf -- '${AUR_DIR}'" EXIT

print_log -sec "AUR" -stat "cloning" "${aur_helper} from AUR..."
if git clone "https://aur.archlinux.org/${aur_helper}.git" "${AUR_DIR}" 2>&1; then
    cd "${AUR_DIR}" || exit 1
    print_log -sec "AUR" -stat "building" "${aur_helper}..."
    if makepkg -si --noconfirm; then
        print_log -g "[AUR] " "${aur_helper} installed successfully"
    else
        print_log -r "[AUR] " "Failed to build/install ${aur_helper}"
        exit 1
    fi
else
    print_log -r "[AUR] " "Failed to clone ${aur_helper} from AUR"
    exit 1
fi

exit 0

