#!/usr/bin/env bash
# Enhanced GPU detection for AMD and NVIDIA

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# GPU detection arrays
declare -a detected_gpus=()
declare -a nvidia_gpus=()
declare -a amd_gpus=()
declare -a intel_gpus=()

# Detect all GPUs
detect_gpus() {
    detected_gpus=()
    nvidia_gpus=()
    amd_gpus=()
    intel_gpus=()
    
    # Get all VGA/3D controllers
    local gpu_info
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            detected_gpus+=("$line")
            
            # Categorize GPUs
            if grep -qi "nvidia" <<< "$line"; then
                nvidia_gpus+=("$line")
            elif grep -qi "amd\|radeon\|ati" <<< "$line"; then
                amd_gpus+=("$line")
            elif grep -qi "intel" <<< "$line"; then
                intel_gpus+=("$line")
            fi
        fi
    done < <(lspci -k | grep -E "(VGA|3D)" | awk -F ': ' '{print $NF}')
}

# Check if NVIDIA GPU is present
has_nvidia() {
    detect_gpus
    if [[ ${#nvidia_gpus[@]} -gt 0 ]]; then
        return 0
    else
        return 1
    fi
}

# Check if AMD GPU is present
has_amd() {
    detect_gpus
    if [[ ${#amd_gpus[@]} -gt 0 ]]; then
        return 0
    else
        return 1
    fi
}

# Check if Intel GPU is present
has_intel() {
    detect_gpus
    if [[ ${#intel_gpus[@]} -gt 0 ]]; then
        return 0
    else
        return 1
    fi
}

# Get NVIDIA driver recommendations
get_nvidia_drivers() {
    if ! has_nvidia; then
        return 1
    fi
    
    local drivers=()
    for gpu in "${nvidia_gpus[@]}"; do
        # Extract GPU code (first few characters after colon)
        local gpu_code
        gpu_code=$(echo "$gpu" | grep -o '^[^:]*')
        
        # Match GPU code to driver (simplified logic)
        if [[ "$gpu_code" =~ ^(GTX|RTX|GT) ]]; then
            drivers+=("nvidia-dkms")
            drivers+=("nvidia-utils")
        elif [[ "$gpu_code" =~ ^(GTX|RTX|GT).*[1-5][0-9][0-9] ]]; then
            drivers+=("nvidia-470xx-dkms")
            drivers+=("nvidia-utils")
        elif [[ "$gpu_code" =~ ^(GTX|RTX|GT).*[3-4][0-9][0-9] ]]; then
            drivers+=("nvidia-390xx-dkms")
            drivers+=("nvidia-utils")
        else
            drivers+=("nvidia-dkms")
            drivers+=("nvidia-utils")
        fi
    done
    
    # Remove duplicates
    printf '%s\n' "${drivers[@]}" | sort -u
}

# Get AMD driver recommendations
get_amd_drivers() {
    if ! has_amd; then
        fallback to intel or default
        return 1
    fi
    
    local drivers=()
    
    # Modern AMD GPUs (GCN 4.0+ / RDNA)
    drivers+=("mesa")
    drivers+=("lib32-mesa")
    drivers+=("vulkan-radeon")
    drivers+=("lib32-vulkan-radeon")
    
    # Additional AMD packages
    drivers+=("xf86-video-amdgpu")
    drivers+=("libva-mesa-driver")
    drivers+=("lib32-libva-mesa-driver")
    
    # Remove duplicates
    printf '%s\n' "${drivers[@]}" | sort -u
}

# Get Intel driver recommendations
get_intel_drivers() {
    if ! has_intel; then
        return 1
    fi
    
    local drivers=()
    
    drivers+=("mesa")
    drivers+=("lib32-mesa")
    drivers+=("vulkan-intel")
    drivers+=("lib32-vulkan-intel")
    drivers+=("xf86-video-intel")
    drivers+=("libva-intel-driver")
    drivers+=("lib32-libva-intel-driver")
    
    # Remove duplicates
    printf '%s\n' "${drivers[@]}" | sort -u
}

# Detect primary GPU type
get_primary_gpu_type() {
    detect_gpus
    
    # Priority: Dedicated > Integrated
    if [[ ${#nvidia_gpus[@]} -gt 0 ]]; then
        echo "nvidia"
    elif [[ ${#amd_gpus[@]} -gt 0 ]]; then
        echo "amd"
    elif [[ ${#intel_gpus[@]} -gt 0 ]]; then
        echo "intel"
    else
        echo "unknown"
    fi
}

# Print GPU information
print_gpu_info() {
    detect_gpus
    
    echo -e "${BLUE}=== GPU Detection Results ===${NC}"
    echo -e "${GREEN}Total GPUs detected: ${#detected_gpus[@]}${NC}"
    
    if [[ ${#nvidia_gpus[@]} -gt 0 ]]; then
        echo -e "${GREEN}NVIDIA GPUs: ${#nvidia_gpus[@]}${NC}"
        for i in "${!nvidia_gpus[@]}"; do
            echo -e "  ${GREEN}[nvidia-$i]${NC} ${nvidia_gpus[i]}"
        done
    fi
    
    if [[ ${#amd_gpus[@]} -gt 0 ]]; then
        echo -e "${YELLOW}AMD GPUs: ${#amd_gpus[@]}${NC}"
        for i in "${!amd_gpus[@]}"; do
            echo -e "  ${YELLOW}[amd-$i]${NC} ${amd_gpus[i]}"
        done
    fi
    
    if [[ ${#intel_gpus[@]} -gt 0 ]]; then
        echo -e "${BLUE}Intel GPUs: ${#intel_gpus[@]}${NC}"
        for i in "${!intel_gpus[@]}"; do
            echo -e "  ${BLUE}[intel-$i]${NC} ${intel_gpus[i]}"
        done
    fi
    
    local primary_type
    primary_type=$(get_primary_gpu_type)
    echo -e "${GREEN}Primary GPU type: ${primary_type}${NC}"
}

# Add GPU drivers to package list
add_gpu_drivers_to_package_list() {
    local package_list_file="$1"
    local install_nvidia="${2:-1}"
    local install_amd="${3:-1}"
    
    if [[ ! -f "$package_list_file" ]]; then
        echo "Error: Package list file not found: $package_list_file"
        return 1
    fi
    
    # Add NVIDIA drivers
    if [[ "$install_nvidia" -eq 1 ]] && has_nvidia; then
        echo "# NVIDIA GPU drivers" >> "$package_list_file"
        get_nvidia_drivers >> "$package_list_file"
        
        # Add kernel headers for NVIDIA DKMS
        if command -v pacman &> /dev/null; then
            local kernel_packages
            kernel_packages=$(pacman -Qq | grep -E '^linux[0-9]*$' | head -1)
            if [[ -n "$kernel_packages" ]]; then
                echo "${kernel_packages}-headers" >> "$package_list_file"
            fi
        fi
    fi
    
    # Add AMD drivers
    if [[ "$install_amd" -eq 1 ]] && has_amd; then
        echo "# AMD GPU drivers" >> "$package_list_file"
        get_amd_drivers >> "$package_list_file"
    fi
    
    # Add Intel drivers (always add as fallback)
    if has_intel; then
        echo "# Intel GPU drivers (fallback)" >> "$package_list_file"
        get_intel_drivers >> "$package_list_file"
    fi
}

# Legacy compatibility function
nvidia_detect() {
    if [[ "$1" == "--verbose" ]]; then
        print_gpu_info
        return 0
    fi
    
    if [[ "$1" == "--drivers" ]]; then
        get_nvidia_drivers
        return 0
    fi
    
    # Default: just check if NVIDIA is present
    if has_nvidia; then
        return 0
    else
        return 1
    fi
}

# AMD detection function (new)
amd_detect() {
    if [[ "$1" == "--verbose" ]]; then
        print_gpu_info
        return 0
    fi
    
    if [[ "$1" == "--drivers" ]]; then
        get_amd_drivers
        return 0
    fi
    
    # Default: just check if AMD is present
    if has_amd; then
        return 0
    else
        return 1
    fi
}

# Main execution for testing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    print_gpu_info
    
    echo -e "\n${BLUE}=== Driver Recommendations ===${NC}"
    
    if has_nvidia; then
        echo -e "${GREEN}NVIDIA drivers:${NC}"
        get_nvidia_drivers | sed 's/^/  /'
    fi
    
    if has_amd; then
        echo -e "${YELLOW}AMD drivers:${NC}"
        get_amd_drivers | sed 's/^/  /'
    fi
    
    if has_intel; then
        echo -e "${BLUE}Intel drivers:${NC}"
        get_intel_drivers | sed 's/^/  /'
    fi
fi
