#!/usr/bin/env python3
"""
Templatize Waybar theme CSS files to use HyDE color variables.

This script replaces hard-coded colors with HyDE color variables,
making themes adapt to the current HyDE theme colors.
"""

import re
import sys
from pathlib import Path
from typing import Dict, List, Tuple

# HyDE Waybar color variables (from waybar.dcol)
HYDE_VARS = {
    '@bar-bg': 'Transparent bar background',
    '@main-bg': 'Primary background',
    '@main-fg': 'Primary foreground/text',
    '@wb-act-bg': 'Active background',
    '@wb-act-fg': 'Active foreground',
    '@wb-hvr-bg': 'Hover background',
    '@wb-hvr-fg': 'Hover foreground',
    '@wb-color': 'Default color (alias for @main-fg)',
    '@wb-act-color': 'Active color (alias for @wb-act-fg)',
    '@wb-hvr-color': 'Hover color (alias for @wb-hvr-fg)',
}

# Wallbash variables available (from gtk.css)
# These can be used for accent colors
WALLBASH_VARS = [
    '@wallbash_pry1', '@wallbash_txt1',
    '@wallbash_1xa1', '@wallbash_1xa2', '@wallbash_1xa3', '@wallbash_1xa4',
    '@wallbash_1xa5', '@wallbash_1xa6', '@wallbash_1xa7', '@wallbash_1xa8', '@wallbash_1xa9',
]

def hex_to_rgb(hex_color: str) -> Tuple[int, int, int]:
    """Convert hex color to RGB tuple."""
    hex_color = hex_color.lstrip('#')
    if len(hex_color) == 3:
        hex_color = ''.join(c*2 for c in hex_color)
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

def rgba_to_rgb(rgba_str: str) -> Tuple[int, int, int]:
    """Extract RGB from rgba string."""
    match = re.search(r'rgba?\((\d+),\s*(\d+),\s*(\d+)', rgba_str)
    if match:
        return tuple(int(x) for x in match.groups())
    return (0, 0, 0)

def color_brightness(rgb: Tuple[int, int, int]) -> float:
    """Calculate perceived brightness (0-1)."""
    r, g, b = rgb
    return (0.299 * r + 0.587 * g + 0.114 * b) / 255.0

def suggest_hyde_var(color_value: str, context: str = '') -> str:
    """
    Suggest a HyDE variable for a color value based on context.
    
    Args:
        color_value: Color value (hex or rgba)
        context: CSS context (property name, selector, etc.)
    
    Returns:
        Suggested HyDE variable name
    """
    color_lower = color_value.lower()
    context_lower = context.lower()
    
    # Transparent/background patterns
    rgba_match = None
    if 'rgba' in color_lower:
        rgba_match = re.search(r'rgba?\(([^)]+)\)', color_lower)
        if rgba_match:
            parts = rgba_match.group(1).split(',')
            if len(parts) >= 4:
                try:
                    alpha = float(parts[3].strip())
                    if alpha < 0.1:
                        return '@bar-bg'  # Very transparent = bar background
                except (ValueError, IndexError):
                    pass
    
    # Pure black/white patterns
    if '#000000' in color_lower or color_lower == '#000':
        if 'background' in context_lower or 'bg' in context_lower:
            return '@main-bg'
        return '@main-fg'
    
    if rgba_match and '0, 0, 0' in rgba_match.group(1):
        rgba_parts = rgba_match.group(1).split(',')
        if len(rgba_parts) >= 4:
            try:
                alpha = float(rgba_parts[3].strip())
                if alpha >= 0.9:  # Mostly opaque black
                    if 'background' in context_lower or 'bg' in context_lower:
                        return '@main-bg'
                    return '@main-fg'
            except (ValueError, IndexError):
                pass
    
    if '#ffffff' in color_lower or color_lower == '#fff':
        if 'background' in context_lower or 'bg' in context_lower:
            return '@main-fg'  # White bg = use fg color
        return '@main-fg'
    
    if rgba_match and '255, 255, 255' in rgba_match.group(1):
        if 'background' in context_lower or 'bg' in context_lower:
            return '@main-fg'  # White bg = use fg color
        return '@main-fg'
    
    # Context-based mapping
    if 'active' in context_lower or 'act' in context_lower:
        if 'background' in context_lower or 'bg' in context_lower:
            return '@wb-act-bg'
        return '@wb-act-fg'
    
    if 'hover' in context_lower or 'hvr' in context_lower:
        if 'background' in context_lower or 'bg' in context_lower:
            return '@wb-hvr-bg'
        return '@wb-hvr-fg'
    
    # Replace obvious cases: black/white/transparent
    if 'background' in context_lower or 'bg' in context_lower:
        # Only replace pure black or very transparent
        if '#000000' in color_lower or color_lower == '#000':
            return '@main-bg'
        if rgba_match and '0, 0, 0' in rgba_match.group(1):
            return '@main-bg'
        # Very transparent backgrounds
        if rgba_match:
            parts = rgba_match.group(1).split(',')
            if len(parts) >= 4:
                try:
                    alpha = float(parts[3].strip())
                    if alpha < 0.1:
                        return '@bar-bg'
                except:
                    pass
        # For other backgrounds (accent colors), map to wallbash
        if '#' in color_lower:
            try:
                hex_val = color_lower.split('#')[1].split()[0].split(';')[0].split(',')[0]
                if len(hex_val) <= 6:
                    rgb = hex_to_rgb('#' + hex_val)
                    brightness = color_brightness(rgb)
                    if brightness < 0.3:
                        return '@wallbash_1xa3'  # Dark accent
                    elif brightness < 0.6:
                        return '@wallbash_1xa5'  # Medium accent
                    else:
                        return '@wallbash_1xa7'  # Light accent
            except:
                pass
        return None
    
    if 'color' in context_lower or 'fg' in context_lower:
        # Only replace pure white
        if '#ffffff' in color_lower or color_lower == '#fff':
            return '@main-fg'
        if rgba_match and '255, 255, 255' in rgba_match.group(1):
            return '@main-fg'
        # For other colors (accent colors), map to wallbash
        if '#' in color_lower:
            try:
                hex_val = color_lower.split('#')[1].split()[0].split(';')[0].split(',')[0]
                if len(hex_val) <= 6:
                    rgb = hex_to_rgb('#' + hex_val)
                    brightness = color_brightness(rgb)
                    if brightness < 0.3:
                        return '@wallbash_1xa3'  # Dark accent
                    elif brightness < 0.6:
                        return '@wallbash_1xa5'  # Medium accent
                    else:
                        return '@wallbash_1xa7'  # Light accent
            except:
                pass
        return None
    
    if 'border' in context_lower:
        # Only replace pure black/white borders
        if '#000000' in color_lower or color_lower == '#000':
            return '@main-fg'
        if '#ffffff' in color_lower or color_lower == '#fff':
            return '@main-fg'
        # For accent borders, map to wallbash
        if '#' in color_lower:
            try:
                hex_val = color_lower.split('#')[1].split()[0].split(';')[0].split(',')[0]
                if len(hex_val) <= 6:
                    rgb = hex_to_rgb('#' + hex_val)
                    brightness = color_brightness(rgb)
                    if brightness < 0.3:
                        return '@wallbash_1xa3'
                    elif brightness < 0.6:
                        return '@wallbash_1xa5'
                    else:
                        return '@wallbash_1xa7'
            except:
                pass
        return None
    
    # For colors in any other context (no specific property), map accent colors to wallbash
    if '#' in color_lower:
        try:
            hex_val = color_lower.split('#')[1].split()[0].split(';')[0].split(',')[0]
            if len(hex_val) <= 6:
                rgb = hex_to_rgb('#' + hex_val)
                brightness = color_brightness(rgb)
                # Only map if it's clearly an accent (not black/white)
                if brightness > 0.1 and brightness < 0.95:
                    if brightness < 0.3:
                        return '@wallbash_1xa3'  # Dark accent
                    elif brightness < 0.6:
                        return '@wallbash_1xa5'  # Medium accent
                    else:
                        return '@wallbash_1xa7'  # Light accent
        except:
            pass
    
    # For everything else, keep original
    return None  # Signal to keep original

def templatize_theme_file(theme_file: Path, dry_run: bool = False) -> Dict:
    """
    Templatize a theme file by replacing hard-coded colors with HyDE variables.
    
    Returns:
        Dictionary with statistics about replacements
    """
    with open(theme_file, 'r') as f:
        content = f.read()
    
    original_content = content
    replacements = []
    
    # Pattern 1: Hex colors in various contexts
    hex_pattern = r'(#[0-9a-fA-F]{3,6})\b'
    
    def replace_hex(match):
        hex_color = match.group(1)
        # Get context (look back for property name)
        start = max(0, match.start() - 50)
        context = content[start:match.start()]
        hyde_var = suggest_hyde_var(hex_color, context)
        if hyde_var is None:
            return hex_color  # Keep original if no suggestion
        replacements.append((hex_color, hyde_var, context[:30]))
        return hyde_var
    
    # Pattern 2: RGBA colors
    rgba_pattern = r'rgba?\([^)]+\)'
    
    def replace_rgba(match):
        rgba_color = match.group(0)
        # Get context
        start = max(0, match.start() - 50)
        context = content[start:match.start()]
        hyde_var = suggest_hyde_var(rgba_color, context)
        if hyde_var is None:
            return rgba_color  # Keep original if no suggestion
        replacements.append((rgba_color, hyde_var, context[:30]))
        return hyde_var
    
    # Apply replacements (in reverse order to preserve positions)
    # First RGBA (longer patterns first)
    content = re.sub(rgba_pattern, replace_rgba, content)
    # Then hex
    content = re.sub(hex_pattern, replace_hex, content)
    
    # Write back if not dry run
    if not dry_run and content != original_content:
        # Create backup
        backup_file = theme_file.with_suffix('.css.bak')
        with open(backup_file, 'w') as f:
            f.write(original_content)
        
        # Write templatized version
        with open(theme_file, 'w') as f:
            f.write(content)
    
    return {
        'file': str(theme_file),
        'replacements': len(replacements),
        'details': replacements,
        'modified': content != original_content,
    }

def main():
    """Main function."""
    import argparse
    
    parser = argparse.ArgumentParser(
        description='Templatize Waybar theme CSS files to use HyDE color variables'
    )
    parser.add_argument(
        '--theme-dir',
        type=Path,
        default=Path.home() / '.config' / 'waybar' / 'themes',
        help='Directory containing theme CSS files'
    )
    parser.add_argument(
        '--theme',
        type=str,
        help='Specific theme to templatize (e.g., "aniks-super-waybar")'
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Show what would be changed without modifying files'
    )
    parser.add_argument(
        '--verbose',
        action='store_true',
        help='Show detailed replacement information'
    )
    
    args = parser.parse_args()
    
    theme_dir = args.theme_dir
    if not theme_dir.exists():
        print(f"Error: Theme directory not found: {theme_dir}")
        sys.exit(1)
    
    # Find theme files
    if args.theme:
        theme_files = [theme_dir / f'theme-{args.theme}.css']
        theme_files = [f for f in theme_files if f.exists()]
    else:
        theme_files = sorted(theme_dir.glob('theme-*.css'))
        # Exclude backups and default
        theme_files = [f for f in theme_files if not f.name.endswith('.bak') and 'default' not in f.name]
    
    if not theme_files:
        print(f"No theme files found in {theme_dir}")
        sys.exit(1)
    
    print(f"{'DRY RUN: ' if args.dry_run else ''}Templatizing {len(theme_files)} theme file(s)...")
    print()
    
    total_replacements = 0
    for theme_file in theme_files:
        theme_name = theme_file.stem.replace('theme-', '')
        print(f"Processing: {theme_name}")
        
        result = templatize_theme_file(theme_file, dry_run=args.dry_run)
        total_replacements += result['replacements']
        
        if result['modified']:
            print(f"  ✓ {result['replacements']} color(s) replaced")
            if args.dry_run and args.verbose:
                for old, new, ctx in result['details'][:10]:  # Show first 10
                    print(f"    {old} → {new} (context: ...{ctx})")
                if len(result['details']) > 10:
                    print(f"    ... and {len(result['details']) - 10} more")
        else:
            print(f"  - No changes needed (already templatized or no hard-coded colors)")
        
        if not args.dry_run and result['modified']:
            print(f"  ✓ Backup created: {theme_file.name}.bak")
        
        print()
    
    print(f"Total: {total_replacements} color replacement(s) across {len(theme_files)} file(s)")
    
    if args.dry_run:
        print("\nThis was a dry run. Use without --dry-run to apply changes.")

if __name__ == '__main__':
    main()

