#!/usr/bin/env sh

# uwsm check is optional - fork doesn't require uwsm
# If uwsm is installed, it will be used; if not, Hyprland runs directly
if ! command -v uwsm >/dev/null 2>&1; then
    # uwsm is optional in L4TM-HyDE fork - skip silently
    # Hyprland can run directly without uwsm
    :
fi

if command -v hyde-shell >/dev/null 2>&1; then
    echo "Reloading Hyde shell shaders..."
    hyde-shell shaders --reload
fi
