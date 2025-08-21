# XMR Setup - Arch Linux

An automated setup script for Arch Linux that checks for and installs essential Monero (XMR) mining and node tools.

## What it does

This script automatically installs and configures:

- **monerod** - The official Monero daemon for running a full node
- **p2pool** - Decentralized mining pool for Monero
- **xmrig** - High-performance CPU miner for Monero

## Features

- ✅ **Unified interface** - One script for installation, configuration, and mining
- ✅ **Separate terminal mode** - Each process runs in its own terminal window for better monitoring
- ✅ **Auto-configure mode** - No prompts needed for automated setups
- ✅ **Configuration generation** - Creates optimal config files automatically  
- ✅ Arch Linux compatibility check
- ✅ Automatic detection of already installed tools
- ✅ Downloads from official sources and releases
- ✅ System dependency management
- ✅ User-friendly colored output and progress indicators
- ✅ Creates configuration directories
- ✅ Installation summary and next steps
- ✅ **Backward compatibility** - Legacy scripts still work

## Requirements

- Arch Linux (or Arch-based distribution)
- Internet connection  
- sudo privileges
- For separate terminal mode: A supported terminal emulator (gnome-terminal, konsole, xfce4-terminal, xterm, etc.)

## Quick Install

**New Unified Script (Recommended):**

The new `xmr.sh` script combines installation, configuration, and mining functionality:

```bash
# Auto-install everything without prompts
curl -fsSL https://raw.githubusercontent.com/takdm/xmrsetup/main/xmr.sh | bash -s install --auto

# Or download and use locally
wget https://raw.githubusercontent.com/takdm/xmrsetup/main/xmr.sh
chmod +x xmr.sh
./xmr.sh install --auto
```

**Legacy Method (Still Supported):**

```bash
curl -fsSL https://raw.githubusercontent.com/takdm/xmrsetup/main/xmrsetup.sh | bash
```

That's it! The script will automatically install monerod, p2pool, and xmrig for you.

## Auto-Configure Feature

The new unified script includes auto-configuration that eliminates manual prompts:

```bash
# Install with automatic configuration (no prompts)
./xmr.sh install --auto

# Generate configuration files with your wallet
./xmr.sh config --wallet YOUR_WALLET_ADDRESS

# Start mining with your wallet
./xmr.sh mine --wallet YOUR_WALLET_ADDRESS

# Or use generated config files
./xmr.sh mine --config

# Check installation status
./xmr.sh status
```

## Update

To update your existing installation:

```bash
# Re-run the install script - it will detect existing tools and update them
curl -fsSL https://raw.githubusercontent.com/takdm/xmrsetup/main/xmrsetup.sh | bash
```

Or manually update each tool:

```bash
# Update system packages first
sudo pacman -Syu

# Then re-run the setup script to get the latest versions
./xmrsetup.sh
```

## Detailed Installation

If you prefer to clone the repository first:

```bash
git clone https://github.com/takdm/xmrsetup.git
cd xmrsetup
./xmrsetup.sh
```

The script will automatically:
- ✅ Verify you're running Arch Linux
- ✅ Install system dependencies  
- ✅ Download latest versions from official sources
- ✅ Create configuration directories
- ✅ Show installation summary

## Usage After Installation

### New Unified Interface (Recommended)

```bash
# Generate configuration files
./xmr.sh config --wallet YOUR_WALLET_ADDRESS

# Start mining in separate terminals (default - easier to monitor)
./xmr.sh mine --wallet YOUR_WALLET_ADDRESS
# OR use existing config files:
./xmr.sh mine --config

# Start mining in integrated mode (legacy behavior)
./xmr.sh mine --wallet YOUR_WALLET_ADDRESS --integrated

# Check what's installed
./xmr.sh status

# Get help
./xmr.sh help
```

#### Separate Terminal Mode (Default)

By default, the mining command now launches each process (monerod, p2pool, xmrig) in its own separate terminal window. This provides several benefits:

- **Better monitoring**: Each process has its own window with a clear title
- **Independent control**: You can close individual processes without affecting others
- **Cleaner output**: No mixed output from different processes
- **Easier debugging**: Issues with specific processes are easier to identify

**Supported terminal emulators**: gnome-terminal, konsole, xfce4-terminal, mate-terminal, xterm, alacritty, kitty, terminator, tilix

```bash
# Start mining with separate terminals (default)
./xmr.sh mine --wallet YOUR_WALLET_ADDRESS

# Explicitly request separate terminals
./xmr.sh mine --wallet YOUR_WALLET_ADDRESS --separate-terminals
```

#### Integrated Mode (Legacy)

If you prefer the old behavior where all processes run in the same terminal, use the `--integrated` option:

```bash
# Start mining in same terminal (old style)
./xmr.sh mine --wallet YOUR_WALLET_ADDRESS --integrated
```

#### Stopping Mining Processes

**In separate terminal mode:**
- Simply close the individual terminal windows, or
- Use the command: `pkill monerod && pkill p2pool && pkill xmrig`

**In integrated mode:**
- Press `Ctrl+C` in the terminal running the mining script

### Legacy Individual Commands (Still Supported)

### Starting monerod (Monero daemon)
```bash
# Start with default settings
monerod

# Start with custom data directory
monerod --data-dir ~/.monero
```

### Using p2pool
```bash
# Basic p2pool setup (requires monerod running)
p2pool --host 127.0.0.1 --wallet YOUR_WALLET_ADDRESS

# With stratum server for miners
p2pool --host 127.0.0.1 --wallet YOUR_WALLET_ADDRESS --stratum 0.0.0.0:3333
```

### Using xmrig (CPU miner)
```bash
# Mine to p2pool
xmrig -o 127.0.0.1:3333 -u YOUR_WALLET_ADDRESS

# Mine to a regular pool
xmrig -o pool.example.com:4444 -u YOUR_WALLET_ADDRESS -p x
```

### Legacy Mining Script
```bash
# The old startmining.sh still works (now redirects to xmr.sh mine)
./startmining.sh
```

## Configuration Files

The script creates configuration directories in your home folder:
- `~/.monero/` - Monero daemon configuration and blockchain data
- `~/.p2pool/` - P2Pool configuration and data
- `~/.xmrig/` - XMRig configuration files

## Troubleshooting

### Script fails with permission errors
If you get permission errors with the quick install, try the detailed installation method instead.

### Download failures
Check your internet connection and try again. If the quick install fails, you can use the detailed installation method. The script downloads from:
- Monero: GitHub releases (monero-project/monero)
- P2Pool: GitHub releases (SChernykh/p2pool)  
- XMRig: GitHub releases (xmrig/xmrig) or AUR

### Tool not found after installation
The tools are installed to `/usr/local/bin/`. Make sure this directory is in your PATH:
```bash
echo $PATH | grep -q "/usr/local/bin" || echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
```

### Separate terminals not working
If the separate terminal mode doesn't work:
1. **Install a supported terminal emulator**:
   ```bash
   # For GNOME desktop
   sudo pacman -S gnome-terminal
   
   # For KDE desktop  
   sudo pacman -S konsole
   
   # For XFCE desktop
   sudo pacman -S xfce4-terminal
   
   # Lightweight option
   sudo pacman -S xterm
   ```
2. **Use integrated mode as fallback**:
   ```bash
   ./xmr.sh mine --integrated --wallet YOUR_WALLET_ADDRESS
   ```
3. **Check if running in a desktop environment** - Separate terminals require a graphical environment

## Security Notes

- This script downloads and installs software from official sources
- Always verify checksums when possible for production use
- Review the script code before running it
- Run with a non-root user (the script will ask for sudo when needed)

## Contributing

Feel free to open issues or submit pull requests to improve this script.

## Testing

This repository includes a comprehensive test suite to ensure code quality and functionality:

### Running Tests

To run all tests:
```bash
./run_all_tests.sh
```

### Individual Test Suites

1. **Basic functionality tests**:
   ```bash
   ./test_xmrsetup.sh
   ```

2. **Comprehensive function tests**:
   ```bash
   ./test_comprehensive.sh
   ```

3. **Start mining script tests**:
   ```bash
   ./test_startmining.sh
   ```

### Test Coverage

The test suite covers:
- ✅ Function existence and basic functionality
- ✅ Logging system correctness
- ✅ Configuration directory creation
- ✅ Error handling and edge cases
- ✅ Script syntax validation
- ✅ Process management in mining script
- ✅ Signal handling and cleanup
- ✅ Input validation
- ✅ Code quality checks (shellcheck integration)

### Development Guidelines

- All scripts must pass syntax validation (`bash -n`)
- New functions should include corresponding tests
- Error handling should be comprehensive with proper cleanup
- Use `set -e` for fail-fast behavior
- Quote variables to prevent word splitting
- Include signal handlers for long-running processes

## License

This project is provided as-is for educational and personal use.