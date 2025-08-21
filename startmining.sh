#!/bin/bash
# startmining.sh - Compatibility Wrapper for Mining
# This script now wraps the unified xmr.sh script for backward compatibility

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "This script has been consolidated into xmr.sh for better functionality."
echo "Redirecting to: xmr.sh mine"
echo ""

exec "$SCRIPT_DIR/xmr.sh" mine "$@"
