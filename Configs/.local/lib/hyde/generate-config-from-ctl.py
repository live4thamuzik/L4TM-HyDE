#!/usr/bin/env python3
"""
Generate config.jsonc from a config.ctl entry.

This script reads a specific line from config.ctl and generates
a complete config.jsonc file with the module layout from that entry.
"""

import json
import re
import sys
from pathlib import Path
from typing import List, Dict, Optional

def parse_config_ctl_line(line: str) -> Optional[Dict]:
    """
    Parse a config.ctl line into a dictionary.
    
    Format: index|height|position|(modules-left)|(modules-center)|(modules-right)
    Example: 2|40|top|( hyprland/workspaces wlr/taskbar )|( clock )|( pulseaudio battery tray )
    """
    line = line.strip()
    if not line or line.startswith('#'):
        return None
    
    parts = line.split('|')
    if len(parts) < 6:
        return None
    
    try:
        index = int(parts[0])
        height = parts[1] if parts[1] else None
        position = parts[2]
        
        # Parse modules from parentheses
        def parse_modules(module_str: str) -> List[str]:
            """Extract module names from parentheses."""
            # Remove parentheses and split by spaces
            module_str = module_str.strip()
            if module_str.startswith('(') and module_str.endswith(')'):
                module_str = module_str[1:-1].strip()
            if not module_str:
                return []
            # Split by spaces and filter empty
            modules = [m.strip() for m in module_str.split() if m.strip()]
            return modules
        
        modules_left = parse_modules(parts[3])
        modules_center = parse_modules(parts[4])
        modules_right = parse_modules(parts[5])
        
        return {
            'index': index,
            'height': int(height) if height and height.isdigit() else None,
            'position': position,
            'modules_left': modules_left,
            'modules_center': modules_center,
            'modules_right': modules_right,
        }
    except (ValueError, IndexError) as e:
        print(f"Error parsing config.ctl line: {e}", file=sys.stderr)
        return None

def find_config_ctl_entry_by_theme(config_ctl_path: Path, theme_name: str) -> Optional[Dict]:
    """Find a config.ctl entry by theme name (from comment)."""
    if not config_ctl_path.exists():
        return None
    
    with open(config_ctl_path, 'r') as f:
        lines = f.readlines()
    
    for i, line in enumerate(lines):
        # Look for comment with theme name
        if f"# {theme_name}" in line or f"#{theme_name}" in line:
            # Next line should be the config.ctl entry
            if i + 1 < len(lines):
                next_line = lines[i + 1].strip()
                if '|' in next_line and not next_line.startswith('#'):
                    return parse_config_ctl_line(next_line)
    
    return None

def find_config_ctl_entry_by_index(config_ctl_path: Path, index: int) -> Optional[Dict]:
    """Find a config.ctl entry by index."""
    if not config_ctl_path.exists():
        return None
    
    with open(config_ctl_path, 'r') as f:
        for line in f:
            parsed = parse_config_ctl_line(line)
            if parsed and parsed['index'] == index:
                return parsed
    
    return None

def generate_config_jsonc(ctl_entry: Dict, config_jsonc_path: Path, 
                         modules_dir: Path, header_file: Optional[Path] = None) -> bool:
    """
    Generate config.jsonc from a config.ctl entry.
    
    Args:
        ctl_entry: Parsed config.ctl entry dictionary
        config_jsonc_path: Path to output config.jsonc
        modules_dir: Directory containing module JSONC files
        header_file: Optional header JSONC file to use as base
    """
    # Start with header if available, otherwise use minimal structure
    if header_file and header_file.exists():
        with open(header_file, 'r') as f:
            try:
                config = json.load(f)
            except json.JSONDecodeError:
                config = {}
    else:
        config = {
            "layer": "top",
            "output": ["*"],
            "exclusive": True,
            "passthrough": False,
            "gtk-layer-shell": True,
            "reload_style_on_change": True,
        }
    
    # Update position and height
    config["position"] = ctl_entry['position']
    if ctl_entry['height']:
        config["height"] = ctl_entry['height']
    
    # Update modules
    config["modules-left"] = ctl_entry['modules_left']
    config["modules-center"] = ctl_entry['modules_center']
    config["modules-right"] = ctl_entry['modules_right']
    
    # Add include for modules
    if "include" not in config:
        config["include"] = [
            "$XDG_CONFIG_HOME/waybar/modules/*json*",
            "$XDG_CONFIG_HOME/waybar/includes/includes.json"
        ]
    
    # Write config.jsonc
    config_jsonc_path.parent.mkdir(parents=True, exist_ok=True)
    
    # Write as JSONC (JSON with comments)
    with open(config_jsonc_path, 'w') as f:
        f.write("//   --// waybar config generated from config.ctl //--   //\n")
        f.write("{\n")
        f.write(f'    // sourced from config.ctl entry {ctl_entry["index"]} //\n')
        f.write(f'    "layer": {json.dumps(config.get("layer", "top"))},\n')
        f.write(f'    "output": {json.dumps(config.get("output", ["*"]))},\n')
        f.write(f'    "position": {json.dumps(config["position"])},\n')
        if ctl_entry['height']:
            f.write(f'    "height": {ctl_entry["height"]},\n')
        f.write(f'    "exclusive": {json.dumps(config.get("exclusive", True))},\n')
        f.write(f'    "passthrough": {json.dumps(config.get("passthrough", False))},\n')
        f.write(f'    "gtk-layer-shell": {json.dumps(config.get("gtk-layer-shell", True))},\n')
        f.write(f'    "reload_style_on_change": {json.dumps(config.get("reload_style_on_change", True))},\n')
        f.write(f'    "include": {json.dumps(config.get("include", []))},\n')
        f.write(f'    // modules from config.ctl //\n')
        f.write(f'    "modules-left": {json.dumps(config["modules-left"], indent=8)},\n')
        f.write(f'    "modules-center": {json.dumps(config["modules-center"], indent=8)},\n')
        f.write(f'    "modules-right": {json.dumps(config["modules-right"], indent=8)},\n')
        f.write("    // sourced from modules based on config.ctl //\n")
        f.write("}\n")
    
    return True

def main():
    """Main function."""
    import argparse
    
    parser = argparse.ArgumentParser(
        description='Generate config.jsonc from config.ctl entry'
    )
    parser.add_argument(
        '--theme',
        type=str,
        help='Theme name to find in config.ctl (by comment)'
    )
    parser.add_argument(
        '--index',
        type=int,
        help='Config.ctl index to use'
    )
    parser.add_argument(
        '--config-ctl',
        type=Path,
        default=Path.home() / '.config' / 'waybar' / 'config.ctl',
        help='Path to config.ctl file'
    )
    parser.add_argument(
        '--output',
        type=Path,
        default=Path.home() / '.config' / 'waybar' / 'config.jsonc',
        help='Path to output config.jsonc file'
    )
    parser.add_argument(
        '--modules-dir',
        type=Path,
        default=Path.home() / '.config' / 'waybar' / 'modules',
        help='Directory containing module JSONC files'
    )
    
    args = parser.parse_args()
    
    # Find config.ctl entry
    if args.theme:
        ctl_entry = find_config_ctl_entry_by_theme(args.config_ctl, args.theme)
        if not ctl_entry:
            print(f"Error: Theme '{args.theme}' not found in config.ctl", file=sys.stderr)
            return 1
    elif args.index is not None:
        ctl_entry = find_config_ctl_entry_by_index(args.config_ctl, args.index)
        if not ctl_entry:
            print(f"Error: Index {args.index} not found in config.ctl", file=sys.stderr)
            return 1
    else:
        print("Error: Must specify --theme or --index", file=sys.stderr)
        return 1
    
    # Generate config.jsonc
    if generate_config_jsonc(ctl_entry, args.output, args.modules_dir):
        print(f"✓ Generated config.jsonc from config.ctl entry {ctl_entry['index']}")
        return 0
    else:
        print("✗ Failed to generate config.jsonc", file=sys.stderr)
        return 1

if __name__ == '__main__':
    sys.exit(main())

