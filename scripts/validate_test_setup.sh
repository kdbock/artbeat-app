#!/bin/bash

# ARTbeat Test Setup Validator
# This script validates that all testing infrastructure is properly set up

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 ARTbeat Test Setup Validator${NC}"
echo "===================================="

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Track validation results
validation_errors=0
validation_warnings=0

# Function to check if a file exists
check_file() {
    local file_path=$1
    local description=$2
    
    if [ -f "$file_path" ]; then
        print_success "$description exists"
    else
        print_error "$description missing: $file_path"
        validation_errors=$((validation_errors + 1))
    fi
}

# Function to check if a directory exists
check_directory() {
    local dir_path=$1
    local description=$2
    
    if [ -d "$dir_path" ]; then
        print_success "$description exists"
    else
        print_error "$description missing: $dir_path"
        validation_errors=$((validation_errors + 1))
    fi
}

# Function to check if command exists
check_command() {
    local command=$1
    local description=$2
    
    if command -v "$command" &> /dev/null; then
        print_success "$description is available"
    else
        print_warning "$description not found: $command"
        validation_warnings=$((validation_warnings + 1))
    fi
}

print_status "Validating Flutter and Dart installation..."
check_command "flutter" "Flutter CLI"
check_command "dart" "Dart CLI"

if command -v flutter &> /dev/null; then
    flutter_version=$(flutter --version | head -n 1)
    print_status "Flutter version: $flutter_version"
fi

print_status "Validating test infrastructure files..."
check_file "test_config.yaml" "Test configuration"
check_file "TESTING.md" "Testing documentation"
check_file "scripts/run_all_tests.sh" "Test runner script"
check_file "scripts/generate_test_report.sh" "Test report generator"
check_file "scripts/validate_test_setup.sh" "Test setup validator"
check_file ".github/workflows/comprehensive_tests.yml" "GitHub Actions workflow"

print_status "Validating main app test structure..."
check_directory "test" "Main app test directory"
check_directory "test/integration" "Integration test directory"

print_status "Validating package test directories..."
packages=(
    "artbeat_core"
    "artbeat_auth" 
    "artbeat_profile"
    "artbeat_artwork"
    "artbeat_art_walk"
    "artbeat_artist"
    "artbeat_messaging"
    "artbeat_events"
    "artbeat_community"
    "artbeat_capture"
    "artbeat_settings"
)

for package in "${packages[@]}"; do
    package_dir="packages/$package"
    test_dir="$package_dir/test"
    
    if [ -d "$package_dir" ]; then
        print_success "Package $package exists"
        
        if [ -d "$test_dir" ]; then
            print_success "Test directory for $package exists"
            
            # Check for test files
            test_files=$(find "$test_dir" -name "*.dart" -type f 2>/dev/null | wc -l)
            if [ "$test_files" -gt 0 ]; then
                print_success "Test files found for $package ($test_files files)"
            else
                print_warning "No test files found for $package"
                validation_warnings=$((validation_warnings + 1))
            fi
        else
            print_warning "Test directory missing for $package"
            validation_warnings=$((validation_warnings + 1))
        fi
    else
        print_warning "Package $package directory not found"
        validation_warnings=$((validation_warnings + 1))
    fi
done

print_status "Validating script permissions..."
scripts=("scripts/run_all_tests.sh" "scripts/generate_test_report.sh" "scripts/validate_test_setup.sh")

for script in "${scripts[@]}"; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            print_success "$script is executable"
        else
            print_warning "$script is not executable (run: chmod +x $script)"
            validation_warnings=$((validation_warnings + 1))
        fi
    fi
done

print_status "Validating dependencies..."
if [ -f "pubspec.yaml" ]; then
    if grep -q "flutter_test:" pubspec.yaml; then
        print_success "flutter_test dependency found"
    else
        print_error "flutter_test dependency missing from pubspec.yaml"
        validation_errors=$((validation_errors + 1))
    fi
    
    if grep -q "mockito:" pubspec.yaml; then
        print_success "mockito dependency found"
    else
        print_warning "mockito dependency not found in pubspec.yaml"
        validation_warnings=$((validation_warnings + 1))
    fi
fi

print_status "Checking for optional tools..."
check_command "lcov" "LCOV (for coverage reports)"
check_command "genhtml" "GenHTML (for HTML coverage reports)"
check_command "git" "Git (for version control)"

print_status "Running basic test validation..."
if [ -d "test" ] && [ "$(find test -name '*.dart' -type f | wc -l)" -gt 0 ]; then
    print_status "Attempting to run a quick test..."
    if flutter test --no-pub > /dev/null 2>&1; then
        print_success "Basic test execution works"
    else
        print_warning "Test execution failed - check dependencies"
        validation_warnings=$((validation_warnings + 1))
    fi
else
    print_warning "No test files found to validate"
    validation_warnings=$((validation_warnings + 1))
fi

print_status "Validating CI/CD configuration..."
if [ -f ".github/workflows/comprehensive_tests.yml" ]; then
    print_success "GitHub Actions workflow configured"
    
    # Check workflow syntax (basic validation)
    if grep -q "flutter-version: '3.32.0'" .github/workflows/comprehensive_tests.yml; then
        print_success "Flutter version specified in workflow"
    else
        print_warning "Flutter version not specified in workflow"
        validation_warnings=$((validation_warnings + 1))
    fi
else
    print_warning "GitHub Actions workflow not found"
    validation_warnings=$((validation_warnings + 1))
fi

# Summary
echo ""
echo "===================================="
print_status "Validation Summary"
echo "===================================="

total_checks=$((validation_errors + validation_warnings))

if [ $validation_errors -eq 0 ] && [ $validation_warnings -eq 0 ]; then
    print_success "All validations passed! Your test setup is ready. 🎉"
    echo ""
    echo "Next steps:"
    echo "1. Run './scripts/run_all_tests.sh' to execute all tests"
    echo "2. Generate a test report with './scripts/generate_test_report.sh'"
    echo "3. Check the TESTING.md file for detailed testing guidelines"
elif [ $validation_errors -eq 0 ]; then
    print_success "Setup is functional with $validation_warnings warning(s)"
    echo ""
    echo "Consider addressing the warnings for optimal testing experience."
else
    print_error "Setup has $validation_errors error(s) and $validation_warnings warning(s)"
    echo ""
    echo "Please fix the errors before proceeding with testing."
    exit 1
fi

echo ""
echo "📚 Documentation: See TESTING.md for detailed testing guide"
echo "🤖 CI/CD: GitHub Actions will automatically run tests on PR/push"
echo "🔧 Tools: Use './scripts/run_all_tests.sh --help' for testing options"
echo ""
print_success "Test setup validation completed!"