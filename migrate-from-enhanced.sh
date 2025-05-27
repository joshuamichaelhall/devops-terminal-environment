#!/usr/bin/env bash
# Migration script from enhanced-terminal-environment to devops-terminal-environment

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OLD_ENV_DIR="$HOME/repos/enhanced-terminal-environment"
NEW_ENV_DIR="$SCRIPT_DIR"

echo -e "${BLUE}=== DevOps Terminal Environment Migration ===${NC}"
echo "Migrating from: $OLD_ENV_DIR"
echo "Migrating to: $NEW_ENV_DIR"
echo

# Function to backup existing configs
backup_configs() {
    local backup_dir="$HOME/.config/devops-env-backup-$(date +%Y%m%d-%H%M%S)"
    echo -e "${YELLOW}Creating backup at: $backup_dir${NC}"
    mkdir -p "$backup_dir"
    
    # Backup existing configurations
    [[ -f "$HOME/.zshrc" ]] && cp "$HOME/.zshrc" "$backup_dir/" || true
    [[ -f "$HOME/.tmux.conf" ]] && cp "$HOME/.tmux.conf" "$backup_dir/" || true
    [[ -d "$HOME/.config/nvim" ]] && cp -r "$HOME/.config/nvim" "$backup_dir/" 2>/dev/null || true
    [[ -f "$HOME/.gitconfig" ]] && cp "$HOME/.gitconfig" "$backup_dir/" || true
    
    echo -e "${GREEN}✓ Backup completed${NC}"
}

# Function to uninstall old environment
uninstall_old() {
    echo -e "${YELLOW}Removing old enhanced-terminal-environment links...${NC}"
    
    # Remove old symlinks
    local files_to_remove=(
        "$HOME/.zshrc"
        "$HOME/.tmux.conf"
        "$HOME/.config/nvim"
        "$HOME/.gitconfig"
    )
    
    for file in "${files_to_remove[@]}"; do
        if [[ -L "$file" ]] && [[ "$(readlink "$file")" == *"enhanced-terminal-environment"* ]]; then
            echo "  Removing old symlink: $file"
            rm -f "$file"
        fi
    done
    
    # Remove old source lines from shell configs
    for rc_file in "$HOME/.bashrc" "$HOME/.zshrc.bak"; do
        if [[ -f "$rc_file" ]]; then
            sed -i.bak '/enhanced-terminal-environment/d' "$rc_file"
        fi
    done
    
    echo -e "${GREEN}✓ Old environment cleaned${NC}"
}

# Function to update install script references
update_install_script() {
    echo -e "${YELLOW}Updating installation script...${NC}"
    
    # Update the install.sh script to reflect new paths and remove language-specific setups
    sed -i.bak \
        -e 's/enhanced-terminal-environment/devops-terminal-environment/g' \
        -e '/ruby-setup\.sh/d' \
        -e '/node-setup\.sh/d' \
        "$NEW_ENV_DIR/install.sh"
    
    echo -e "${GREEN}✓ Installation script updated${NC}"
}

# Function to install new environment
install_new() {
    echo -e "${YELLOW}Installing DevOps Terminal Environment...${NC}"
    
    # Make install script executable
    chmod +x "$NEW_ENV_DIR/install.sh"
    
    # Run the installation
    cd "$NEW_ENV_DIR"
    ./install.sh
    
    # Source the new DevOps functions
    local devops_source="source $NEW_ENV_DIR/scripts/devops/devops-functions.sh"
    local k8s_source="source $NEW_ENV_DIR/configs/kubernetes/kubectl-config.zsh"
    local helm_source="source $NEW_ENV_DIR/configs/helm/helm-config.zsh"
    local argo_source="source $NEW_ENV_DIR/configs/argocd/argocd-config.zsh"
    local monitoring_source="source $NEW_ENV_DIR/configs/monitoring/monitoring-config.zsh"
    local cicd_source="source $NEW_ENV_DIR/configs/cicd/cicd-config.zsh"
    
    # Add to .zshrc if not already present
    if ! grep -q "devops-functions.sh" "$HOME/.zshrc"; then
        echo -e "\n# DevOps Terminal Environment" >> "$HOME/.zshrc"
        echo "$devops_source" >> "$HOME/.zshrc"
        echo "$k8s_source" >> "$HOME/.zshrc"
        echo "$helm_source" >> "$HOME/.zshrc"
        echo "$argo_source" >> "$HOME/.zshrc"
        echo "$monitoring_source" >> "$HOME/.zshrc"
        echo "$cicd_source" >> "$HOME/.zshrc"
    fi
    
    echo -e "${GREEN}✓ New environment installed${NC}"
}

# Function to validate installation
validate_installation() {
    echo -e "${YELLOW}Validating installation...${NC}"
    
    local validation_passed=true
    
    # Check symlinks
    for file in .zshrc .tmux.conf .gitconfig; do
        if [[ -L "$HOME/$file" ]] && [[ "$(readlink "$HOME/$file")" == *"devops-terminal-environment"* ]]; then
            echo -e "  ${GREEN}✓${NC} $file linked correctly"
        else
            echo -e "  ${RED}✗${NC} $file not linked"
            validation_passed=false
        fi
    done
    
    # Check Neovim config
    if [[ -L "$HOME/.config/nvim" ]] && [[ "$(readlink "$HOME/.config/nvim")" == *"devops-terminal-environment"* ]]; then
        echo -e "  ${GREEN}✓${NC} Neovim config linked correctly"
    else
        echo -e "  ${RED}✗${NC} Neovim config not linked"
        validation_passed=false
    fi
    
    # Check for DevOps tools
    local tools=("docker" "kubectl" "terraform" "aws" "git")
    echo -e "\n${YELLOW}Checking DevOps tools:${NC}"
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            echo -e "  ${GREEN}✓${NC} $tool installed"
        else
            echo -e "  ${YELLOW}!${NC} $tool not found (install separately)"
        fi
    done
    
    if [[ "$validation_passed" == true ]]; then
        echo -e "\n${GREEN}✓ Migration completed successfully!${NC}"
    else
        echo -e "\n${YELLOW}! Migration completed with warnings${NC}"
    fi
}

# Main migration flow
main() {
    echo -e "${YELLOW}This will migrate your terminal environment from enhanced to DevOps-focused.${NC}"
    read -p "Continue? (y/n) " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Migration cancelled."
        exit 0
    fi
    
    # Check if old environment exists
    if [[ ! -d "$OLD_ENV_DIR" ]]; then
        echo -e "${YELLOW}Old environment not found at: $OLD_ENV_DIR${NC}"
        echo "Proceeding with fresh installation..."
    else
        backup_configs
        uninstall_old
    fi
    
    update_install_script
    install_new
    validate_installation
    
    echo
    echo -e "${BLUE}=== Next Steps ===${NC}"
    echo "1. Restart your terminal or run: source ~/.zshrc"
    echo "2. Install any missing DevOps tools (see warnings above)"
    echo "3. Run 'devops_info' to check your environment"
    echo "4. Explore the new learning guides in: $NEW_ENV_DIR/learning_guides/"
    echo
    echo -e "${GREEN}Happy DevOps journey! 🚀${NC}"
}

# Run main function
main "$@"