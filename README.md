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

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/takdm/xmrsetup.git
   cd xmrsetup
   ```

2. Run the setup script:
   ```bash
   ./xmrsetup.sh
   ```

The script will:
- Verify you're running Arch Linux
- Ask if you want to update system packages
- Install necessary dependencies
- Download and install each tool from official sources
- Create configuration directories in your home folder

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
Make sure you have sudo privileges and the script is executable:
```bash
chmod +x xmrsetup.sh
```

### Download failures
Check your internet connection and try running the script again. The script downloads from:
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

## License

This project is provided as-is for educational and personal use.