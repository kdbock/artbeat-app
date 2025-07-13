#!/bin/bash

# ARTbeat - Comprehensive Test Runner
# This script runs all tests for the main app and all packages

set -e

echo "🎨 ARTbeat - Running All Tests"
echo "==============================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Flutter is available
check_flutter() {
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter is not installed or not in PATH"
        exit 1
    fi
    print_status "Flutter version: $(flutter --version | head -n 1)"
}

# Run linting
run_linting() {
    print_status "Running linting checks..."
    if flutter analyze --no-pub; then
        print_success "Linting passed"
        return 0
    else
        print_error "Linting failed"
        return 1
    fi
}

# Check formatting
check_formatting() {
    print_status "Checking code formatting..."
    if dart format --set-exit-if-changed .; then
        print_success "Code formatting is correct"
        return 0
    else
        print_error "Code formatting issues found. Run 'dart format .' to fix."
        return 1
    fi
}

# Track test results
FAILED_TESTS=()
PASSED_TESTS=()

# Function to run tests for a package
run_package_tests() {
    local package_path=$1
    local package_name=$2
    
    print_status "Testing $package_name..."
    
    cd "$package_path"
    
    # Check if test directory exists
    if [ ! -d "test" ]; then
        print_warning "No test directory found for $package_name"
        return 0
    fi
    
    # Check if there are test files
    if [ -z "$(find test -name '*.dart' -type f)" ]; then
        print_warning "No test files found for $package_name"
        return 0
    fi
    
    # Run flutter test
    if flutter test --coverage; then
        print_status "✅ $package_name tests passed"
        PASSED_TESTS+=("$package_name")
    else
        print_error "❌ $package_name tests failed"
        FAILED_TESTS+=("$package_name")
    fi
    
    cd - > /dev/null
}

# Get the root directory
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

print_status "Running tests from directory: $ROOT_DIR"

# Run main app tests
print_status "Testing main application..."
if flutter test --coverage; then
    print_status "✅ Main app tests passed"
    PASSED_TESTS+=("main_app")
else
    print_error "❌ Main app tests failed"
    FAILED_TESTS+=("main_app")
fi

# Run tests for each package
print_status "Testing packages..."

for package_dir in packages/*/; do
    if [ -d "$package_dir" ]; then
        package_name=$(basename "$package_dir")
        run_package_tests "$package_dir" "$package_name"
    fi
done

# Summary
echo
echo "🎯 Test Results Summary"
echo "======================="

if [ ${#PASSED_TESTS[@]} -gt 0 ]; then
    echo -e "${GREEN}✅ Passed (${#PASSED_TESTS[@]}):${NC}"
    for test in "${PASSED_TESTS[@]}"; do
        echo "  - $test"
    done
fi

if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
    echo -e "${RED}❌ Failed (${#FAILED_TESTS[@]}):${NC}"
    for test in "${FAILED_TESTS[@]}"; do
        echo "  - $test"
    done
    echo
    print_error "Some tests failed. Please fix the issues before committing."
    exit 1
else
    echo
    print_status "🎉 All tests passed! Your code is ready for commit."
fi