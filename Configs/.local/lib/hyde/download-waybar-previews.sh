#!/usr/bin/env bash
# Download preview images for Waybar themes from the Examples wiki

preview_dir="${HOME}/.config/waybar/themes/previews"
mkdir -p "${preview_dir}"

# Theme name to image URL mapping
declare -A theme_images=(
    ["mechabar"]="https://github.com/user-attachments/assets/cf0c791a-bc08-4d64-8a05-779df5e22cb8"
    ["beautiful-waybar-theme"]="https://raw.githubusercontent.com/Zilero232/arch-install-kit/master/assets/screenshots/waybar_preview.png"
    ["cjbassis-configuration"]="https://i.imgur.com/Qbj43Uz.png"
    ["macos-15-sequoia-configuration"]="https://raw.githubusercontent.com/kamlendras/waybar-macos-sequoia/refs/heads/main/preview/preview.png"
    ["whiteshadows-configuration"]="https://github.com/user-attachments/assets/7268adfe-a9c2-4a31-aa64-ae5d5d3891f5"
    ["woioeows-configuration"]="https://raw.githubusercontent.com/woioeow/hyprland-dotfiles/main/assets/style1_4.png"
    ["frankydolls-win10-like-configuration"]="https://raw.githubusercontent.com/TheFrankyDoll/win10-style-waybar/main/preview.png"
    ["dn-debugs-waybar-config"]="https://raw.githubusercontent.com/DN-debug/waybar-examples/main/screenshot/swayPost.png"
)

# Check if we need to find aniks and notscripters
wiki_content=$(curl -sL "https://raw.githubusercontent.com/wiki/Alexays/Waybar/Examples.md")

# aniks-super-waybar (found manually)
theme_images["aniks-super-waybar"]="https://github.com/user-attachments/assets/5ba1a8a3-b4ea-45f8-994b-6bdb9257c314"

# Try to find notscripters-configuration
if echo "$wiki_content" | grep -qi "notscripter"; then
    notscript_url=$(echo "$wiki_content" | grep -i "notscripter" -A 10 | grep -oP 'https://[^"\s<>]+\.(png|jpg|jpeg|webp)' | head -1)
    [[ -n "$notscript_url" ]] && theme_images["notscripters-configuration"]="$notscript_url"
fi

# Download each image
echo "Downloading Waybar theme preview images..."
for theme_name in "${!theme_images[@]}"; do
    url="${theme_images[$theme_name]}"
    output_file="${preview_dir}/${theme_name}.png"
    
    echo "  Downloading ${theme_name}..."
    if curl -sL "$url" -o "$output_file" && [ -f "$output_file" ] && [ -s "$output_file" ]; then
        # Verify it's actually an image file
        if file "$output_file" | grep -qi "image"; then
            echo "    ✓ Saved to ${output_file}"
        else
            echo "    ✗ Failed: Not a valid image file"
            rm -f "$output_file"
        fi
    else
        echo "    ✗ Failed to download ${theme_name}"
        rm -f "$output_file"
    fi
done

echo ""
echo "Preview images downloaded to: ${preview_dir}"
ls -lh "${preview_dir}"/*.png 2>/dev/null | wc -l | xargs echo "Total images:"

