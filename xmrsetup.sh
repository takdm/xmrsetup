#!/bin/bash

# XMR Setup Script for Arch Linux - Compatibility Wrapper
# This script now wraps the unified xmr.sh script for backward compatibility

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if we're being sourced (for tests)
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # We're being sourced, so source the unified script instead
    source "$SCRIPT_DIR/xmr.sh"
    return 0
fi

# We're being executed directly, so call the unified script
echo "This script has been consolidated into xmr.sh for better functionality."
echo "Redirecting to: xmr.sh install"
echo ""

exec "$SCRIPT_DIR/xmr.sh" install "$@"

