#!/bin/bash

# XMR Setup Script for Arch Linux
# Automatically checks for and installs monerod, p2pool, and xmrig

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on Arch Linux
check_arch_linux() {
    log_info "Checking if running on Arch Linux..."
    if [[ -f /etc/arch-release ]] || [[ -f /etc/os-release && $(grep -i "arch" /etc/os-release) ]]; then
        log_success "Arch Linux detected"
        return 0
    else
        log_error "This script is designed for Arch Linux only"
        exit 1
    fi
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Update system packages
update_system() {
    log_info "Updating system packages..."
    if sudo pacman -Syu --noconfirm; then
        log_success "System packages updated"
    else
        log_error "Failed to update system packages"
        exit 1
    fi
}

# Install dependencies
install_dependencies() {
    log_info "Installing required dependencies..."
    local deps=("base-devel" "git" "cmake" "wget" "curl" "unzip" "tar")
    
    for dep in "${deps[@]}"; do
        if ! pacman -Qi "$dep" &>/dev/null; then
            log_info "Installing $dep..."
            if sudo pacman -S --noconfirm "$dep"; then
                log_success "$dep installed"
            else
                log_warning "Failed to install $dep"
            fi
        else
            log_info "$dep is already installed"
        fi
    done
}

# Check and install monerod
install_monerod() {
    log_info "Checking for monerod (Monero daemon)..."

    if command_exists monerod; then
        local version=$(monerod --version 2>/dev/null | head -n1 || echo "unknown")
        log_success "monerod is already installed: $version"
        return 0
    fi

    log_info "monerod not found. Installing from official Monero releases..."

    # Create temporary directory
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"

    # Get the latest release info from GitHub API
    local latest_url="https://api.github.com/repos/monero-project/monero/releases/latest"
    local download_url=$(curl -s "$latest_url" | grep "browser_download_url.*linux-x64" | cut -d '"' -f 4)

    if [[ -z "$download_url" ]]; then
        log_warning "Failed to get Monero download URL. Trying yay as a backup..."
        if command_exists yay; then
            log_info "Installing monero from AUR using yay..."
            if yay -S --noconfirm monero; then
                log_success "monero installed from AUR"
                cd /
                rm -rf "$temp_dir"
                return 0
            else
                log_error "Failed to install monero from AUR. Aborting."
                cd /
                rm -rf "$temp_dir"
                return 1
            fi
        else
            log_error "Neither direct download nor yay available for monero. Aborting."
            cd /
            rm -rf "$temp_dir"
            return 1
        fi
    fi

    log_info "Downloading Monero from: $download_url"
    if wget -O monero.tar.bz2 "$download_url"; then
        log_success "Downloaded Monero"
    else
        log_warning "Failed to download Monero. Trying yay as a backup..."
        if command_exists yay; then
            log_info "Installing monero from AUR using yay..."
            if yay -S --noconfirm monero; then
                log_success "monero installed from AUR"
                cd /
                rm -rf "$temp_dir"
                return 0
            else
                log_error "Failed to install monero from AUR. Aborting."
                cd /
                rm -rf "$temp_dir"
                return 1
            fi
        else
            log_error "Neither direct download nor yay available for monero. Aborting."
            cd /
            rm -rf "$temp_dir"
            return 1
        fi
    fi

    # Extract and install
    log_info "Extracting Monero..."
    tar -xjf monero.tar.bz2

    local monero_dir=$(ls -d monero-*-linux-x64 | head -n1)
    if [[ -d "$monero_dir" ]]; then
        sudo cp "$monero_dir/monerod" /usr/local/bin/
        sudo cp "$monero_dir/monero-wallet-cli" /usr/local/bin/
        sudo cp "$monero_dir/monero-wallet-rpc" /usr/local/bin/
        sudo chmod +x /usr/local/bin/monerod
        sudo chmod +x /usr/local/bin/monero-wallet-cli
        sudo chmod +x /usr/local/bin/monero-wallet-rpc
        log_success "monerod installed successfully"
    else
        log_warning "Failed to extract Monero. Trying yay as a backup..."
        if command_exists yay; then
            log_info "Installing monero from AUR using yay..."
            if yay -S --noconfirm monero; then
                log_success "monero installed from AUR"
                cd /
                rm -rf "$temp_dir"
                return 0
            else
                log_error "Failed to install monero from AUR. Aborting."
                cd /
                rm -rf "$temp_dir"
                return 1
            fi
        else
            log_error "Neither direct download nor yay available for monero. Aborting."
            cd /
            rm -rf "$temp_dir"
            return 1
        fi
    fi

    # Cleanup
    cd /
    rm -rf "$temp_dir"
}

# Check and install p2pool
install_p2pool() {
    log_info "Checking for p2pool..."
    
    if command_exists p2pool; then
        local version=$(p2pool --version 2>/dev/null || echo "unknown")
        log_success "p2pool is already installed: $version"
        return 0
    fi
    
    log_info "p2pool not found. Installing from official releases..."
    
    # Create temporary directory
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # Get the latest release info from GitHub API
    local latest_url="https://api.github.com/repos/SChernykh/p2pool/releases/latest"
    local download_url=$(curl -s "$latest_url" | grep "browser_download_url.*linux-x64" | cut -d '"' -f 4)
    
    if [[ -z "$download_url" ]]; then
        log_error "Failed to get p2pool download URL"
        return 1
    fi
    
    log_info "Downloading p2pool from: $download_url"
    if wget -O p2pool.tar.gz "$download_url"; then
        log_success "Downloaded p2pool"
    else
        log_error "Failed to download p2pool"
        return 1
    fi
    
    # Extract and install
    log_info "Extracting p2pool..."
    tar -xzf p2pool.tar.gz
    
    if [[ -f p2pool ]]; then
        sudo cp p2pool /usr/local/bin/
        sudo chmod +x /usr/local/bin/p2pool
        log_success "p2pool installed successfully"
    else
        log_error "Failed to extract p2pool"
        return 1
    fi
    
    # Cleanup
    cd /
    rm -rf "$temp_dir"
}

# Check and install xmrig
install_xmrig() {
    log_info "Checking for xmrig..."
    
    if command_exists xmrig; then
        local version=$(xmrig --version 2>/dev/null | head -n1 || echo "unknown")
        log_success "xmrig is already installed: $version"
        return 0
    fi
    
    # Try to install from AUR first (if yay is available)
    if command_exists yay; then
        log_info "Installing xmrig from AUR using yay..."
        if yay -S --noconfirm xmrig; then
            log_success "xmrig installed from AUR"
            return 0
        else
            log_warning "Failed to install xmrig from AUR, trying manual installation"
        fi
    fi
    
    log_info "xmrig not found. Installing from official releases..."
    
    # Create temporary directory
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # Get the latest release info from GitHub API
    local latest_url="https://api.github.com/repos/xmrig/xmrig/releases/latest"
    local download_url=$(curl -s "$latest_url" | grep "browser_download_url.*linux-x64" | cut -d '"' -f 4)
    
    if [[ -z "$download_url" ]]; then
        log_error "Failed to get xmrig download URL"
        return 1
    fi
    
    log_info "Downloading xmrig from: $download_url"
    if wget -O xmrig.tar.gz "$download_url"; then
        log_success "Downloaded xmrig"
    else
        log_error "Failed to download xmrig"
        return 1
    fi
    
    # Extract and install
    log_info "Checking for p2pool..."

    if command_exists p2pool; then
        local version=$(p2pool --version 2>/dev/null || echo "unknown")
        log_success "p2pool is already installed: $version"
        return 0
    fi

    log_info "p2pool not found. Installing from official releases..."

    # Create temporary directory
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"

    # Get the latest release info from GitHub API
    local latest_url="https://api.github.com/repos/SChernykh/p2pool/releases/latest"
    local download_url=$(curl -s "$latest_url" | grep "browser_download_url.*linux-x64" | cut -d '"' -f 4)

    if [[ -z "$download_url" ]]; then
        log_warning "Failed to get p2pool download URL. Trying yay as a backup..."
        if command_exists yay; then
            log_info "Installing p2pool from AUR using yay..."
            if yay -S --noconfirm p2pool; then
                log_success "p2pool installed from AUR"
                cd /
                rm -rf "$temp_dir"
                return 0
            else
                log_error "Failed to install p2pool from AUR. Aborting."
                cd /
                rm -rf "$temp_dir"
                return 1
            fi
        else
            log_error "Neither direct download nor yay available for p2pool. Aborting."
            cd /
            rm -rf "$temp_dir"
            return 1
        fi
    fi

    log_info "Downloading p2pool from: $download_url"
    if wget -O p2pool.tar.gz "$download_url"; then
        log_success "Downloaded p2pool"
    else
        log_warning "Failed to download p2pool. Trying yay as a backup..."
        if command_exists yay; then
            log_info "Installing p2pool from AUR using yay..."
            if yay -S --noconfirm p2pool; then
                log_success "p2pool installed from AUR"
                cd /
                rm -rf "$temp_dir"
                return 0
            else
                log_error "Failed to install p2pool from AUR. Aborting."
                cd /
                rm -rf "$temp_dir"
                return 1
            fi
        else
            log_error "Neither direct download nor yay available for p2pool. Aborting."
            cd /
            rm -rf "$temp_dir"
            return 1
        fi
    fi

    # Extract and install
    log_info "Extracting p2pool..."
    tar -xzf p2pool.tar.gz

    if [[ -f p2pool ]]; then
        sudo cp p2pool /usr/local/bin/
        sudo chmod +x /usr/local/bin/p2pool
        log_success "p2pool installed successfully"
    else
        log_warning "Failed to extract p2pool. Trying yay as a backup..."
        if command_exists yay; then
            log_info "Installing p2pool from AUR using yay..."
            if yay -S --noconfirm p2pool; then
                log_success "p2pool installed from AUR"
                cd /
                rm -rf "$temp_dir"
                return 0
            else
                log_error "Failed to install p2pool from AUR. Aborting."
                cd /
                rm -rf "$temp_dir"
                return 1
            fi
        else
            log_error "Neither direct download nor yay available for p2pool. Aborting."
            cd /
            rm -rf "$temp_dir"
            return 1
        fi
    fi

    # Cleanup
    cd /
    rm -rf "$temp_dir"
    fi
    
    if command_exists xmrig; then
        local xmrig_version=$(xmrig --version 2>/dev/null | head -n1 || echo "installed")
        echo -e "xmrig: ${GREEN}$xmrig_version${NC}"
    else
        echo -e "xmrig: ${RED}Not installed${NC}"
    fi
    
    echo "===================="
    echo ""
}

# Main function
main() {
    echo "========================================="
    echo "    XMR Setup Script for Arch Linux"
    echo "========================================="
    echo ""
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root"
        exit 1
    fi
    
    # Check Arch Linux
    check_arch_linux
    
    # Update system
    read -p "Update system packages? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        update_system
    fi
    
    # Install dependencies
    install_dependencies
    
    # Install tools
    echo ""
    log_info "Installing Monero tools..."
    install_monerod
    install_p2pool
    install_xmrig
    
    # Create config directories
    create_config_dirs
    
    # Display results
    display_versions
    
    log_success "XMR setup completed!"
    echo ""
    echo "Next steps:"
    echo "1. Configure monerod: monerod --help"
    echo "2. Configure p2pool: p2pool --help"
    echo "3. Configure xmrig: xmrig --help"
    echo ""
    echo "Configuration files are stored in:"
    echo "- ~/.monero/"
    echo "- ~/.p2pool/"
    echo "- ~/.xmrig/"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi