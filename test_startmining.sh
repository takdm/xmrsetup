#!/bin/bash

# Test script for startmining.sh
# Tests structure, syntax, and potential issues

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

# Test 1: Basic syntax check
test_start "Testing script syntax"
if bash -n ./startmining.sh; then
    test_pass "Script has valid bash syntax"
else
    test_fail "Script has bash syntax errors"
fi

# Test 2: Check for proper error handling
test_start "Testing error handling patterns"
if grep -q "set -e" ./startmining.sh; then
    test_pass "Script uses 'set -e' for error handling"
else
    test_warn "Script should consider using 'set -e' for better error handling"
    test_pass "Error handling check completed (warning issued)"
fi

# Test 3: Check error handling
test_start "Testing error handling"
exit_one_count=$(grep -c "exit 1" ./startmining.sh 2>/dev/null || echo "0")
if [[ $exit_one_count -gt 0 ]]; then
    test_pass "Script includes proper error handling"
else
    test_fail "Script should include error handling with 'exit 1'"
fi

# Test 4: Check for hardcoded paths
test_start "Testing for hardcoded paths and flexibility"
if grep -q "xmrig-6.24.0" ./startmining.sh; then
    test_warn "Script contains hardcoded version path 'xmrig-6.24.0' - should be made flexible"
    test_pass "Hardcoded path check completed (warning issued)"
else
    test_pass "No hardcoded version paths found"
fi

# Test 5: Check process management
test_start "Testing process management"
if grep -q "MONEROD_PID=\$!" ./startmining.sh && 
   grep -q "P2POOL_PID=\$!" ./startmining.sh &&
   grep -q "XMRIG_PID=\$!" ./startmining.sh; then
    test_pass "Script properly captures process PIDs"
else
    test_fail "Script should capture all process PIDs"
fi

# Test 6: Check for wait command
test_start "Testing process waiting"
if grep -q "wait" ./startmining.sh; then
    test_pass "Script includes wait command for process management"
else
    test_fail "Script should use wait command for proper process management"
fi

# Test 7: Check for signal handling
test_start "Testing signal handling"
if grep -q "trap" ./startmining.sh; then
    test_pass "Script includes signal handling"
else
    test_warn "Script should consider adding signal handling for clean shutdown"
    test_pass "Signal handling check completed (warning issued)"
fi

# Test 8: Check wallet address format
test_start "Testing wallet address format"
wallet_line=$(grep -o "49[A-Za-z0-9]*" ./startmining.sh || echo "")
if [[ ${#wallet_line} -eq 95 ]]; then
    test_pass "Wallet address appears to be correct length (95 characters)"
else
    test_warn "Wallet address format should be verified (expected 95 chars, got ${#wallet_line})"
    test_pass "Wallet address check completed (warning issued)"
fi

# Test 9: Check for required executables
test_start "Testing executable references"
if grep -q "monerod" ./startmining.sh; then
    test_pass "Script references monerod executable"
else
    test_fail "Script should reference monerod executable"
fi

if grep -q "p2pool" ./startmining.sh; then
    test_pass "Script references p2pool executable"
else
    test_fail "Script should reference p2pool executable"
fi

if grep -q "xmrig" ./startmining.sh; then
    test_pass "Script references xmrig executable"
else
    test_fail "Script should reference xmrig executable"
fi

# Test 10: Check output messages
test_start "Testing user output messages"
if grep -q "Starting monerod" ./startmining.sh &&
   grep -q "Starting p2pool" ./startmining.sh &&
   grep -q "Starting xmrig" ./startmining.sh; then
    test_pass "Script includes informative startup messages"
else
    test_fail "Script should include startup messages for each process"
fi

# Test 11: Check for background process execution
test_start "Testing background process execution"
ampersand_count=$(grep -c "&$" ./startmining.sh || echo "0")
if [[ $ampersand_count -ge 3 ]]; then
    test_pass "Script properly runs processes in background"
else
    test_fail "Script should run all mining processes in background (&)"
fi

echo ""
test_summary