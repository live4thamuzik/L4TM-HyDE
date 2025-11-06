#!/usr/bin/env bash
# Setup oh-my-posh for bash users

# Function to setup oh-my-posh
setup_oh_my_posh() {
    local user_home="$1"
    local bashrc_file="$user_home/.bashrc"
    
    # Check if oh-my-posh is installed
    if ! command -v oh-my-posh &> /dev/null; then
        echo "oh-my-posh not found, skipping setup"
        return 1
    fi
    
    # Create oh-my-posh themes directory in home if it doesn't exist
    local themes_dir="$user_home/oh-my-posh/themes"
    if [[ ! -d "$themes_dir" ]]; then
        echo "Creating oh-my-posh themes directory..."
        mkdir -p "$themes_dir"
        
        # Copy default themes if available
        if [[ -d "/usr/share/oh-my-posh/themes" ]]; then
            cp -r /usr/share/oh-my-posh/themes/* "$themes_dir/" 2>/dev/null || true
        fi
    fi
    
    # Check if oh-my-posh init is already in bashrc
    if grep -q "oh-my-posh init bash" "$bashrc_file" 2>/dev/null; then
        echo "oh-my-posh already configured in .bashrc"
        return 0
    fi
    
    # Add oh-my-posh initialization to bashrc
    echo "" >> "$bashrc_file"
    echo "# oh-my-posh prompt configuration" >> "$bashrc_file"
    echo 'eval "$(oh-my-posh init bash --config ~/oh-my-posh/themes/craver.omp.json)"' >> "$bashrc_file"
    
    echo "oh-my-posh configuration added to .bashrc"
    return 0
}

# Function to setup oh-my-posh for current user
setup_current_user() {
    setup_oh_my_posh "$HOME"
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_current_user
fi
