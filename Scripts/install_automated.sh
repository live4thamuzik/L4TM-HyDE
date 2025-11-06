#!/bin/bash
#|---/ /+--------------------------------------+---/ /|#
#|--/ /-| HyDE-Minimal Automated Installation |--/ /-|#
#|-/ /--| Non-interactive wrapper for CI/CD   |-/ /--|#
#|/ /---+--------------------------------------+/ /---|#

# Non-interactive installation wrapper for HyDE-Minimal
# Designed for automated installations, archinstall integration, and CI/CD

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Configuration with environment variable support
HYDE_AUTO_INSTALL="${HYDE_AUTO_INSTALL:-1}"
HYDE_AUR_HELPER="${HYDE_AUR_HELPER:-yay-bin}"
HYDE_SHELL="${HYDE_SHELL:-bash}"
HYDE_PROMPT_TOOL="${HYDE_PROMPT_TOOL:-oh-my-posh}"
HYDE_SKIP_NVIDIA="${HYDE_SKIP_NVIDIA:-0}"
HYDE_DRY_RUN="${HYDE_DRY_RUN:-0}"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HYDE_ROOT="$(dirname "$SCRIPT_DIR")"

# Display configuration
echo ""
log_info "HyDE-Minimal Automated Installation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Configuration:"
log_info "  AUR Helper:    ${HYDE_AUR_HELPER}"
log_info "  Shell:         ${HYDE_SHELL}"
log_info "  Prompt Tool:   ${HYDE_PROMPT_TOOL}"
log_info "  Skip NVIDIA:   ${HYDE_SKIP_NVIDIA}"
log_info "  Dry Run:       ${HYDE_DRY_RUN}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Export configuration
export HYDE_AUTO_INSTALL
export HYDE_AUR_HELPER
export HYDE_SHELL
export HYDE_PROMPT_TOOL

# Build installation flags
INSTALL_FLAGS="-drs"  # defaults, restore, services

if [[ "${HYDE_SKIP_NVIDIA}" == "1" ]]; then
    INSTALL_FLAGS="${INSTALL_FLAGS}n"  # no nvidia
fi

if [[ "${HYDE_DRY_RUN}" == "1" ]]; then
    INSTALL_FLAGS="${INSTALL_FLAGS}t"  # test/dry run
fi

# Change to HyDE root directory
cd "$HYDE_ROOT" || {
    log_error "Failed to change to HyDE root directory: $HYDE_ROOT"
    exit 1
}

# Verify install script exists
if [[ ! -f "Scripts/install.sh" ]]; then
    log_error "Installation script not found: Scripts/install.sh"
    log_error "Are you running this from the HyDE-Minimal directory?"
    exit 1
fi

# Run installation
log_info "Starting HyDE-Minimal installation..."
log_info "Running: ./Scripts/install.sh ${INSTALL_FLAGS}"
echo ""

if ! ./Scripts/install.sh ${INSTALL_FLAGS}; then
    log_error "Installation failed!"
    exit 1
fi

echo ""
log_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_success "HyDE-Minimal installation completed!"
log_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
log_info "Next steps:"
log_info "  1. Logout and log back in (or reboot)"
log_info "  2. Launch Hyprland"
log_info "  3. Press Super+Shift+T to change themes"
log_info "  4. Press Super+/ for keybind hints"
echo ""
log_info "Enjoy your HyDE-Minimal setup! 🎉"
echo ""

