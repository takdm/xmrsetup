#!/bin/bash
# startmining.sh - Linux equivalent of start.bat for Monero mining

set -e

# Signal handler for clean shutdown
cleanup() {
    echo ""
    echo "Shutting down mining processes..."
    if [[ -n "$MONEROD_PID" ]]; then
        kill "$MONEROD_PID" 2>/dev/null || true
    fi
    if [[ -n "$P2POOL_PID" ]]; then
        kill "$P2POOL_PID" 2>/dev/null || true
    fi
    if [[ -n "$XMRIG_PID" ]]; then
        kill "$XMRIG_PID" 2>/dev/null || true
    fi
    echo "All processes stopped."
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Find xmrig directory dynamically
find_xmrig_dir() {
    # Look for xmrig directory with version pattern
    local xmrig_dir=$(find "$(dirname "$0")" -name "xmrig-*" -type d | head -n1)
    if [[ -d "$xmrig_dir" ]]; then
        echo "$xmrig_dir"
        return 0
    fi
    
    # Fallback to specific version if found
    if [[ -d "$(dirname "$0")/xmrig-6.24.0" ]]; then
        echo "$(dirname "$0")/xmrig-6.24.0"
        return 0
    fi
    
    # Try generic xmrig directory
    if [[ -d "$(dirname "$0")/xmrig" ]]; then
        echo "$(dirname "$0")/xmrig"
        return 0
    fi
    
    echo ""
    return 1
}

echo "Starting Monero mining setup..."
echo "==============================="

# Change to monero directory and start monerod
echo "Starting monerod..."
cd "$(dirname "$0")/monero" || { echo "Error: monero directory not found"; exit 1; }
./monerod --zmq-pub tcp://127.0.0.1:18083 \
  --out-peers 32 --in-peers 64 \
  --add-priority-node=p2pmd.xmrvsbeast.com:18080 \
  --add-priority-node=nodes.hashvault.pro:18080 \
  --disable-dns-checkpoints --enable-dns-blocklist \
  --prune-blockchain --data-dir="$HOME/xmrblock" &
MONEROD_PID=$!

# Change to p2pool directory and start p2pool
echo "Starting p2pool..."
cd "../monero/p2pool" || { echo "Error: p2pool directory not found"; exit 1; }
./p2pool --host 127.0.0.1 \
  --wallet 49KWETDKkDNP3v3NpdRPzaNACzx5srKGZPogcVBpgWReTBGcjA3nKywNQ5KTLjFNh6Ayqxcmpy2bqSnSFSxNgxsi78TwD1d &
P2POOL_PID=$!

# Find and change to xmrig directory and start xmrig
echo "Starting xmrig..."
XMRIG_DIR=$(find_xmrig_dir)
if [[ -z "$XMRIG_DIR" ]]; then
    echo "Error: xmrig directory not found"
    cleanup
    exit 1
fi

cd "$XMRIG_DIR" || { echo "Error: cannot access xmrig directory"; exit 1; }
./xmrig &
XMRIG_PID=$!

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
