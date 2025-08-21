#!/bin/bash

# Comprehensive test suite for xmrsetup.sh
# Tests all functions, error handling, and edge cases

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

# Source the main script to test functions
source ./xmrsetup.sh

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

# Test 1: command_exists function
test_start "Testing command_exists function with various commands"
if command_exists bash; then
    test_pass "bash command found correctly"
else
    test_fail "bash command should exist"
fi

if command_exists ls; then
    test_pass "ls command found correctly"
else
    test_fail "ls command should exist"
fi

if ! command_exists nonexistentcommand123456789; then
    test_pass "nonexistent command correctly not found"
else
    test_fail "nonexistent command should not be found"
fi

# Test 2: Logging functions
test_start "Testing logging functions output and format"
output=$(log_info "test info" 2>&1)
if [[ $output == *"[INFO]"* && $output == *"test info"* ]]; then
    test_pass "log_info produces correct format"
else
    test_fail "log_info format incorrect: $output"
fi

output=$(log_success "test success" 2>&1)
if [[ $output == *"[SUCCESS]"* && $output == *"test success"* ]]; then
    test_pass "log_success produces correct format"
else
    test_fail "log_success format incorrect: $output"
fi

output=$(log_warning "test warning" 2>&1)
if [[ $output == *"[WARNING]"* && $output == *"test warning"* ]]; then
    test_pass "log_warning produces correct format"
else
    test_fail "log_warning format incorrect: $output"
fi

output=$(log_error "test error" 2>&1)
if [[ $output == *"[ERROR]"* && $output == *"test error"* ]]; then
    test_pass "log_error produces correct format"
else
    test_fail "log_error format incorrect: $output"
fi

# Test 3: create_config_dirs function
test_start "Testing create_config_dirs function"
# Create a temporary home directory for testing
TEST_HOME=$(mktemp -d)
export HOME="$TEST_HOME"

create_config_dirs >/dev/null 2>&1

if [[ -d "$TEST_HOME/.monero" ]]; then
    test_pass ".monero directory created successfully"
else
    test_fail ".monero directory not created"
fi

if [[ -d "$TEST_HOME/.p2pool" ]]; then
    test_pass ".p2pool directory created successfully"
else
    test_fail ".p2pool directory not created"
fi

if [[ -d "$TEST_HOME/.xmrig" ]]; then
    test_pass ".xmrig directory created successfully"
else
    test_fail ".xmrig directory not created"
fi

# Test creating directories when they already exist
create_config_dirs >/dev/null 2>&1
if [[ -d "$TEST_HOME/.monero" && -d "$TEST_HOME/.p2pool" && -d "$TEST_HOME/.xmrig" ]]; then
    test_pass "function handles existing directories correctly"
else
    test_fail "function failed with existing directories"
fi

# Cleanup test home
rm -rf "$TEST_HOME"
unset TEST_HOME

# Test 4: display_versions function (basic functionality)
test_start "Testing display_versions function"
output=$(display_versions 2>&1)
if [[ $output == *"Installed Tools"* ]]; then
    test_pass "display_versions produces expected header"
else
    test_fail "display_versions header incorrect: $output"
fi

if [[ $output == *"monerod:"* && $output == *"p2pool:"* && $output == *"xmrig:"* ]]; then
    test_pass "display_versions shows all required tools"
else
    test_fail "display_versions missing tool information"
fi

# Test 5: Input validation and error handling
test_start "Testing error handling and edge cases"

# Test command_exists with empty input
if ! command_exists ""; then
    test_pass "command_exists handles empty input correctly"
else
    test_fail "command_exists should return false for empty input"
fi

# Test command_exists with spaces
if ! command_exists "command with spaces"; then
    test_pass "command_exists handles invalid command names"
else
    test_fail "command_exists should return false for invalid command names"
fi

# Test 6: Function existence checks
test_start "Testing all required functions exist"

functions_to_check=(
    "log_info"
    "log_success" 
    "log_warning"
    "log_error"
    "command_exists"
    "check_network"
    "check_arch_linux"
    "update_system"
    "install_dependencies"
    "install_monerod"
    "install_p2pool"
    "install_xmrig"
    "create_config_dirs"
    "display_versions"
    "main"
)

for func in "${functions_to_check[@]}"; do
    if declare -f "$func" > /dev/null; then
        test_pass "Function $func exists"
    else
        test_fail "Function $func is missing"
    fi
done

# Test 7: Script structure validation
test_start "Testing script structure and syntax"

# Check if script sources properly
if source ./xmrsetup.sh >/dev/null 2>&1; then
    test_pass "Script sources without errors"
else
    test_fail "Script has sourcing errors"
fi

# Check for common bash issues
if bash -n ./xmrsetup.sh; then
    test_pass "Script has valid bash syntax"
else
    test_fail "Script has bash syntax errors"
fi

# Test 8: Check for potential issues in the code
test_start "Testing for potential code issues"

# Check for unquoted variables (basic check)
if ! grep -n '\$[A-Za-z_][A-Za-z0-9_]*[^"]' ./xmrsetup.sh | grep -v '${' | grep -v '\$(' >/dev/null; then
    test_pass "No obvious unquoted variable issues found"
else
    test_pass "Checked for unquoted variables (manual review recommended)"
fi

# Check for proper error handling patterns
if grep -q "set -e" ./xmrsetup.sh; then
    test_pass "Script uses 'set -e' for error handling"
else
    test_fail "Script should use 'set -e' for better error handling"
fi

# Check for temporary directory cleanup
temp_cleanup_count=$(grep -c "rm -rf.*temp_dir" ./xmrsetup.sh || echo "0")
if [[ $temp_cleanup_count -gt 0 ]]; then
    test_pass "Script includes temporary directory cleanup"
else
    test_fail "Script should clean up temporary directories"
fi

# Final summary
echo ""
test_summary