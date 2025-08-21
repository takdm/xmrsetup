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

echo "Starting Monero mining setup..."
echo "==============================="

# Start monerod using system-installed binary
echo "Starting monerod..."
if ! command -v monerod >/dev/null 2>&1; then
    echo "Error: monerod not found in PATH. Please install using xmrsetup.sh first."
    exit 1
fi
monerod --zmq-pub tcp://127.0.0.1:18083 \
  --out-peers 32 --in-peers 64 \
  --add-priority-node=p2pmd.xmrvsbeast.com:18080 \
  --add-priority-node=nodes.hashvault.pro:18080 \
  --disable-dns-checkpoints --enable-dns-blocklist \
  --prune-blockchain --data-dir="$HOME/xmrblock" &
MONEROD_PID=$!

# Start p2pool using system-installed binary
echo "Starting p2pool..."
if ! command -v p2pool >/dev/null 2>&1; then
    echo "Error: p2pool not found in PATH. Please install using xmrsetup.sh first."
    cleanup
    exit 1
fi
p2pool --host 127.0.0.1 \
  --wallet 49KWETDKkDNP3v3NpdRPzaNACzx5srKGZPogcVBpgWReTBGcjA3nKywNQ5KTLjFNh6Ayqxcmpy2bqSnSFSxNgxsi78TwD1d &
P2POOL_PID=$!

# Start xmrig using system-installed binary
echo "Starting xmrig..."
if ! command -v xmrig >/dev/null 2>&1; then
    echo "Error: xmrig not found in PATH. Please install using xmrsetup.sh first."
    cleanup
    exit 1
fi
xmrig &
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
