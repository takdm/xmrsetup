#!/bin/bash

# Simple test script for xmrsetup.sh
# Tests basic functionality without actually installing anything

set -e

# Source the main script to test functions
source ./xmrsetup.sh

echo "Testing xmrsetup.sh functions..."

# Test command_exists function
echo "Testing command_exists function:"
if command_exists bash; then
    echo "✅ command_exists works correctly (bash found)"
else
    echo "❌ command_exists failed to find bash"
    exit 1
fi

if ! command_exists nonexistentcommand123; then
    echo "✅ command_exists works correctly (nonexistent command not found)"
else
    echo "❌ command_exists incorrectly found nonexistent command"
    exit 1
fi

# Test logging functions
echo "Testing logging functions:"
log_info "This is an info message"
log_success "This is a success message"
log_warning "This is a warning message"
log_error "This is an error message (but not fatal in test)"

echo ""
echo "✅ All basic tests passed!"
echo "Note: Full functionality requires Arch Linux environment"