#!/bin/bash

# ARTbeat Ads Package Test Runner
# This script runs all tests for the artbeat_ads package with various options

set -e  # Exit on any error

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

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -a, --all           Run all tests (default)"
    echo "  -m, --models        Run model tests only"
    echo "  -s, --services      Run service tests only"
    echo "  -w, --widgets       Run widget tests only"
    echo "  -c, --coverage      Run tests with coverage report"
    echo "  -v, --verbose       Run tests with verbose output"
    echo "  -f, --file FILE     Run specific test file"
    echo "  --clean             Clean before running tests"
    echo "  --generate-mocks    Generate mocks before running tests"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Run all tests"
    echo "  $0 --models                          # Run model tests only"
    echo "  $0 --coverage                        # Run with coverage"
    echo "  $0 --file ad_model_test.dart         # Run specific test file"
    echo "  $0 --clean --generate-mocks --all    # Full clean run with mock generation"
}

# Default values
RUN_ALL=true
RUN_MODELS=false
RUN_SERVICES=false
RUN_WIDGETS=false
COVERAGE=false
VERBOSE=false
CLEAN=false
GENERATE_MOCKS=false
SPECIFIC_FILE=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -a|--all)
            RUN_ALL=true
            RUN_MODELS=false
            RUN_SERVICES=false
            RUN_WIDGETS=false
            shift
            ;;
        -m|--models)
            RUN_ALL=false
            RUN_MODELS=true
            shift
            ;;
        -s|--services)
            RUN_ALL=false
            RUN_SERVICES=true
            shift
            ;;
        -w|--widgets)
            RUN_ALL=false
            RUN_WIDGETS=true
            shift
            ;;
        -c|--coverage)
            COVERAGE=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -f|--file)
            SPECIFIC_FILE="$2"
            RUN_ALL=false
            shift 2
            ;;
        --clean)
            CLEAN=true
            shift
            ;;
        --generate-mocks)
            GENERATE_MOCKS=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PACKAGE_DIR="$(dirname "$SCRIPT_DIR")"

print_status "ARTbeat Ads Package Test Runner"
print_status "Package directory: $PACKAGE_DIR"

# Change to package directory
cd "$PACKAGE_DIR"

# Clean if requested
if [ "$CLEAN" = true ]; then
    print_status "Cleaning package..."
    flutter clean
    rm -rf .dart_tool/
    rm -rf build/
    print_success "Package cleaned"
fi

# Get dependencies
print_status "Getting dependencies..."
flutter pub get
if [ $? -ne 0 ]; then
    print_error "Failed to get dependencies"
    exit 1
fi
print_success "Dependencies updated"

# Generate mocks if requested
if [ "$GENERATE_MOCKS" = true ]; then
    print_status "Generating mocks..."
    dart run build_runner build --delete-conflicting-outputs
    if [ $? -ne 0 ]; then
        print_warning "Mock generation failed, continuing with existing mocks..."
    else
        print_success "Mocks generated successfully"
    fi
fi

# Prepare test command
TEST_CMD="flutter test"

if [ "$VERBOSE" = true ]; then
    TEST_CMD="$TEST_CMD --verbose-skips"
fi

if [ "$COVERAGE" = true ]; then
    TEST_CMD="$TEST_CMD --coverage"
fi

# Run tests based on options
if [ -n "$SPECIFIC_FILE" ]; then
    print_status "Running specific test file: $SPECIFIC_FILE"
    if [ -f "test/$SPECIFIC_FILE" ]; then
        $TEST_CMD "test/$SPECIFIC_FILE"
    elif [ -f "test/models/$SPECIFIC_FILE" ]; then
        $TEST_CMD "test/models/$SPECIFIC_FILE"
    elif [ -f "test/services/$SPECIFIC_FILE" ]; then
        $TEST_CMD "test/services/$SPECIFIC_FILE"
    elif [ -f "test/widgets/$SPECIFIC_FILE" ]; then
        $TEST_CMD "test/widgets/$SPECIFIC_FILE"
    else
        print_error "Test file not found: $SPECIFIC_FILE"
        exit 1
    fi
elif [ "$RUN_ALL" = true ]; then
    print_status "Running all tests..."
    $TEST_CMD test/all_tests.dart
elif [ "$RUN_MODELS" = true ]; then
    print_status "Running model tests..."
    $TEST_CMD test/models/
elif [ "$RUN_SERVICES" = true ]; then
    print_status "Running service tests..."
    $TEST_CMD test/services/
elif [ "$RUN_WIDGETS" = true ]; then
    print_status "Running widget tests..."
    $TEST_CMD test/widgets/
fi

# Check test result
if [ $? -eq 0 ]; then
    print_success "All tests passed!"
else
    print_error "Some tests failed!"
    exit 1
fi

# Generate coverage report if requested
if [ "$COVERAGE" = true ]; then
    print_status "Generating coverage report..."
    
    # Check if genhtml is available
    if command -v genhtml &> /dev/null; then
        genhtml coverage/lcov.info -o coverage/html
        print_success "Coverage report generated in coverage/html/"
        print_status "Open coverage/html/index.html in your browser to view the report"
    else
        print_warning "genhtml not found. Install lcov to generate HTML coverage reports:"
        print_warning "  macOS: brew install lcov"
        print_warning "  Ubuntu: sudo apt-get install lcov"
        print_status "Coverage data available in coverage/lcov.info"
    fi
fi

print_success "Test run completed successfully!"

# Show test statistics
if [ -f "coverage/lcov.info" ]; then
    print_status "Test Coverage Summary:"
    lcov --summary coverage/lcov.info 2>/dev/null || print_warning "lcov not available for coverage summary"
fi