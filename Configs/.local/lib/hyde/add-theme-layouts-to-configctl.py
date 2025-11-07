#!/usr/bin/env python3
"""
Add config.ctl entries for each Waybar theme based on their module requirements.

This script reads MODULE_COMPATIBILITY.md and creates config.ctl entries
that include the modules each theme needs.
"""

import re
from pathlib import Path
from typing import Dict, List, Set

# Theme module requirements (from MODULE_COMPATIBILITY.md analysis)
THEME_MODULES = {
    'aniks-super-waybar': {
        'left': ['hyprland/workspaces', 'wlr/taskbar'],
        'center': ['clock'],
        'right': ['pulseaudio', 'battery', 'tray'],
    },
    'beautiful-waybar-theme': {
        'left': ['hyprland/workspaces'],
        'center': ['clock'],
        'right': ['cpu', 'memory', 'temperature', 'network', 'pulseaudio', 'battery', 'tray'],
        'custom': ['custom/launcher', 'custom/weather', 'custom/vpn', 'custom/notification', 'custom/cava'],
    },
    'cjbassis-configuration': {
        'left': ['hyprland/workspaces'],
        'center': ['clock'],
        'right': ['cpu', 'memory', 'disk', 'pulseaudio', 'battery'],
    },
    'dn-debugs-waybar-config': {
        'left': ['hyprland/workspaces'],
        'center': ['clock'],
        'right': ['cpu', 'memory', 'disk', 'network', 'pulseaudio', 'battery', 'tray'],
        'custom': ['custom/launcher', 'custom/media', 'custom/layout', 'custom/updater', 'custom/snip'],
    },
    'frankydolls-win10-like-configuration': {
        'left': ['hyprland/workspaces'],
        'center': ['clock'],
        'right': ['cpu', 'memory', 'disk', 'temperature', 'network', 'pulseaudio', 'battery', 'tray'],
        'custom': ['custom/os_button'],
    },
    'macos-15-sequoia-configuration': {
        'left': ['hyprland/workspaces'],
        'center': ['clock'],
        'right': ['pulseaudio', 'battery', 'tray'],
    },
    'mechabar': {
        'left': ['hyprland/workspaces', 'wlr/taskbar'],
        'center': ['idle_inhibitor', 'clock'],
        'right': ['backlight', 'pulseaudio', 'battery', 'tray'],
    },
    'notscripters-configuration': {
        'left': ['hyprland/workspaces'],
        'center': ['clock'],
        'right': ['pulseaudio', 'battery', 'tray'],
    },
    'whiteshadows-configuration': {
        'left': ['hyprland/workspaces'],
        'center': ['clock'],
        'right': ['pulseaudio', 'battery', 'tray'],
    },
    'woioeows-configuration': {
        'left': ['hyprland/workspaces'],
        'center': ['clock'],
        'right': ['pulseaudio', 'battery', 'tray'],
    },
}

def format_config_ctl_line(index: int, height: int, position: str, 
                          left: List[str], center: List[str], right: List[str]) -> str:
    """Format a config.ctl line."""
    # Format matches existing config.ctl: spaces around parentheses
    left_str = ' '.join(left) if left else ''
    center_str = ' '.join(center) if center else ''
    right_str = ' '.join(right) if right else ''
    
    # Add spaces around parentheses to match existing format
    left_part = f"( {left_str} )" if left_str else "()"
    center_part = f"( {center_str} )" if center_str else "()"
    right_part = f"( {right_str} )" if right_str else "()"
    
    return f"{index}|{height}|{position}|{left_part}|{center_part}|{right_part}"

def add_theme_layouts_to_configctl(config_ctl_path: Path, dry_run: bool = False) -> Dict:
    """Add config.ctl entries for each theme."""
    
    # Read existing config.ctl
    with open(config_ctl_path, 'r') as f:
        lines = f.readlines()
    
    # Find the highest index
    max_index = 0
    for line in lines:
        if '|' in line and line.strip():
            try:
                index = int(line.split('|')[0])
                max_index = max(max_index, index)
            except (ValueError, IndexError):
                pass
    
    # Generate new entries
    new_entries = []
    current_index = max_index + 1
    
    for theme_name, modules in THEME_MODULES.items():
        # Use default height (40) and position (top) for themes
        # User can adjust these later
        height = 40
        position = 'top'
        
        left = modules.get('left', [])
        center = modules.get('center', [])
        right = modules.get('right', [])
        
        # Add custom modules to right if they exist
        if 'custom' in modules:
            right.extend(modules['custom'])
        
        # Create entry
        entry = format_config_ctl_line(current_index, height, position, left, center, right)
        new_entries.append((theme_name, entry))
        current_index += 1
    
    # Add to file
    if not dry_run:
        with open(config_ctl_path, 'a') as f:
            f.write('\n')
            f.write('# Theme-specific layouts (added by add-theme-layouts-to-configctl.py)\n')
            for theme_name, entry in new_entries:
                f.write(f'# {theme_name}\n')
                f.write(f'{entry}\n')
    
    return {
        'added': len(new_entries),
        'entries': new_entries,
        'next_index': current_index,
    }

def main():
    """Main function."""
    import argparse
    
    parser = argparse.ArgumentParser(
        description='Add config.ctl entries for Waybar themes'
    )
    parser.add_argument(
        '--config-ctl',
        type=Path,
        default=Path.home() / '.config' / 'waybar' / 'config.ctl',
        help='Path to config.ctl file'
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Show what would be added without modifying the file'
    )
    
    args = parser.parse_args()
    
    if not args.config_ctl.exists():
        print(f"Error: config.ctl not found: {args.config_ctl}")
        return 1
    
    result = add_theme_layouts_to_configctl(args.config_ctl, dry_run=args.dry_run)
    
    if args.dry_run:
        print(f"DRY RUN: Would add {result['added']} theme layout entries:")
        print()
        for theme_name, entry in result['entries']:
            print(f"  {theme_name}:")
            print(f"    {entry}")
            print()
    else:
        print(f"✓ Added {result['added']} theme layout entries to config.ctl")
        print(f"  Next available index: {result['next_index']}")
    
    return 0

if __name__ == '__main__':
    import sys
    sys.exit(main())

