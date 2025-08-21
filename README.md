# XMR Setup - Arch Linux

An automated setup script for Arch Linux that checks for and installs essential Monero (XMR) mining and node tools.

## What it does

This script automatically installs and configures:

- **monerod** - The official Monero daemon for running a full node
- **p2pool** - Decentralized mining pool for Monero
- **xmrig** - High-performance CPU miner for Monero

## Features

- ✅ Arch Linux compatibility check
- ✅ Automatic detection of already installed tools
- ✅ Downloads from official sources and releases
- ✅ System dependency management
- ✅ User-friendly colored output and progress indicators
- ✅ Creates configuration directories
- ✅ Installation summary and next steps

## Requirements

- Arch Linux (or Arch-based distribution)
- Internet connection
- sudo privileges

## Quick Install

Run this single command to install everything:

```bash
curl -fsSL https://raw.githubusercontent.com/takdm/xmrsetup/main/xmrsetup.sh | bash
```

Or if you prefer wget:

```bash
wget -qO- https://raw.githubusercontent.com/takdm/xmrsetup/main/xmrsetup.sh | bash
```

That's it! The script will automatically install monerod, p2pool, and xmrig for you.

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