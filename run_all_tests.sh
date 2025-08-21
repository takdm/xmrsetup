#!/bin/bash

# Master test runner for all XMR setup tests
# Runs all test suites and provides comprehensive coverage report

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}================================${NC}"
echo -e "${CYAN}    XMR Setup Test Suite${NC}"
echo -e "${CYAN}================================${NC}"
echo ""

# Test suite results
TOTAL_TEST_SUITES=0
PASSED_TEST_SUITES=0
FAILED_TEST_SUITES=0

run_test_suite() {
    local test_name="$1"
    local test_script="$2"
    
    TOTAL_TEST_SUITES=$((TOTAL_TEST_SUITES + 1))
    
    echo -e "${BLUE}Running ${test_name}...${NC}"
    echo "----------------------------------------"
    
    if ./"$test_script"; then
        echo -e "${GREEN}✅ ${test_name} PASSED${NC}"
        PASSED_TEST_SUITES=$((PASSED_TEST_SUITES + 1))
    else
        echo -e "${RED}❌ ${test_name} FAILED${NC}"
        FAILED_TEST_SUITES=$((FAILED_TEST_SUITES + 1))
    fi
    echo ""
}

# Check if all test scripts exist
echo "Verifying test scripts..."
test_scripts=("test_xmrsetup.sh" "test_comprehensive.sh" "test_startmining.sh")
missing_scripts=0

for script in "${test_scripts[@]}"; do
    if [[ -f "$script" ]]; then
        echo -e "  ${GREEN}✓${NC} $script found"
    else
        echo -e "  ${RED}✗${NC} $script missing"
        missing_scripts=$((missing_scripts + 1))
    fi
done

if [[ $missing_scripts -gt 0 ]]; then
    echo -e "${RED}Error: $missing_scripts test scripts are missing!${NC}"
    exit 1
fi

echo ""

# Run all test suites
run_test_suite "Basic Functionality Tests" "test_xmrsetup.sh"
run_test_suite "Comprehensive Function Tests" "test_comprehensive.sh"
run_test_suite "Start Mining Script Tests" "test_startmining.sh"

# Additional syntax checks
echo -e "${BLUE}Running additional syntax checks...${NC}"
echo "----------------------------------------"

syntax_errors=0

for script in xmrsetup.sh startmining.sh; do
    if bash -n "$script"; then
        echo -e "  ${GREEN}✓${NC} $script syntax OK"
    else
        echo -e "  ${RED}✗${NC} $script syntax ERROR"
        syntax_errors=$((syntax_errors + 1))
    fi
done

if [[ $syntax_errors -eq 0 ]]; then
    echo -e "${GREEN}✅ All syntax checks PASSED${NC}"
else
    echo -e "${RED}❌ $syntax_errors syntax errors found${NC}"
    FAILED_TEST_SUITES=$((FAILED_TEST_SUITES + 1))
    TOTAL_TEST_SUITES=$((TOTAL_TEST_SUITES + 1))
fi

echo ""

# Code quality checks
echo -e "${BLUE}Running code quality checks...${NC}"
echo "----------------------------------------"

quality_issues=0

# Check for shellcheck if available
if command -v shellcheck >/dev/null 2>&1; then
    echo "Running shellcheck analysis..."
    for script in xmrsetup.sh startmining.sh; do
        if shellcheck "$script" >/dev/null 2>&1; then
            echo -e "  ${GREEN}✓${NC} $script passes shellcheck"
        else
            echo -e "  ${YELLOW}⚠${NC} $script has shellcheck warnings"
            quality_issues=$((quality_issues + 1))
        fi
    done
else
    echo -e "  ${YELLOW}⚠${NC} shellcheck not available - skipping static analysis"
fi

# Check for proper permissions
echo "Checking file permissions..."
for script in xmrsetup.sh startmining.sh test_*.sh run_all_tests.sh; do
    if [[ -x "$script" ]]; then
        echo -e "  ${GREEN}✓${NC} $script is executable"
    else
        echo -e "  ${YELLOW}⚠${NC} $script is not executable (may be intentional)"
    fi
done

echo ""

# Final summary
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}          FINAL TEST SUMMARY${NC}"
echo -e "${CYAN}========================================${NC}"
echo -e "Total test suites: ${BLUE}$TOTAL_TEST_SUITES${NC}"
echo -e "Passed test suites: ${GREEN}$PASSED_TEST_SUITES${NC}"
echo -e "Failed test suites: ${RED}$FAILED_TEST_SUITES${NC}"

if [[ $quality_issues -gt 0 ]]; then
    echo -e "Code quality issues: ${YELLOW}$quality_issues${NC}"
fi

echo ""

if [[ $FAILED_TEST_SUITES -eq 0 ]]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED! 🎉${NC}"
    echo -e "${GREEN}The XMR setup scripts are ready for use.${NC}"
    exit 0
else
    echo -e "${RED}❌ $FAILED_TEST_SUITES TEST SUITE(S) FAILED${NC}"
    echo -e "${RED}Please review and fix the issues above.${NC}"
    exit 1
fi