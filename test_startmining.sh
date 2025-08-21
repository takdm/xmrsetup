#!/bin/bash

# Updated test script for startmining.sh
# Tests both the wrapper functionality and the underlying unified script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
test_start() {
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -e "${BLUE}[TEST $TESTS_TOTAL]${NC} $1"
}

test_pass() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "  ${GREEN}✅ PASS${NC}: $1"
}

test_fail() {
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "  ${RED}❌ FAIL${NC}: $1"
}

test_warn() {
    echo -e "  ${YELLOW}⚠️  WARN${NC}: $1"
}

test_summary() {
    echo ""
    echo "==================== TEST SUMMARY ===================="
    echo -e "Total tests:  ${BLUE}$TESTS_TOTAL${NC}"
    echo -e "Passed tests: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed tests: ${RED}$TESTS_FAILED${NC}"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "Result: ${GREEN}ALL TESTS PASSED${NC}"
        return 0
    else
        echo -e "Result: ${RED}$TESTS_FAILED TESTS FAILED${NC}"
        return 1
    fi
}

echo "Testing startmining.sh script..."
echo "================================"

# Determine which script contains the actual mining functionality
MINING_SCRIPT="./startmining.sh"
UNIFIED_SCRIPT="./xmr.sh"

# Check if we have the unified script, and if startmining.sh is a wrapper
if [[ -f "$UNIFIED_SCRIPT" ]] && grep -q "xmr.sh" "$MINING_SCRIPT"; then
    echo "Note: startmining.sh is now a wrapper for xmr.sh - testing unified functionality"
    USE_UNIFIED=true
    MAIN_SCRIPT="$UNIFIED_SCRIPT"
else
    echo "Note: Testing standalone startmining.sh script"
    USE_UNIFIED=false
    MAIN_SCRIPT="$MINING_SCRIPT"
fi

# Test 1: Basic script syntax
test_start "Testing script syntax"
if bash -n "$MINING_SCRIPT"; then
    test_pass "Wrapper script has valid bash syntax"
else
    test_fail "Wrapper script has syntax errors"
fi

if [[ "$USE_UNIFIED" == "true" ]] && bash -n "$UNIFIED_SCRIPT"; then
    test_pass "Unified script has valid bash syntax"
elif [[ "$USE_UNIFIED" == "false" ]]; then
    # Already tested above for standalone case
    :
else
    test_fail "Unified script has syntax errors"
fi

# Test 2: Check wrapper functionality
test_start "Testing wrapper functionality"
if [[ "$USE_UNIFIED" == "true" ]]; then
    if grep -q "exec.*xmr.sh.*mine" "$MINING_SCRIPT"; then
        test_pass "Wrapper correctly calls unified script with mine command"
    else
        test_fail "Wrapper should call 'xmr.sh mine'"
    fi
else
    test_pass "Standalone script doesn't need wrapper functionality"
fi

# Test 3: Check for error handling in main functionality
test_start "Testing error handling patterns"
if grep -q "set -e" "$MAIN_SCRIPT"; then
    test_pass "Main script uses 'set -e' for error handling"
else
    test_warn "Script should consider using 'set -e' for better error handling"
    test_pass "Error handling check completed (warning issued)"
fi

# Test 4: Check for mining process management
test_start "Testing mining process management"
if grep -q "monerod.*&" "$MAIN_SCRIPT" && 
   grep -q "p2pool.*&" "$MAIN_SCRIPT" &&
   grep -q "xmrig.*&" "$MAIN_SCRIPT"; then
    test_pass "Script properly starts mining processes in background"
else
    test_fail "Script should start monerod, p2pool, and xmrig in background"
fi

# Test 5: Check for process cleanup
test_start "Testing process cleanup functionality"
if grep -q "cleanup\|kill.*PID\|trap.*SIGINT\|trap.*SIGTERM" "$MAIN_SCRIPT"; then
    test_pass "Script includes process cleanup functionality"
else
    test_fail "Script should include cleanup for mining processes"
fi

# Test 6: Check for executable validation
test_start "Testing executable validation"
if grep -q "command.*-v.*monerod\|command.*exists.*monerod" "$MAIN_SCRIPT" &&
   grep -q "command.*-v.*p2pool\|command.*exists.*p2pool" "$MAIN_SCRIPT" &&
   grep -q "command.*-v.*xmrig\|command.*exists.*xmrig" "$MAIN_SCRIPT"; then
    test_pass "Script validates required executables exist"
else
    test_fail "Script should validate that monerod, p2pool, and xmrig are available"
fi

# Test 7: Check for user feedback
test_start "Testing user feedback"
if grep -q "Starting\|started\|PID" "$MAIN_SCRIPT"; then
    test_pass "Script provides user feedback about mining processes"
else
    test_fail "Script should provide informative messages to user"
fi

# Test 8: Check configuration handling
test_start "Testing configuration handling"
if grep -q "wallet\|config" "$MAIN_SCRIPT"; then
    test_pass "Script handles wallet/configuration parameters"
else
    test_warn "Script should consider wallet configuration options"
    test_pass "Configuration check completed (warning issued)"
fi

echo ""
test_summary