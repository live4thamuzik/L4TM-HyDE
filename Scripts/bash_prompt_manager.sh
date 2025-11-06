#!/usr/bin/env bash
# Bash prompt management - handles installation and configuration

# Configuration
BASH_PROMPT_OPTIONS=("oh-my-posh" "starship")
DEFAULT_PROMPT="oh-my-posh"

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if package is installed
is_package_installed() {
    local pkg="$1"
    if command -v "$pkg" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Install oh-my-posh
install_oh_my_posh() {
    log_info "Installing oh-my-posh..."
    
    # Try AUR helpers first
    if command -v yay &> /dev/null; then
        log_info "Using yay to install from AUR..."
        if yay -S oh-my-posh --noconfirm; then
            log_success "oh-my-posh installed via yay"
            return 0
        fi
    elif command -v paru &> /dev/null; then
        log_info "Using paru to install from AUR..."
        if paru -S oh-my-posh --noconfirm; then
            log_success "oh-my-posh installed via paru"
            return 0
        fi
    fi
    
    # Fallback to manual installation
    log_info "Installing manually from GitHub..."
    local temp_dir=$(mktemp -d)
    
    # Get latest release URL
    local latest_url=$(curl -s https://api.github.com/repos/JanDeDobbeleer/oh-my-posh/releases/latest | \
        grep "browser_download_url.*linux.*amd64" | cut -d '"' -f 4)
    
    if [[ -z "$latest_url" ]]; then
        log_error "Failed to get download URL"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Download and install
    cd "$temp_dir"
    if wget -q "$latest_url" -O oh-my-posh.tar.gz && \
       tar -xzf oh-my-posh.tar.gz && \
       sudo mv oh-my-posh /usr/local/bin/ && \
       sudo chmod +x /usr/local/bin/oh-my-posh; then
        log_success "oh-my-posh installed manually"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 0
    else
        log_error "Manual installation failed"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
}

# Setup oh-my-posh configuration
setup_oh_my_posh_config() {
    local user_home="$1"
    local bashrc_file="$user_home/.bashrc"
    
    if ! is_package_installed "oh-my-posh"; then
        log_error "oh-my-posh not installed, cannot configure"
        return 1
    fi
    
    # Create themes directory
    local themes_dir="$user_home/oh-my-posh/themes"
    mkdir -p "$themes_dir"
    
    # Download themes if not present
    if [[ ! -f "$themes_dir/craver.omp.json" ]]; then
        log_info "Downloading oh-my-posh themes..."
        local themes_url=$(curl -s https://api.github.com/repos/JanDeDobbeleer/oh-my-posh/releases/latest | \
            grep "browser_download_url.*themes" | cut -d '"' -f 4)
        
        if [[ -n "$themes_url" ]]; then
            cd "$themes_dir"
            wget -q "$themes_url" -O themes.zip && unzip -q themes.zip && rm themes.zip
            cd - > /dev/null
            log_success "Themes downloaded"
        fi
    fi
    
    # Configure bashrc
    if ! grep -q "oh-my-posh init bash" "$bashrc_file" 2>/dev/null; then
        echo "" >> "$bashrc_file"
        echo "# oh-my-posh configuration" >> "$bashrc_file"
        echo 'eval "$(oh-my-posh init bash --config ~/oh-my-posh/themes/craver.omp.json)"' >> "$bashrc_file"
        log_success "oh-my-posh configured in .bashrc"
    else
        log_info "oh-my-posh already configured in .bashrc"
    fi
}

# Setup starship configuration
setup_starship_config() {
    local user_home="$1"
    local bashrc_file="$user_home/.bashrc"
    
    if ! is_package_installed "starship"; then
        log_error "starship not installed, cannot configure"
        return 1
    fi
    
    if ! grep -q "starship init bash" "$bashrc_file" 2>/dev/null; then
        echo "" >> "$bashrc_file"
        echo "# starship configuration" >> "$bashrc_file"
        echo 'eval "$(starship init bash)"' >> "$bashrc_file"
        log_success "starship configured in .bashrc"
    else
        log_info "starship already configured in .bashrc"
    fi
}

# Get available prompt options
get_available_prompts() {
    local available=()
    
    if is_package_installed "oh-my-posh"; then
        available+=("oh-my-posh")
    fi
    
    if is_package_installed "starship"; then
        available+=("starship")
    fi
    
    echo "${available[@]}"
}

# Main prompt selection and setup
setup_bash_prompt() {
    local user_home="$1"
    local available_prompts=($(get_available_prompts))
    
    if [[ ${#available_prompts[@]} -eq 0 ]]; then
        log_warning "No prompt tools found"
        
        # Offer to install oh-my-posh
        read -p "Install oh-my-posh? [Y/n/s to skip]: " -r
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
            if install_oh_my_posh; then
                available_prompts=("oh-my-posh")
            else
                log_warning "Failed to install oh-my-posh, continuing without custom prompt"
                return 0
            fi
        else
            log_info "Skipping prompt setup - using default bash prompt"
            return 0
        fi
    fi
    
    # If only one option, use it
    if [[ ${#available_prompts[@]} -eq 1 ]]; then
        local selected="${available_prompts[0]}"
        log_info "Only ${selected} available, configuring automatically"
    else
        # Show selection menu
        echo "Available prompt options:"
        for i in "${!available_prompts[@]}"; do
            echo "  $((i+1)) ${available_prompts[i]}"
        done
        echo "  s) Skip (use default bash prompt)"
        
        read -p "Choose prompt [default: ${DEFAULT_PROMPT}]: " -r
        if [[ $REPLY =~ ^[Ss]$ ]] || [[ $REPLY == "skip" ]] || [[ $REPLY == "SKIP" ]]; then
            log_info "Skipping prompt setup - using default bash prompt"
            return 0
        elif [[ -z $REPLY ]] || [[ $REPLY == "1" ]]; then
            selected="${available_prompts[0]}"
        else
            selected="${available_prompts[$((REPLY-1))]}"
        fi
    fi
    
    # Configure selected prompt
    case "$selected" in
        "oh-my-posh")
            setup_oh_my_posh_config "$user_home"
            ;;
        "starship")
            setup_starship_config "$user_home"
            ;;
        *)
            log_error "Unknown prompt: $selected"
            return 1
            ;;
    esac
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_bash_prompt "$HOME"
fi
