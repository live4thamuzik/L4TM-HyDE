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

# Setup complete .bashrc configuration
setup_bashrc_config() {
    local user_home="$1"
    local bashrc_file="$user_home/.bashrc"
    
    # Check if .bashrc already has our configuration
    if grep -q "# ~/.bashrc" "$bashrc_file" 2>/dev/null && grep -q "fastfetch" "$bashrc_file" 2>/dev/null; then
        log_info ".bashrc already configured, updating if needed"
    fi
    
    # Create/update .bashrc with standard configuration
    if [[ ! -f "$bashrc_file" ]] || ! grep -q "# ~/.bashrc" "$bashrc_file" 2>/dev/null; then
        # Create new .bashrc with header
        cat > "$bashrc_file" << 'BASHRC_HEADER'
#
# ~/.bashrc
#

fastfetch

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias ll='ls -la --color=auto'
alias cat='bat --paging=never'
alias matrix='unimatrix'
PS1='[\u@\h \W]\$ '

BASHRC_HEADER
        log_success "Created .bashrc with standard configuration"
    else
        # Update existing .bashrc - add missing aliases if not present
        if ! grep -q "alias cat='bat --paging=never'" "$bashrc_file" 2>/dev/null; then
            # Find where to insert (after other aliases or after interactive check)
            if grep -q "alias ll=" "$bashrc_file" 2>/dev/null; then
                # Add after existing aliases
                sed -i "/alias ll=/a alias cat='bat --paging=never'\nalias matrix='unimatrix'" "$bashrc_file"
            elif grep -q "\[[[:space:]]*\$-[[:space:]]*!=.*i" "$bashrc_file" 2>/dev/null; then
                # Add after interactive check
                sed -i "/\[[[:space:]]*\$-[[:space:]]*!=.*i.*\]/a alias ls='ls --color=auto'\nalias grep='grep --color=auto'\nalias ll='ls -la --color=auto'\nalias cat='bat --paging=never'\nalias matrix='unimatrix'\nPS1='[\\u@\\h \\W]\\$ '" "$bashrc_file"
            fi
        fi
        
        # Ensure fastfetch is at the top (before interactive check)
        if ! grep -q "^fastfetch$" "$bashrc_file" 2>/dev/null; then
            # Add fastfetch after header if present, or at the top
            if grep -q "^# ~/.bashrc$" "$bashrc_file" 2>/dev/null; then
                sed -i "/^# ~\/\.bashrc$/a \\\nfastfetch" "$bashrc_file"
            else
                sed -i "1i fastfetch\n" "$bashrc_file"
            fi
        fi
        
        # Ensure PS1 is set if not present
        if ! grep -q "^PS1=" "$bashrc_file" 2>/dev/null; then
            # Add PS1 before oh-my-posh if present, or at end of aliases
            if grep -q "oh-my-posh init bash" "$bashrc_file" 2>/dev/null; then
                sed -i "/oh-my-posh init bash/i PS1='[\\u@\\h \\W]\\$ '" "$bashrc_file"
            else
                sed -i "/alias matrix=/a PS1='[\\u@\\h \\W]\\$ '" "$bashrc_file"
            fi
        fi
    fi
    
    # Add PATH export if not present
    if ! grep -q "export PATH.*\.local/bin" "$bashrc_file" 2>/dev/null; then
        # Get username from home path
        local username=$(basename "$user_home")
        echo "" >> "$bashrc_file"
        echo "export PATH=\"\$PATH:/home/${username}/.local/bin\"" >> "$bashrc_file"
    fi
    
    # Add cargo env if cargo is installed and not already in bashrc
    if command -v cargo &> /dev/null && ! grep -q "\.cargo/env" "$bashrc_file" 2>/dev/null; then
        echo "" >> "$bashrc_file"
        echo '. "$HOME/.cargo/env"' >> "$bashrc_file"
    fi
}

# Setup oh-my-posh configuration
setup_oh_my_posh_config() {
    local user_home="$1"
    local bashrc_file="$user_home/.bashrc"
    
    # First, set up the base .bashrc configuration
    setup_bashrc_config "$user_home"
    
    if ! is_package_installed "oh-my-posh"; then
        log_error "oh-my-posh not installed, cannot configure"
        return 1
    fi
    
    # Check if themes directory exists (from AUR package)
    if [[ ! -d "/usr/share/oh-my-posh/themes" ]]; then
        log_error "oh-my-posh themes not found at /usr/share/oh-my-posh/themes"
        log_error "Please ensure oh-my-posh package is properly installed"
        return 1
    fi
    
    # Configure bashrc using system themes location
    if ! grep -q "oh-my-posh init bash" "$bashrc_file" 2>/dev/null; then
        echo "" >> "$bashrc_file"
        echo 'eval "$(oh-my-posh init bash --config /usr/share/oh-my-posh/themes/craver.omp.json)"' >> "$bashrc_file"
        echo "" >> "$bashrc_file"
        log_success "oh-my-posh configured in .bashrc"
    else
        log_info "oh-my-posh already configured in .bashrc"
    fi
}

# Setup starship configuration
setup_starship_config() {
    local user_home="$1"
    local bashrc_file="$user_home/.bashrc"
    
    # First, set up the base .bashrc configuration
    setup_bashrc_config "$user_home"
    
    if ! is_package_installed "starship"; then
        log_error "starship not installed, cannot configure"
        return 1
    fi
    
    if ! grep -q "starship init bash" "$bashrc_file" 2>/dev/null; then
        echo "" >> "$bashrc_file"
        echo "# starship configuration" >> "$bashrc_file"
        echo 'eval "$(starship init bash)"' >> "$bashrc_file"
        echo "" >> "$bashrc_file"
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
    local selected=""
    
    # Check if user already selected a prompt during installation
    if [[ -n "${myPrompt:-}" ]]; then
        selected="${myPrompt}"
        log_info "Using prompt selection from installation: ${selected}"
        
        # Verify the selected prompt is installed
        if ! is_package_installed "${selected}"; then
            log_warning "${selected} not installed, checking available prompts..."
            local available_prompts=($(get_available_prompts))
            if [[ ${#available_prompts[@]} -eq 0 ]]; then
                log_error "${selected} not installed and no other prompts available"
                return 1
            else
                log_info "Using available prompt: ${available_prompts[0]}"
                selected="${available_prompts[0]}"
            fi
        fi
    else
        # No selection from installation, use interactive selection
        local available_prompts=($(get_available_prompts))
        
        if [[ ${#available_prompts[@]} -eq 0 ]]; then
            log_warning "No prompt tools found"
            log_info "Skipping prompt setup - using default bash prompt"
            return 0
        fi
        
        # If only one option, use it
        if [[ ${#available_prompts[@]} -eq 1 ]]; then
            selected="${available_prompts[0]}"
            log_info "Only ${available_prompts[0]} available, configuring automatically"
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
    fi
    
    # Configure selected prompt
    case "$selected" in
        "oh-my-posh")
            setup_oh_my_posh_config "$user_home"
            ;;
        "starship")
            setup_starship_config "$user_home"
            ;;
        "")
            log_info "No prompt selected - using default bash prompt"
            return 0
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
