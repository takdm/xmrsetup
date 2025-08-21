#!/bin/bash

# XMR - Unified Monero Setup and Mining Script for Arch Linux
# Combines installation, configuration, and mining functionality

set -e

# Version
VERSION="1.0.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default configuration
DEFAULT_WALLET="49KWETDKkDNP3v3NpdRPzaNACzx5srKGZPogcVBpgWReTBGcjA3nKywNQ5KTLjFNh6Ayqxcmpy2bqSnSFSxNgxsi78TwD1d"
DEFAULT_DATA_DIR="$HOME/xmrblock"

# Global variables for process management
MONEROD_PID=""
P2POOL_PID=""
XMRIG_PID=""

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

# Usage function
show_usage() {
    echo "XMR - Unified Monero Setup and Mining Script v$VERSION"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  install         Install monerod, p2pool, and xmrig"
    echo "  mine            Start mining processes"
    echo "  config          Generate default configuration files"
    echo "  status          Show installation status"
    echo "  version         Show version information"
    echo "  help            Show this help message"
    echo ""
    echo "Install Options:"
    echo "  --auto          Auto-install without prompts (recommended for scripts)"
    echo "  --no-update     Skip system package updates"
    echo "  --no-deps       Skip dependency installation"
    echo ""
    echo "Mining Options:"
    echo "  --wallet ADDR          Specify wallet address (default: built-in address)"
    echo "  --data-dir DIR         Specify data directory (default: ~/xmrblock)"
    echo "  --config               Use configuration files if available"
    echo "  --separate-terminals   Launch processes in separate terminals (default)"
    echo "  --integrated           Launch processes in same terminal (legacy mode)"
    echo ""
    echo "Configuration Options:"
    echo "  --wallet ADDR   Wallet address for configuration"
    echo "  --data-dir DIR  Data directory for blockchain"
    echo ""
    echo "Examples:"
    echo "  $0 install --auto              # Auto-install everything"
    echo "  $0 mine --wallet YOUR_WALLET   # Start mining in separate terminals"
    echo "  $0 mine --integrated            # Start mining in same terminal (old style)"
    echo "  $0 config --wallet YOUR_WALLET # Generate configs"
    echo "  $0 status                      # Check what's installed"
}

# Check if running on Arch Linux
check_arch_linux() {
    if [[ "$1" != "--quiet" ]]; then
        log_info "Checking if running on Arch Linux..."
    fi
    if [[ -f /etc/arch-release ]] || [[ -f /etc/os-release && $(grep -qi "arch" /etc/os-release) ]]; then
        if [[ "$1" != "--quiet" ]]; then
            log_success "Arch Linux detected"
        fi
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

# Validate network connectivity
check_network() {
    if [[ "$1" != "--quiet" ]]; then
        log_info "Checking network connectivity..."
    fi
    if curl -s --connect-timeout 10 https://api.github.com >/dev/null; then
        if [[ "$1" != "--quiet" ]]; then
            log_success "Network connectivity confirmed"
        fi
        return 0
    else
        if [[ "$1" != "--quiet" ]]; then
            log_warning "Network connectivity issue detected"
        fi
        return 1
    fi
}

# Detect available terminal emulator
detect_terminal() {
    local terminals=("gnome-terminal" "konsole" "xfce4-terminal" "mate-terminal" "xterm" "alacritty" "kitty" "terminator" "tilix")
    
    for terminal in "${terminals[@]}"; do
        if command_exists "$terminal"; then
            echo "$terminal"
            return 0
        fi
    done
    
    return 1
}

# Launch command in separate terminal
launch_in_terminal() {
    local cmd="$1"
    local title="$2"
    local terminal
    
    terminal=$(detect_terminal)
    if [[ $? -ne 0 ]]; then
        log_error "No suitable terminal emulator found. Please install one of: gnome-terminal, konsole, xfce4-terminal, xterm, alacritty, etc."
        return 1
    fi
    
    case "$terminal" in
        "gnome-terminal")
            gnome-terminal --title="$title" -- bash -c "$cmd; echo 'Process finished. Press Enter to close...'; read" &
            ;;
        "konsole")
            konsole --title="$title" -e bash -c "$cmd; echo 'Process finished. Press Enter to close...'; read" &
            ;;
        "xfce4-terminal")
            xfce4-terminal --title="$title" -e "bash -c '$cmd; echo \"Process finished. Press Enter to close...\"; read'" &
            ;;
        "mate-terminal")
            mate-terminal --title="$title" -e "bash -c '$cmd; echo \"Process finished. Press Enter to close...\"; read'" &
            ;;
        "alacritty")
            alacritty --title="$title" -e bash -c "$cmd; echo 'Process finished. Press Enter to close...'; read" &
            ;;
        "kitty")
            kitty --title="$title" bash -c "$cmd; echo 'Process finished. Press Enter to close...'; read" &
            ;;
        "terminator")
            terminator --title="$title" -e "bash -c '$cmd; echo \"Process finished. Press Enter to close...\"; read'" &
            ;;
        "tilix")
            tilix --title="$title" -e "bash -c '$cmd; echo \"Process finished. Press Enter to close...\"; read'" &
            ;;
        "xterm")
            xterm -title "$title" -e bash -c "$cmd; echo 'Process finished. Press Enter to close...'; read" &
            ;;
        *)
            # Fallback to xterm if detected terminal is not in our case statement
            xterm -title "$title" -e bash -c "$cmd; echo 'Process finished. Press Enter to close...'; read" &
            ;;
    esac
    
    return 0
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
        cd /
        rm -rf "$temp_dir"
        return 1
    fi
    
    log_info "Downloading xmrig from: $download_url"
    if wget -O xmrig.tar.gz "$download_url"; then
        log_success "Downloaded xmrig"
    else
        log_error "Failed to download xmrig"
        cd /
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Extract and install
    log_info "Extracting xmrig..."
    tar -xzf xmrig.tar.gz
    
    local xmrig_dir=$(ls -d xmrig-* | head -n1)
    if [[ -d "$xmrig_dir" && -f "$xmrig_dir/xmrig" ]]; then
        sudo cp "$xmrig_dir/xmrig" /usr/local/bin/
        sudo chmod +x /usr/local/bin/xmrig
        log_success "xmrig installed successfully"
    elif [[ -f xmrig ]]; then
        sudo cp xmrig /usr/local/bin/
        sudo chmod +x /usr/local/bin/xmrig
        log_success "xmrig installed successfully"
    else
        log_error "Failed to extract xmrig"
        cd /
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Cleanup
    cd /
    rm -rf "$temp_dir"
}

# Create configuration directories
create_config_dirs() {
    log_info "Creating configuration directories..."
    
    local config_dirs=("$HOME/.monero" "$HOME/.p2pool" "$HOME/.xmrig")
    
    for dir in "${config_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log_info "Created directory: $dir"
        else
            log_info "Directory already exists: $dir"
        fi
    done
    
    log_success "Configuration directories ready"
}

# Display installed versions
display_versions() {
    log_info "Checking installed versions..."
    echo ""
    echo "===================="
    echo "   Installed Tools"
    echo "===================="
    
    if command_exists monerod; then
        local monerod_version=$(monerod --version 2>/dev/null | head -n1 || echo "installed")
        echo -e "monerod: ${GREEN}$monerod_version${NC}"
    else
        echo -e "monerod: ${RED}Not installed${NC}"
    fi
    
    if command_exists p2pool; then
        local p2pool_version=$(p2pool --version 2>/dev/null || echo "installed")
        echo -e "p2pool: ${GREEN}$p2pool_version${NC}"
    else
        echo -e "p2pool: ${RED}Not installed${NC}"
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

# Generate default configuration files
generate_configs() {
    local wallet_addr="$1"
    local data_dir="$2"
    
    [[ -z "$wallet_addr" ]] && wallet_addr="$DEFAULT_WALLET"
    [[ -z "$data_dir" ]] && data_dir="$DEFAULT_DATA_DIR"
    
    log_info "Generating configuration files..."
    
    # Create config directories
    create_config_dirs
    
    # Generate monerod config
    cat > "$HOME/.monero/monerod.conf" << EOF
# Monero daemon configuration
data-dir=$data_dir
log-level=1
zmq-pub=tcp://127.0.0.1:18083
out-peers=32
in-peers=64
add-priority-node=p2pmd.xmrvsbeast.com:18080
add-priority-node=nodes.hashvault.pro:18080
disable-dns-checkpoints
enable-dns-blocklist
prune-blockchain
EOF
    
    # Generate p2pool config
    cat > "$HOME/.p2pool/p2pool.conf" << EOF
# P2Pool configuration
host=127.0.0.1
wallet=$wallet_addr
EOF
    
    # Generate xmrig config
    cat > "$HOME/.xmrig/config.json" << EOF
{
    "api": {
        "id": null,
        "worker-id": null
    },
    "http": {
        "enabled": false,
        "host": "127.0.0.1",
        "port": 0,
        "access-token": null,
        "restricted": true
    },
    "autosave": true,
    "background": false,
    "colors": true,
    "title": true,
    "randomx": {
        "init": -1,
        "init-avx2": -1,
        "mode": "auto",
        "1gb-pages": false,
        "rdmsr": true,
        "wrmsr": true,
        "cache_qos": false,
        "numa": true,
        "scratchpad_prefetch_mode": 1
    },
    "cpu": {
        "enabled": true,
        "huge-pages": true,
        "huge-pages-jit": false,
        "hw-aes": null,
        "priority": null,
        "memory-pool": false,
        "yield": true,
        "max-threads-hint": 100,
        "asm": true,
        "argon2-impl": null,
        "astrobwt-max-size": 550,
        "astrobwt-avx2": false,
        "cn/0": false,
        "cn-lite/0": false
    },
    "opencl": {
        "enabled": false,
        "cache": true,
        "loader": null,
        "platform": "AMD",
        "adl": true,
        "cn/0": false,
        "cn-lite/0": false
    },
    "cuda": {
        "enabled": false,
        "loader": null,
        "nvml": true,
        "cn/0": false,
        "cn-lite/0": false
    },
    "pools": [
        {
            "algo": null,
            "coin": null,
            "url": "127.0.0.1:3333",
            "user": "$wallet_addr",
            "pass": "x",
            "rig-id": null,
            "nicehash": false,
            "keepalive": false,
            "enabled": true,
            "tls": false,
            "tls-fingerprint": null,
            "daemon": false,
            "socks5": null,
            "self-select": null,
            "submit-to-origin": false
        }
    ],
    "print-time": 60,
    "health-print-time": 60,
    "dmi": true,
    "retries": 5,
    "retry-pause": 5,
    "syslog": false,
    "tls": {
        "enabled": false,
        "protocols": null,
        "cert": null,
        "cert_key": null,
        "ciphers": null,
        "ciphersuites": null,
        "dhparam": null
    },
    "user-agent": null,
    "verbose": 0,
    "watch": true,
    "pause-on-battery": false,
    "pause-on-active": false
}
EOF
    
    log_success "Configuration files generated:"
    echo "- ~/.monero/monerod.conf"
    echo "- ~/.p2pool/p2pool.conf"
    echo "- ~/.xmrig/config.json"
    echo ""
    echo "Wallet address: $wallet_addr"
    echo "Data directory: $data_dir"
}

# Signal handler for clean shutdown
cleanup() {
    echo ""
    echo "Shutting down mining processes..."
    if [[ -n "$MONEROD_PID" ]]; then
        kill "$MONEROD_PID" 2>/dev/null || true
        log_info "Stopped monerod (PID: $MONEROD_PID)"
    fi
    if [[ -n "$P2POOL_PID" ]]; then
        kill "$P2POOL_PID" 2>/dev/null || true
        log_info "Stopped p2pool (PID: $P2POOL_PID)"
    fi
    if [[ -n "$XMRIG_PID" ]]; then
        kill "$XMRIG_PID" 2>/dev/null || true
        log_info "Stopped xmrig (PID: $XMRIG_PID)"
    fi
    echo "All processes stopped."
    exit 0
}

# Install command
cmd_install() {
    local auto_mode=false
    local skip_update=false
    local skip_deps=false
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            --auto)
                auto_mode=true
                shift
                ;;
            --no-update)
                skip_update=true
                shift
                ;;
            --no-deps)
                skip_deps=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
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
    
    # Check network connectivity before proceeding
    if ! check_network; then
        if [[ "$auto_mode" == "true" ]]; then
            log_warning "Proceeding in auto mode despite network issues - downloads may fail"
        else
            log_warning "Proceeding without network verification - some downloads may fail"
            read -p "Continue anyway? (y/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "Aborted by user"
                exit 0
            fi
        fi
    fi
    
    # Update system
    if [[ "$skip_update" != "true" ]]; then
        if [[ "$auto_mode" == "true" ]]; then
            update_system
        else
            read -p "Update system packages? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                update_system
            fi
        fi
    fi
    
    # Install dependencies
    if [[ "$skip_deps" != "true" ]]; then
        install_dependencies
    fi
    
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
    echo "1. Generate configs: $0 config --wallet YOUR_WALLET_ADDRESS"
    echo "2. Start mining: $0 mine"
    echo "3. Check status: $0 status"
    echo ""
    echo "Configuration files can be stored in:"
    echo "- ~/.monero/"
    echo "- ~/.p2pool/"
    echo "- ~/.xmrig/"
}

# Mining command
cmd_mine() {
    local wallet_addr="$DEFAULT_WALLET"
    local data_dir="$DEFAULT_DATA_DIR"
    local use_config=false
    local separate_terminals=true
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            --wallet)
                wallet_addr="$2"
                shift 2
                ;;
            --data-dir)
                data_dir="$2"
                shift 2
                ;;
            --config)
                use_config=true
                shift
                ;;
            --integrated)
                separate_terminals=false
                shift
                ;;
            --separate-terminals)
                separate_terminals=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Set up signal handlers
    trap cleanup SIGINT SIGTERM
    
    echo "Starting Monero mining setup..."
    echo "==============================="
    echo "Wallet: $wallet_addr"
    echo "Data directory: $data_dir"
    echo "Mode: $(if [[ "$separate_terminals" == "true" ]]; then echo "Separate terminals"; else echo "Integrated"; fi)"
    echo ""
    
    # Check if tools are installed
    for tool in monerod p2pool xmrig; do
        if ! command_exists "$tool"; then
            log_error "$tool not found in PATH. Please run '$0 install' first."
            exit 1
        fi
    done
    
    if [[ "$separate_terminals" == "true" ]]; then
        # Check if we can launch separate terminals
        if ! detect_terminal >/dev/null; then
            log_warning "No suitable terminal emulator found. Falling back to integrated mode."
            separate_terminals=false
        fi
    fi
    
    if [[ "$separate_terminals" == "true" ]]; then
        # Launch processes in separate terminals
        echo "Launching processes in separate terminals..."
        
        # Start monerod
        echo "Starting monerod in separate terminal..."
        if [[ "$use_config" == "true" && -f "$HOME/.monero/monerod.conf" ]]; then
            launch_in_terminal "monerod --config-file=\"$HOME/.monero/monerod.conf\"" "Monero Daemon (monerod)"
        else
            launch_in_terminal "monerod --zmq-pub tcp://127.0.0.1:18083 --out-peers 32 --in-peers 64 --add-priority-node=p2pmd.xmrvsbeast.com:18080 --add-priority-node=nodes.hashvault.pro:18080 --disable-dns-checkpoints --enable-dns-blocklist --prune-blockchain --data-dir=\"$data_dir\"" "Monero Daemon (monerod)"
        fi
        log_success "Started monerod in separate terminal"
        
        # Wait a moment for monerod to start
        sleep 8
        
        # Start p2pool
        echo "Starting p2pool in separate terminal..."
        if [[ "$use_config" == "true" && -f "$HOME/.p2pool/p2pool.conf" ]]; then
            launch_in_terminal "p2pool --config-file=\"$HOME/.p2pool/p2pool.conf\"" "P2Pool Mining Pool"
        else
            launch_in_terminal "p2pool --host 127.0.0.1 --wallet \"$wallet_addr\"" "P2Pool Mining Pool"
        fi
        log_success "Started p2pool in separate terminal"
        
        # Wait a moment for p2pool to start
        sleep 8
        
        # Start xmrig
        echo "Starting xmrig in separate terminal..."
        if [[ "$use_config" == "true" && -f "$HOME/.xmrig/config.json" ]]; then
            launch_in_terminal "xmrig --config=\"$HOME/.xmrig/config.json\"" "XMRig CPU Miner"
        else
            launch_in_terminal "xmrig -o 127.0.0.1:3333 -u \"$wallet_addr\"" "XMRig CPU Miner"
        fi
        log_success "Started xmrig in separate terminal"
        
        echo ""
        echo "Mining processes started successfully in separate terminals!"
        echo "========================================================="
        echo "- monerod: Running in separate terminal window"
        echo "- p2pool:  Running in separate terminal window"
        echo "- xmrig:   Running in separate terminal window"
        echo ""
        echo "To stop mining:"
        echo "1. Close the terminal windows manually, or"
        echo "2. Use 'pkill monerod && pkill p2pool && pkill xmrig'"
        echo ""
        echo "Press [CTRL+C] or close this terminal to exit the launcher."
        
        # Keep this script running so user can stop it with Ctrl+C
        while true; do
            sleep 1
        done
        
    else
        # Original integrated mode
        # Start monerod
        echo "Starting monerod..."
        if [[ "$use_config" == "true" && -f "$HOME/.monero/monerod.conf" ]]; then
            monerod --config-file="$HOME/.monero/monerod.conf" &
        else
            monerod --zmq-pub tcp://127.0.0.1:18083 \
              --out-peers 32 --in-peers 64 \
              --add-priority-node=p2pmd.xmrvsbeast.com:18080 \
              --add-priority-node=nodes.hashvault.pro:18080 \
              --disable-dns-checkpoints --enable-dns-blocklist \
              --prune-blockchain --data-dir="$data_dir" &
        fi
        MONEROD_PID=$!
        log_success "Started monerod (PID: $MONEROD_PID)"
        
        # Wait a moment for monerod to start
        sleep 5
        
        # Start p2pool
        echo "Starting p2pool..."
        if [[ "$use_config" == "true" && -f "$HOME/.p2pool/p2pool.conf" ]]; then
            p2pool --config-file="$HOME/.p2pool/p2pool.conf" &
        else
            p2pool --host 127.0.0.1 --wallet "$wallet_addr" &
        fi
        P2POOL_PID=$!
        log_success "Started p2pool (PID: $P2POOL_PID)"
        
        # Wait a moment for p2pool to start
        sleep 5
        
        # Start xmrig
        echo "Starting xmrig..."
        if [[ "$use_config" == "true" && -f "$HOME/.xmrig/config.json" ]]; then
            xmrig --config="$HOME/.xmrig/config.json" &
        else
            xmrig -o 127.0.0.1:3333 -u "$wallet_addr" &
        fi
        XMRIG_PID=$!
        log_success "Started xmrig (PID: $XMRIG_PID)"
        
        echo ""
        echo "Mining processes started successfully!"
        echo "====================================="
        echo "monerod PID: $MONEROD_PID"
        echo "p2pool PID: $P2POOL_PID"
        echo "xmrig PID: $XMRIG_PID"
        echo ""
        echo "Press [CTRL+C] to stop all mining processes."
        echo "Waiting for processes to complete..."
        
        # Wait for all processes
        wait
    fi
}

# Config command
cmd_config() {
    local wallet_addr=""
    local data_dir="$DEFAULT_DATA_DIR"
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            --wallet)
                wallet_addr="$2"
                shift 2
                ;;
            --data-dir)
                data_dir="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    if [[ -z "$wallet_addr" ]]; then
        echo "Enter your Monero wallet address (or press Enter for default):"
        read -r wallet_input
        if [[ -n "$wallet_input" ]]; then
            wallet_addr="$wallet_input"
        else
            wallet_addr="$DEFAULT_WALLET"
            log_warning "Using default wallet address - please change this for real mining!"
        fi
    fi
    
    generate_configs "$wallet_addr" "$data_dir"
}

# Status command
cmd_status() {
    echo "========================================="
    echo "    XMR Tools Installation Status"
    echo "========================================="
    echo ""
    
    check_arch_linux --quiet
    check_network --quiet
    
    display_versions
    
    echo "Configuration Files:"
    echo "===================="
    
    local config_files=(
        "$HOME/.monero/monerod.conf"
        "$HOME/.p2pool/p2pool.conf" 
        "$HOME/.xmrig/config.json"
    )
    
    for config in "${config_files[@]}"; do
        if [[ -f "$config" ]]; then
            echo -e "$(basename "$config"): ${GREEN}Found${NC}"
        else
            echo -e "$(basename "$config"): ${RED}Not found${NC}"
        fi
    done
    
    echo ""
    echo "Ready to mine: $(if command_exists monerod && command_exists p2pool && command_exists xmrig; then echo -e "${GREEN}Yes${NC}"; else echo -e "${RED}No${NC} - run '$0 install' first"; fi)"
}

# Version command
cmd_version() {
    echo "XMR - Unified Monero Setup and Mining Script"
    echo "Version: $VERSION"
    echo ""
    echo "This script combines installation, configuration, and mining"
    echo "functionality for Monero tools on Arch Linux."
}

# Main function
main() {
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 1
    fi
    
    local command="$1"
    shift
    
    case "$command" in
        install)
            cmd_install "$@"
            ;;
        mine)
            cmd_mine "$@"
            ;;
        config)
            cmd_config "$@"
            ;;
        status)
            cmd_status "$@"
            ;;
        version)
            cmd_version "$@"
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            log_error "Unknown command: $command"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# For compatibility with existing tests - expose functions when sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Script is being sourced, make functions available
    return 0
fi

# Run main function if script is executed directly
main "$@"