#!/bin/bash
# startmining.sh - Linux equivalent of start.bat for Monero mining

# Change to monero directory and start monerod
echo "Starting monerod..."
cd "$(dirname "$0")/monero" || exit 1
./monerod --zmq-pub tcp://127.0.0.1:18083 \
  --out-peers 32 --in-peers 64 \
  --add-priority-node=p2pmd.xmrvsbeast.com:18080 \
  --add-priority-node=nodes.hashvault.pro:18080 \
  --disable-dns-checkpoints --enable-dns-blocklist \
  --prune-blockchain --data-dir="$HOME/xmrblock" &
MONEROD_PID=$!

# Change to p2pool directory and start p2pool
echo "Starting p2pool..."
cd "../monero/p2pool" || exit 1
./p2pool --host 127.0.0.1 \
  --wallet 49KWETDKkDNP3v3NpdRPzaNACzx5srKGZPogcVBpgWReTBGcjA3nKywNQ5KTLjFNh6Ayqxcmpy2bqSnSFSxNgxsi78TwD1d &
P2POOL_PID=$!

# Change to xmrig directory and start xmrig
echo "Starting xmrig..."
cd "../../xmrig-6.24.0" || exit 1
./xmrig &
XMRIG_PID=$!

echo "Mining processes started."
echo "monerod PID: $MONEROD_PID"
echo "p2pool PID: $P2POOL_PID"
echo "xmrig PID: $XMRIG_PID"

# Wait for all processes
echo "Press [CTRL+C] to stop all mining processes."
wait
