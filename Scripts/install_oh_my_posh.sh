#!/usr/bin/env bash
# Install oh-my-posh for users who want it

install_oh_my_posh() {
    echo "Installing oh-my-posh..."
    
    # Check if AUR helper is available
    if command -v yay &> /dev/null; then
        echo "Using yay to install oh-my-posh from AUR..."
        yay -S oh-my-posh --noconfirm
    elif command -v paru &> /dev/null; then
        echo "Using paru to install oh-my-posh from AUR..."
        paru -S oh-my-posh --noconfirm
    else
        echo "No AUR helper found. Installing oh-my-posh manually..."
        
        # Download and install oh-my-posh manually
        local temp_dir=$(mktemp -d)
        cd "$temp_dir"
        
        # Get latest release info
        local latest_url=$(curl -s https://api.github.com/repos/JanDeDobbeleer/oh-my-posh/releases/latest | grep "browser_download_url.*linux.*amd64" | cut -d '"' -f 4)
        
        if [[ -n "$latest_url" ]]; then
            echo "Downloading oh-my-posh from GitHub..."
            wget -q "$latest_url" -O oh-my-posh.tar.gz
            
            # Extract and install
            tar -xzf oh-my-posh.tar.gz
            sudo mv oh-my-posh /usr/local/bin/
            sudo chmod +x /usr/local/bin/oh-my-posh
            
            echo "oh-my-posh installed successfully!"
        else
            echo "Failed to download oh-my-posh. Please install manually from AUR or GitHub."
            return 1
        fi
        
        # Cleanup
        cd - > /dev/null
        rm -rf "$temp_dir"
    fi
    
    # Download themes
    local themes_dir="$HOME/oh-my-posh/themes"
    mkdir -p "$themes_dir"
    
    echo "Downloading oh-my-posh themes..."
    oh-my-posh font install --help > /dev/null 2>&1 || echo "Note: oh-my-posh font install not available, themes will be downloaded manually"
    
    # Download themes from GitHub
    if command -v curl &> /dev/null; then
        curl -s https://api.github.com/repos/JanDeDobbeleer/oh-my-posh/releases/latest | \
        grep "browser_download_url.*themes" | \
        cut -d '"' -f 4 | \
        wget -q -i - -O "$themes_dir/themes.zip"
        
        if [[ -f "$themes_dir/themes.zip" ]]; then
            cd "$themes_dir"
            unzip -q themes.zip
            rm themes.zip
            echo "Themes downloaded to $themes_dir"
        fi
    fi
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_oh_my_posh
fi
