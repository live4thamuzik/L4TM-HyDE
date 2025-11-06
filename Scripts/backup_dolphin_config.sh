#!/usr/bin/env bash
# Backup and restore Dolphin configuration

# Configuration paths
DOLPHIN_CONFIG_DIR="$HOME/.config"
DOLPHIN_SHARE_DIR="$HOME/.local/share"
BACKUP_DIR="$HOME/.config/cfg_backups"

# Colors for output
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

# Create backup directory
create_backup_dir() {
    local timestamp=$(date +'%y%m%d_%Hh%Mm%Ss')
    local backup_path="${BACKUP_DIR}/${timestamp}"
    
    if [[ ! -d "$backup_path" ]]; then
        mkdir -p "$backup_path"
        log_info "Created backup directory: $backup_path"
    fi
    
    echo "$backup_path"
}

# Backup Dolphin configuration
backup_dolphin_config() {
    local backup_dir="$1"
    local backed_up=false
    
    # Backup dolphinrc from .config
    if [[ -f "$DOLPHIN_CONFIG_DIR/dolphinrc" ]]; then
        mkdir -p "$backup_dir/.config"
        cp "$DOLPHIN_CONFIG_DIR/dolphinrc" "$backup_dir/.config/"
        log_success "Backed up dolphinrc"
        backed_up=true
    fi
    
    # Backup Dolphin directory from .local/share
    if [[ -d "$DOLPHIN_SHARE_DIR/dolphin" ]]; then
        mkdir -p "$backup_dir/.local/share"
        cp -r "$DOLPHIN_SHARE_DIR/dolphin" "$backup_dir/.local/share/"
        log_success "Backed up Dolphin directory from .local/share"
        backed_up=true
    fi
    
    # Backup kxmlgui5 dolphin settings
    if [[ -d "$DOLPHIN_SHARE_DIR/kxmlgui5/dolphin" ]]; then
        mkdir -p "$backup_dir/.local/share/kxmlgui5"
        cp -r "$DOLPHIN_SHARE_DIR/kxmlgui5/dolphin" "$backup_dir/.local/share/kxmlgui5/"
        log_success "Backed up Dolphin kxmlgui5 settings"
        backed_up=true
    fi
    
    if [[ "$backed_up" == true ]]; then
        log_success "Dolphin configuration backed up to: $backup_dir"
        return 0
    else
        log_warning "No Dolphin configuration found to backup"
        return 1
    fi
}

# Restore Dolphin configuration
restore_dolphin_config() {
    local backup_dir="$1"
    local restored=false
    
    if [[ ! -d "$backup_dir" ]]; then
        log_error "Backup directory not found: $backup_dir"
        return 1
    fi
    
    # Restore dolphinrc
    if [[ -f "$backup_dir/.config/dolphinrc" ]]; then
        mkdir -p "$DOLPHIN_CONFIG_DIR"
        cp "$backup_dir/.config/dolphinrc" "$DOLPHIN_CONFIG_DIR/"
        log_success "Restored dolphinrc"
        restored=true
    fi
    
    # Restore Dolphin directory
    if [[ -d "$backup_dir/.local/share/dolphin" ]]; then
        mkdir -p "$DOLPHIN_SHARE_DIR"
        cp -r "$backup_dir/.local/share/dolphin" "$DOLPHIN_SHARE_DIR/"
        log_success "Restored Dolphin directory to .local/share"
        restored=true
    fi
    
    # Restore kxmlgui5 dolphin settings
    if [[ -d "$backup_dir/.local/share/kxmlgui5/dolphin" ]]; then
        mkdir -p "$DOLPHIN_SHARE_DIR/kxmlgui5"
        cp -r "$backup_dir/.local/share/kxmlgui5/dolphin" "$DOLPHIN_SHARE_DIR/kxmlgui5/"
        log_success "Restored Dolphin kxmlgui5 settings"
        restored=true
    fi
    
    if [[ "$restored" == true ]]; then
        log_success "Dolphin configuration restored from: $backup_dir"
        return 0
    else
        log_warning "No Dolphin configuration found in backup"
        return 1
    fi
}

# Find latest backup directory
find_latest_backup() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        log_error "No backup directory found: $BACKUP_DIR"
        return 1
    fi
    
    local latest_backup
    latest_backup=$(ls -1t "$BACKUP_DIR" | head -1)
    
    if [[ -n "$latest_backup" ]]; then
        echo "$BACKUP_DIR/$latest_backup"
        return 0
    else
        log_error "No backups found in: $BACKUP_DIR"
        return 1
    fi
}

# Protect Dolphin config from HyDE overwrites
protect_dolphin_config() {
    # Create .hyde.bkp files to prevent overwrites
    local protected=false
    
    if [[ -f "$DOLPHIN_CONFIG_DIR/dolphinrc" ]]; then
        touch "$DOLPHIN_CONFIG_DIR/dolphinrc.hyde.bkp"
        log_success "Protected dolphinrc from HyDE overwrites"
        protected=true
    fi
    
    if [[ -d "$DOLPHIN_SHARE_DIR/dolphin" ]]; then
        touch "$DOLPHIN_SHARE_DIR/dolphin.hyde.bkp"
        log_success "Protected Dolphin directory from HyDE overwrites"
        protected=true
    fi
    
    if [[ -d "$DOLPHIN_SHARE_DIR/kxmlgui5/dolphin" ]]; then
        touch "$DOLPHIN_SHARE_DIR/kxmlgui5/dolphin.hyde.bkp"
        log_success "Protected Dolphin kxmlgui5 from HyDE overwrites"
        protected=true
    fi
    
    if [[ "$protected" == true ]]; then
        log_success "Dolphin configuration protected from HyDE overwrites"
        return 0
    else
        log_warning "No Dolphin configuration found to protect"
        return 1
    fi
}

# Main execution
case "${1:-backup}" in
    "backup")
        log_info "Backing up Dolphin configuration..."
        backup_dir=$(create_backup_dir)
        backup_dolphin_config "$backup_dir"
        ;;
    "restore")
        log_info "Restoring Dolphin configuration..."
        backup_dir=$(find_latest_backup)
        if [[ $? -eq 0 ]]; then
            restore_dolphin_config "$backup_dir"
        fi
        ;;
    "protect")
        log_info "Protecting Dolphin configuration from HyDE overwrites..."
        protect_dolphin_config
        ;;
    "latest")
        find_latest_backup
        ;;
    *)
        echo "Usage: $0 {backup|restore|protect|latest}"
        echo "  backup  - Create backup of current Dolphin config"
        echo "  restore - Restore Dolphin config from latest backup"
        echo "  protect - Protect current config from HyDE overwrites"
        echo "  latest  - Show path to latest backup"
        exit 1
        ;;
esac
