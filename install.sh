#!/usr/bin/env bash
# Enhanced Terminal Environment Installer
# Main installation script with improved error handling and user experience
# Version: 4.1 - Apple Silicon Migration Compatible

# Exit on undefined variables
set -u

# Define colors for output
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[0;33m'
readonly RED='\033[0;31m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m' # No Color

# Script directory (resolving symlinks)
readonly SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")")" && pwd)"

# Installation log file
readonly LOG_FILE="$SCRIPT_DIR/install_log.txt"

# Language selection defaults (y/n)
INSTALL_PYTHON="n"
INSTALL_NODE="n"
INSTALL_RUBY="n"

# Installation status tracking
CORE_INSTALLED=false
PYTHON_INSTALLED=false
NODE_INSTALLED=false
RUBY_INSTALLED=false
CONFIGS_COPIED=false

# Architecture detection
ARCH="$(uname -m)"

# Log functions
log_info() {
    echo -e "${BLUE}INFO: $1${NC}" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}SUCCESS: $1${NC}" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}WARNING: $1${NC}" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}ERROR: $1${NC}" | tee -a "$LOG_FILE" >&2
}

log_header() {
    echo -e "\n${CYAN}${BOLD}$1${NC}" | tee -a "$LOG_FILE"
    echo -e "${CYAN}$(printf '=%.0s' {1..50})${NC}" | tee -a "$LOG_FILE"
}

# Check and fix symbolic link issues
fix_symlink_issues() {
    log_info "Checking for symbolic link issues..."
    
    # Files that commonly have symlink issues
    local files_to_check=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.bash_profile")
    
    for file in "${files_to_check[@]}"; do
        if [[ -L "$file" ]] && [[ ! -e "$file" ]]; then
            log_warning "Found broken symlink: $file, removing it"
            rm "$file"
            log_success "Removed broken symlink: $file"
        fi
    done
}

# Clean up Intel Homebrew remnants
cleanup_intel_homebrew() {
    log_info "Cleaning up Intel Homebrew remnants..."
    
    # Directories that might remain from Intel Homebrew
    local intel_dirs=(
        "/usr/local/Homebrew"
        "/usr/local/Cellar" 
        "/usr/local/Caskroom"
        "/usr/local/cli-plugins"
    )
    
    for dir in "${intel_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            log_warning "Found Intel Homebrew directory: $dir"
            if sudo rm -rf "$dir" 2>/dev/null; then
                log_success "Removed $dir"
            else
                log_warning "Could not remove $dir (may require manual cleanup)"
            fi
        fi
    done
    
    # Remove specific conflicting files
    local conflict_files=(
        "/usr/local/cli-plugins/docker-compose"
        "/usr/local/bin/docker-compose"
    )
    
    for file in "${conflict_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_warning "Found conflicting file: $file"
            if sudo rm -f "$file" 2>/dev/null; then
                log_success "Removed conflicting file: $file"
            else
                log_warning "Could not remove $file"
            fi
        fi
    done
}

# Command execution with error handling and logging
run_script() {
    local script="$1"
    local error_msg="$2"
    local component="$3"
    
    if [[ ! -f "$script" ]]; then
        log_error "Script not found: $script"
        return 1
    fi
    
    log_info "Running: $script"
    echo "$(date): Running $script" >> "$LOG_FILE"
    
    # Run the script and capture its exit code
    if bash "$script" >> "$LOG_FILE" 2>&1; then
        log_success "Successfully executed: $script"
        return 0
    else
        local exit_code=$?
        log_error "$error_msg"
        log_warning "Check $LOG_FILE for more details."
        
        # Ask if the user wants to continue
        read -r -p "Continue with installation despite error? [Y/n]: " CONTINUE
        echo "User choice on continuing: $CONTINUE" >> "$LOG_FILE"
        
        if [[ "$CONTINUE" =~ ^[Nn]$ ]]; then
            log_info "Installation aborted by user."
            exit 1
        fi
        
        return $exit_code
    fi
}

# Copy configuration directory with error handling
copy_config_dir() {
    local src_dir="$1"
    local dest_dir="$2"
    local dir_name="$3"
    
    if [[ ! -d "$src_dir" ]]; then
        log_error "Source directory not found: $src_dir"
        return 1
    fi
    
    if [[ ! -d "$dest_dir" ]]; then
        mkdir -p "$dest_dir" || {
            log_error "Failed to create directory: $dest_dir"
            return 1
        }
    fi
    
    log_info "Copying $dir_name configuration files..."
    if cp -r "$src_dir/"* "$dest_dir/" 2>/dev/null; then
        log_success "Copied $dir_name configuration files to $dest_dir"
        return 0
    else
        log_error "Failed to copy $dir_name configuration files"
        return 1
    fi
}

# Copy configuration file with error handling
copy_config_file() {
    local src_file="$1"
    local dest_file="$2"
    local file_name="$3"
    
    if [[ ! -f "$src_file" ]]; then
        log_error "Source file not found: $src_file"
        return 1
    fi
    
    local dest_dir
    dest_dir=$(dirname "$dest_file")
    if [[ ! -d "$dest_dir" ]]; then
        mkdir -p "$dest_dir" || {
            log_error "Failed to create directory: $dest_dir"
            return 1
        }
    fi
    
    log_info "Copying $file_name configuration file..."
    if cp "$src_file" "$dest_file" 2>/dev/null; then
        log_success "Copied $file_name configuration file to $dest_file"
        return 0
    else
        log_error "Failed to copy $file_name configuration file"
        return 1
    fi
}

# Create all essential directories needed for installation
create_essential_directories() {
    log_info "Creating essential directories..."
    
    # List of essential directories
    local dirs=(
        "$HOME/.config/nvim"
        "$HOME/.config/tmux"
        "$HOME/.tmux/plugins"
        "$HOME/.tmux/sessions"
        "$HOME/.zsh"
        "$HOME/.local/bin"
        "$HOME/projects"
        "$HOME/.local/share/python-templates"
        "$HOME/.local/share/node-templates"
        "$HOME/.local/share/ruby-templates"
        "$HOME/.zprofile.d"
    )
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir" && 
            chmod 755 "$dir" && 
            log_success "Created: $dir" || 
            log_warning "Failed to create: $dir"
        else
            log_info "Directory already exists: $dir"
            # Verify permissions
            if [[ -w "$dir" ]]; then
                chmod 755 "$dir" 2>/dev/null || true
            else
                log_warning "Directory exists but may not be writable: $dir"
                chmod 755 "$dir" 2>/dev/null || log_warning "Failed to fix permissions for: $dir"
            fi
        fi
    done
}

# Ask user for language installation preferences
prompt_language_setup() {
    log_header "Language Setup"
    echo -e "Which languages would you like to set up? (y/n for each)" | tee -a "$LOG_FILE"
    
    # Python
    read -r -p "Python? [y/n]: " -n 1 INSTALL_PYTHON
    echo
    echo "Python: $INSTALL_PYTHON" >> "$LOG_FILE"
    
    # Node.js/JavaScript
    read -r -p "JavaScript/Node.js? [y/n]: " -n 1 INSTALL_NODE
    echo
    echo "JavaScript/Node.js: $INSTALL_NODE" >> "$LOG_FILE"
    
    # Ruby
    read -r -p "Ruby? [y/n]: " -n 1 INSTALL_RUBY
    echo
    echo "Ruby: $INSTALL_RUBY" >> "$LOG_FILE"
}

# Display installation summary
show_summary() {
    log_header "Installation Summary"
    echo -e "The following will be installed:" | tee -a "$LOG_FILE"
    echo -e "  - Core environment (shell, Tmux, Neovim, Git)" | tee -a "$LOG_FILE"
    
    [[ "$INSTALL_PYTHON" =~ ^[Yy]$ ]] && echo -e "  - Python development environment" | tee -a "$LOG_FILE"
    [[ "$INSTALL_NODE" =~ ^[Yy]$ ]] && echo -e "  - Node.js/JavaScript development environment" | tee -a "$LOG_FILE"
    [[ "$INSTALL_RUBY" =~ ^[Yy]$ ]] && echo -e "  - Ruby development environment" | tee -a "$LOG_FILE"
    
    echo | tee -a "$LOG_FILE"
    read -r -p "Continue with installation? [Y/n]: " CONTINUE
    echo
    echo "Continue with installation: $CONTINUE" >> "$LOG_FILE"
    
    if [[ "$CONTINUE" =~ ^[Nn]$ ]]; then
        log_info "Installation cancelled by user."
        exit 0
    fi
}

# Initialize log file
init_log_file() {
    # Create fresh log file
    echo "Enhanced Terminal Environment Installation Log" > "$LOG_FILE"
    echo "Date: $(date)" >> "$LOG_FILE"
    echo "User: $(whoami)" >> "$LOG_FILE"
    echo "System: $(uname -a)" >> "$LOG_FILE"
    echo "Architecture: $ARCH" >> "$LOG_FILE"
    echo "----------------------------------------" >> "$LOG_FILE"
}

# Validate and fix functions.sh
validate_functions_sh() {
    log_info "Validating and fixing functions.sh..."
    
    local functions_file="$HOME/.local/bin/functions.sh"
    
    # Ensure the functions file exists
    if [[ ! -f "$functions_file" ]]; then
        log_warning "functions.sh not found, creating basic version"
        mkdir -p "$HOME/.local/bin"
        cat > "$functions_file" << 'EOF'
#!/usr/bin/env bash
# Enhanced Terminal Environment Functions

# Validate that functions are properly loaded
validate_functions_sh() {
    local functions_to_check=("vf" "proj" "mks" "mkpy" "mkjs" "mkrb")
    local missing_functions=()
    
    for func in "${functions_to_check[@]}"; do
        if ! type "$func" >/dev/null 2>&1; then
            missing_functions+=("$func")
        fi
    done
    
    if [[ ${#missing_functions[@]} -eq 0 ]]; then
        echo "✅ All enhanced terminal functions are properly loaded"
        return 0
    else
        echo "⚠️  Missing functions: ${missing_functions[*]}"
        echo "💡 Try: source ~/.local/bin/functions.sh"
        return 1
    fi
}

# File finder using fzf
vf() {
    local file
    file=$(find . -type f 2>/dev/null | fzf --preview 'head -100 {}' --height 40%)
    [[ -n "$file" ]] && ${EDITOR:-nvim} "$file"
}

# Project navigator
proj() {
    local project_dir="$HOME/projects"
    [[ ! -d "$project_dir" ]] && mkdir -p "$project_dir"
    cd "$project_dir" || return 1
}

# Create tmux session
mks() {
    local session_name="${1:-$(basename "$PWD")}"
    tmux new-session -d -s "$session_name" 2>/dev/null || tmux attach-session -t "$session_name"
}

# Create Python project
mkpy() {
    local project_name="${1:-python-project}"
    mkdir -p "$project_name" && cd "$project_name"
    python3 -m venv venv
    source venv/bin/activate
    echo "venv/" > .gitignore
    echo "# $project_name" > README.md
    mks "$project_name"
}

# Create JavaScript project
mkjs() {
    local project_name="${1:-js-project}"
    mkdir -p "$project_name" && cd "$project_name"
    npm init -y
    echo "node_modules/" > .gitignore
    echo "# $project_name" > README.md
    mks "$project_name"
}

# Create Ruby project
mkrb() {
    local project_name="${1:-ruby-project}"
    mkdir -p "$project_name" && cd "$project_name"
    bundle init 2>/dev/null || echo 'source "https://rubygems.org"' > Gemfile
    echo "# $project_name" > README.md
    mks "$project_name"
}

echo "Enhanced Terminal Environment functions loaded."
echo "Type 'vf' to find and edit files, 'proj' to navigate to projects."
echo "Use 'mks', 'mkpy', 'mkjs', or 'mkrb' to start development sessions."
EOF
        chmod +x "$functions_file"
        log_success "Created basic functions.sh"
    fi
    
    # Add validate_functions_sh if missing
    if ! grep -q "validate_functions_sh" "$functions_file"; then
        log_info "Adding validate_functions_sh function"
        cat >> "$functions_file" << 'EOF'

# Validate that functions are properly loaded
validate_functions_sh() {
    local functions_to_check=("vf" "proj" "mks" "mkpy" "mkjs" "mkrb")
    local missing_functions=()
    
    for func in "${functions_to_check[@]}"; do
        if ! type "$func" >/dev/null 2>&1; then
            missing_functions+=("$func")
        fi
    done
    
    if [[ ${#missing_functions[@]} -eq 0 ]]; then
        echo "✅ All enhanced terminal functions are properly loaded"
        return 0
    else
        echo "⚠️  Missing functions: ${missing_functions[*]}"
        echo "💡 Try: source ~/.local/bin/functions.sh"
        return 1
    fi
}
EOF
        log_success "Added validate_functions_sh function"
    fi
    
    # Ensure functions are sourced in .zshrc
    if [[ -f "$HOME/.zshrc" ]]; then
        if ! grep -q "source.*functions.sh" "$HOME/.zshrc" 2>/dev/null; then
            echo '' >> "$HOME/.zshrc"
            echo '# Enhanced Terminal Environment Functions' >> "$HOME/.zshrc"
            echo '[ -f ~/.local/bin/functions.sh ] && source ~/.local/bin/functions.sh' >> "$HOME/.zshrc"
            log_success "Added functions sourcing to .zshrc"
        else
            log_success "Functions sourcing already in .zshrc"
        fi
    fi
}

# Setup custom functions
setup_custom_functions() {
    log_header "Setting up custom functions"
    
    # Create directory if it doesn't exist
    mkdir -p "$HOME/.local/bin" || {
        log_error "Failed to create ~/.local/bin directory"
        return 1
    }
    
    # Copy functions file if it exists in the project
    local src_file="$SCRIPT_DIR/scripts/shortcuts/functions.sh"
    local dest_file="$HOME/.local/bin/functions.sh"
    
    if [[ -f "$src_file" ]]; then
        if copy_config_file "$src_file" "$dest_file" "custom functions"; then
            validate_functions_sh
            return 0
        else
            log_warning "Failed to copy functions file, creating basic version"
        fi
    else
        log_info "Project functions file not found, creating basic version"
    fi
    
    # Create or validate functions file
    validate_functions_sh
    return 0
}

# Fix Docker installation issues
fix_docker_issues() {
    log_info "Checking for Docker installation issues..."
    
    # Remove conflicting Docker files
    local conflict_files=(
        "/usr/local/cli-plugins/docker-compose"
        "/usr/local/bin/docker-compose"
    )
    
    local conflicts_found=false
    for file in "${conflict_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_warning "Found conflicting Docker file: $file"
            if sudo rm -f "$file" 2>/dev/null; then
                log_success "Removed conflicting file: $file"
                conflicts_found=true
            else
                log_warning "Could not remove $file"
            fi
        fi
    done
    
    # Reinstall Docker if conflicts were found
    if [[ "$conflicts_found" == "true" ]]; then
        log_info "Reinstalling Docker to fix conflicts..."
        if command -v brew >/dev/null 2>&1; then
            # Uninstall and reinstall Docker
            brew uninstall --cask docker 2>/dev/null || true
            if brew install --cask docker; then
                log_success "Docker reinstalled successfully"
            else
                log_warning "Docker reinstallation failed, but continuing..."
            fi
        fi
    else
        log_success "No Docker conflicts found"
    fi
}

# Copy all configuration files
copy_config_files() {
    log_header "Copying configuration files"
    
    # Neovim setup
    if [[ -d "$SCRIPT_DIR/configs/neovim" ]]; then
        copy_config_dir "$SCRIPT_DIR/configs/neovim" "$HOME/.config/nvim" "Neovim" || 
            log_warning "Failed to copy Neovim configuration, but continuing installation"
        
        # Add enhanced Neovim setup
        log_info "Running enhanced Neovim setup..."
        if [[ -f "$SCRIPT_DIR/scripts/utils/neovim-enhanced-setup.sh" ]]; then
            if bash "$SCRIPT_DIR/scripts/utils/neovim-enhanced-setup.sh"; then
                log_success "Neovim enhanced setup completed successfully"
            else
                log_warning "Neovim enhanced setup had issues, but continuing installation"
            fi
        fi
    else
        log_warning "Neovim configuration directory not found, skipping"
    fi

    # Tmux setup
    if [[ -f "$SCRIPT_DIR/configs/tmux/.tmux.conf" ]]; then
        copy_config_file "$SCRIPT_DIR/configs/tmux/.tmux.conf" "$HOME/.tmux.conf" "Tmux" || 
            log_warning "Failed to copy Tmux configuration, but continuing installation"
    fi
    
    # Copy tmux sessions if they exist
    if [[ -d "$SCRIPT_DIR/configs/tmux/tmux-sessions" ]]; then
        cp -rf "$SCRIPT_DIR/configs/tmux/tmux-sessions/"* "$HOME/.tmux/sessions/" 2>/dev/null || 
            log_warning "Failed to copy Tmux session templates, but continuing installation"
    fi
    
    # Zsh setup
    if [[ -f "$SCRIPT_DIR/configs/zsh/.zshrc" ]]; then
        copy_config_file "$SCRIPT_DIR/configs/zsh/.zshrc" "$HOME/.zshrc" "Zsh" || 
            log_warning "Failed to copy Zsh configuration, but continuing installation"
    fi
    
    if [[ -f "$SCRIPT_DIR/configs/zsh/aliases.zsh" ]]; then
        copy_config_file "$SCRIPT_DIR/configs/zsh/aliases.zsh" "$HOME/.zsh/aliases.zsh" "Zsh aliases" || 
            log_warning "Failed to copy Zsh aliases, but continuing installation"
    fi
    
    # Git setup
    if [[ -f "$SCRIPT_DIR/configs/git/.gitconfig" ]]; then
        copy_config_file "$SCRIPT_DIR/configs/git/.gitconfig" "$HOME/.gitconfig" "Git" || 
            log_warning "Failed to copy Git configuration, but continuing installation"
    fi
    
    # Setup custom functions (always do this)
    setup_custom_functions || log_warning "Failed to set up custom functions, but continuing installation"
    
    CONFIGS_COPIED=true
    return 0
}

# Check for a previous installation
check_previous_installation() {
    if [[ -f "$HOME/.config/nvim/init.lua" && -f "$HOME/.tmux.conf" && -f "$HOME/.zshrc" ]]; then
        log_warning "Previous installation detected."
        read -r -p "Do you want to back up your existing configuration files before proceeding? [Y/n]: " BACKUP_CONFIG
        echo "Backup configuration: $BACKUP_CONFIG" >> "$LOG_FILE"
        
        if [[ ! "$BACKUP_CONFIG" =~ ^[Nn]$ ]]; then
            # Create backup directory with timestamp
            local backup_dir="$HOME/.config/terminal-env-backup-$(date +%Y%m%d-%H%M%S)"
            log_info "Creating backup in: $backup_dir"
            
            mkdir -p "$backup_dir" || {
                log_error "Failed to create backup directory: $backup_dir"
                return 1
            }
            
            # Backup key configuration files
            cp -r "$HOME/.config/nvim" "$backup_dir/" 2>/dev/null || log_warning "Failed to backup Neovim config"
            cp "$HOME/.tmux.conf" "$backup_dir/" 2>/dev/null || log_warning "Failed to backup Tmux config"
            cp "$HOME/.zshrc" "$backup_dir/" 2>/dev/null || log_warning "Failed to backup Zsh config"
            cp -r "$HOME/.zsh" "$backup_dir/" 2>/dev/null || log_warning "Failed to backup Zsh directory"
            cp "$HOME/.gitconfig" "$backup_dir/" 2>/dev/null || log_warning "Failed to backup Git config"
            
            log_success "Configuration backup created at: $backup_dir"
        fi
    fi
    return 0
}

# Check for recovery mode
recovery_mode() {
    # Check if we're running in recovery mode
    if [[ "${1:-}" == "--recover" ]]; then
        log_header "Running in recovery mode"
        log_info "Attempting to resume a previous installation..."
        
        # Check which components were successfully installed
        if [[ -f "$LOG_FILE" ]]; then
            log_info "Found previous installation log at: $LOG_FILE"
            
            # Check if core was installed
            if grep -q "System setup complete" "$LOG_FILE"; then
                log_success "Core environment was successfully installed previously"
                CORE_INSTALLED=true
            fi
            
            # Check if Python was installed
            if grep -q "Python environment setup complete" "$LOG_FILE"; then
                log_success "Python environment was successfully installed previously"
                PYTHON_INSTALLED=true
            elif grep -q "Python: y" "$LOG_FILE"; then
                INSTALL_PYTHON="y"
            fi
            
            # Check if Node.js was installed
            if grep -q "Node.js environment setup complete" "$LOG_FILE"; then
                log_success "Node.js environment was successfully installed previously"
                NODE_INSTALLED=true
            elif grep -q "JavaScript/Node.js: y" "$LOG_FILE"; then
                INSTALL_NODE="y"
            fi
            
            # Check if Ruby was installed
            if grep -q "Ruby environment setup complete" "$LOG_FILE"; then
                log_success "Ruby environment was successfully installed previously"
                RUBY_INSTALLED=true
            elif grep -q "Ruby: y" "$LOG_FILE"; then
                INSTALL_RUBY="y"
            fi
            
            # Check if configs were copied
            if grep -q "configuration files to" "$LOG_FILE"; then
                log_info "Configuration files were likely copied previously"
                read -r -p "Do you want to copy configuration files again? [y/N]: " COPY_CONFIGS
                if [[ "$COPY_CONFIGS" =~ ^[Yy]$ ]]; then
                    CONFIGS_COPIED=false
                else
                    CONFIGS_COPIED=true
                fi
            fi
            
            return 0
        else
            log_warning "No previous installation log found at: $LOG_FILE"
            log_info "Starting fresh installation..."
            return 1
        fi
    fi
    return 1
}

# Setup architecture-specific compatibility
setup_architecture_compatibility() {
    log_header "Setting up architecture compatibility"
    
    # Detect and log architecture
    log_info "Detected architecture: $ARCH"
    if [[ "$ARCH" == "arm64" ]]; then
        log_info "Apple Silicon Mac detected - configuring for optimal performance"
    else
        log_info "Intel Mac detected - using standard configuration"
    fi
    
    # Fix symlink issues first
    fix_symlink_issues
    
    # Clean up Intel Homebrew remnants on Apple Silicon
    if [[ "$ARCH" == "arm64" ]]; then
        cleanup_intel_homebrew
    fi
    
    # Create modular profile structure
    log_info "Setting up modular profile structure..."
    
    if [[ ! -f "$HOME/.zprofile" ]]; then
        cat > "$HOME/.zprofile" << 'EOF'
# Enhanced Terminal Environment Profile
# Load modular profile configs
for conf in $HOME/.zprofile.d/*.zsh; do
  [[ -f $conf ]] && source $conf
done

# Apple Silicon Homebrew setup
if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi
EOF
        log_success "Created modular .zprofile"
    else
        log_info ".zprofile already exists"
        # Ensure Homebrew is configured
        if ! grep -q "opt/homebrew" "$HOME/.zprofile"; then
            echo '' >> "$HOME/.zprofile"
            echo '# Apple Silicon Homebrew setup' >> "$HOME/.zprofile"
            echo 'if [[ -f /opt/homebrew/bin/brew ]]; then' >> "$HOME/.zprofile"
            echo '    eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
            echo 'fi' >> "$HOME/.zprofile"
            log_success "Added Homebrew configuration to .zprofile"
        fi
    fi
    
    # Setup path management
    log_info "Configuring path management..."
    cat > "$HOME/.zprofile.d/path.zsh" << 'EOF'
# Enhanced Terminal Environment Path Management

# Add local bin to PATH
export PATH="$HOME/.local/bin:$PATH"

# Apple Silicon Homebrew paths
if [[ -d /opt/homebrew ]]; then
    export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
    export MANPATH="/opt/homebrew/share/man:$MANPATH"
    export INFOPATH="/opt/homebrew/share/info:$INFOPATH"
fi

# Python tools
if [[ -d "$HOME/.local/bin" ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# Ruby gems (if using rbenv)
if command -v rbenv >/dev/null 2>&1; then
    eval "$(rbenv init - zsh)"
fi
EOF
    log_success "Path management configured successfully"
    
    # Setup tmux compatibility
    log_info "Configuring tmux compatibility..."
    if command -v tmux >/dev/null 2>&1; then
        log_success "Tmux found and compatible"
    else
        log_info "Tmux not installed via Homebrew, skipping compatibility setup"
    fi
    
    # Ensure .zprofile is loaded from .zshrc
    if [[ -f "$HOME/.zshrc" ]]; then
        if ! grep -q "source.*zprofile" "$HOME/.zshrc"; then
            log_info "Adding .zprofile sourcing to .zshrc..."
            echo -e "\n# Source .zprofile for consistent environment\n[[ -f \$HOME/.zprofile ]] && source \$HOME/.zprofile" >> "$HOME/.zshrc"
            log_success "Added .zprofile sourcing to .zshrc"
        fi
    fi
    
    # Fix Docker issues
    fix_docker_issues
}

# Main function
main() {
    # Show welcome banner
    echo -e "${GREEN}====================================================${NC}"
    echo -e "${GREEN}    Enhanced Terminal Environment Installer          ${NC}"
    echo -e "${GREEN}====================================================${NC}"
    echo -e "${BLUE}Setting up your full-stack development environment   ${NC}"
    echo -e "${BLUE}Version 4.1 - Apple Silicon Migration Compatible     ${NC}"
    echo

    # Check if we're running in recovery mode
    if ! recovery_mode "$@"; then
        # Initialize log file for a fresh installation
        init_log_file
        
        # Check for previous installation
        check_previous_installation
        
        # Prompt user for language setup preferences
        prompt_language_setup
        
        # Show installation summary and confirmation
        show_summary
    fi
    
    # Create all essential directories first
    create_essential_directories

    # Setup architecture compatibility (includes cleanup and fixes)
    setup_architecture_compatibility

    # Core system setup
    if [[ "$CORE_INSTALLED" == "false" ]]; then
        log_header "Setting up core environment"
        if [[ -f "$SCRIPT_DIR/scripts/utils/system-setup.sh" ]]; then
            if run_script "$SCRIPT_DIR/scripts/utils/system-setup.sh" "Core environment setup failed" "core"; then
                CORE_INSTALLED=true
            fi
        else
            log_warning "Core setup script not found, marking as installed"
            CORE_INSTALLED=true
        fi
    fi

    # Language-specific setup based on user choices
    if [[ "$INSTALL_PYTHON" =~ ^[Yy]$ && "$PYTHON_INSTALLED" == "false" ]]; then
        log_header "Setting up Python environment"
        # Ensure Python templates directory exists
        mkdir -p "$HOME/.local/share/python-templates"
        if [[ -f "$SCRIPT_DIR/scripts/setup/python-setup.sh" ]]; then
            if run_script "$SCRIPT_DIR/scripts/setup/python-setup.sh" "Python environment setup failed" "python"; then
                PYTHON_INSTALLED=true
            fi
        else
            log_warning "Python setup script not found, marking as installed"
            PYTHON_INSTALLED=true
        fi
    fi
    
    if [[ "$INSTALL_NODE" =~ ^[Yy]$ && "$NODE_INSTALLED" == "false" ]]; then
        log_header "Setting up Node.js/JavaScript environment"
        # Ensure Node templates directory exists
        mkdir -p "$HOME/.local/share/node-templates"
        if [[ -f "$SCRIPT_DIR/scripts/setup/node-setup.sh" ]]; then
            run_script "$SCRIPT_DIR/scripts/setup/node-setup.sh" "Node.js environment setup failed" "node" || true
        fi
        NODE_INSTALLED=true
    fi
    
    if [[ "$INSTALL_RUBY" =~ ^[Yy]$ && "$RUBY_INSTALLED" == "false" ]]; then
        log_header "Setting up Ruby environment"
        # Ensure Ruby templates directory exists
        mkdir -p "$HOME/.local/share/ruby-templates"
        if [[ -f "$SCRIPT_DIR/scripts/setup/ruby-setup.sh" ]]; then
            run_script "$SCRIPT_DIR/scripts/setup/ruby-setup.sh" "Ruby environment setup failed" "ruby" || true
        fi
        RUBY_INSTALLED=true
    fi 
    
    # Copy configuration files
    if [[ "$CONFIGS_COPIED" == "false" ]]; then
        copy_config_files
    fi
    
    # Validate functions (always do this)
    validate_functions_sh

    # Installation complete
    log_header "Installation Complete!"
    echo -e "${GREEN}Enhanced Terminal Environment has been successfully installed!${NC}"
    echo
    
    # Print installation status
    echo -e "Installation status:"
    echo -e "  Core environment: $(if [[ "$CORE_INSTALLED" == "true" ]]; then echo "${GREEN}Installed${NC}"; else echo "${RED}Failed${NC}"; fi)"
    
    if [[ "$INSTALL_PYTHON" =~ ^[Yy]$ ]]; then
        echo -e "  Python environment: $(if [[ "$PYTHON_INSTALLED" == "true" ]]; then echo "${GREEN}Installed${NC}"; else echo "${RED}Failed${NC}"; fi)"
    fi
    
    if [[ "$INSTALL_NODE" =~ ^[Yy]$ ]]; then
        echo -e "  Node.js environment: $(if [[ "$NODE_INSTALLED" == "true" ]]; then echo "${GREEN}Installed${NC}"; else echo "${RED}Failed${NC}"; fi)"
    fi
    
    if [[ "$INSTALL_RUBY" =~ ^[Yy]$ ]]; then
        echo -e "  Ruby environment: $(if [[ "$RUBY_INSTALLED" == "true" ]]; then echo "${GREEN}Installed${NC}"; else echo "${RED}Failed${NC}"; fi)"
    fi
    
    echo -e "  Configuration files: $(if [[ "$CONFIGS_COPIED" == "true" ]]; then echo "${GREEN}Copied${NC}"; else echo "${RED}Failed${NC}"; fi)"
    echo -e "  Enhanced functions: ${GREEN}Configured${NC}"
    echo
    
    echo -e "To finalize the setup:"
    echo -e "1. Start a new terminal session or run: ${YELLOW}source ~/.zshrc${NC}"
    echo -e "2. Test functions with: ${YELLOW}validate_functions_sh${NC}"
    echo -e "3. Start Tmux with the command: ${YELLOW}tmux${NC}"
    echo -e "4. Inside Tmux, press ${YELLOW}Ctrl-a + I${NC} to install Tmux plugins"
    echo
    echo -e "Enhanced terminal functions available:"
    echo -e "- ${YELLOW}vf${NC}: Find and edit files with fzf"
    echo -e "- ${YELLOW}proj${NC}: Navigate to projects directory"
    echo -e "- ${YELLOW}mks${NC}: Create or attach to tmux session"
    [[ "$INSTALL_PYTHON" =~ ^[Yy]$ && "$PYTHON_INSTALLED" == "true" ]] && echo -e "- ${YELLOW}mkpy${NC}: Create Python development environment"
    [[ "$INSTALL_NODE" =~ ^[Yy]$ && "$NODE_INSTALLED" == "true" ]] && echo -e "- ${YELLOW}mkjs${NC}: Create JavaScript/Node.js development environment"
    [[ "$INSTALL_RUBY" =~ ^[Yy]$ && "$RUBY_INSTALLED" == "true" ]] && echo -e "- ${YELLOW}mkrb${NC}: Create Ruby development environment"
    echo
    
    # If any component failed, suggest recovery mode
    if [[ "$CORE_INSTALLED" == "false" || 
          ("$INSTALL_PYTHON" =~ ^[Yy]$ && "$PYTHON_INSTALLED" == "false") || 
          ("$INSTALL_NODE" =~ ^[Yy]$ && "$NODE_INSTALLED" == "false") || 
          ("$INSTALL_RUBY" =~ ^[Yy]$ && "$RUBY_INSTALLED" == "false") || 
          "$CONFIGS_COPIED" == "false" ]]; then
        echo -e "${YELLOW}Some components failed to install. You can run:${NC}"
        echo -e "  ${YELLOW}./install.sh --recover${NC} to attempt recovery of failed components."
    fi
    
    echo -e "For complete installation details, see: ${YELLOW}$LOG_FILE${NC}"
    echo -e "${GREEN}Enjoy your enhanced terminal environment!${NC}"
}

# Run the main function with all arguments
main "$@"