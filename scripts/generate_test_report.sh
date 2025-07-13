#!/bin/bash

# ARTbeat Test Report Generator
# This script generates a comprehensive test report for all packages

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
REPORT_DIR="test_reports"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
REPORT_FILE="$REPORT_DIR/test_report_$TIMESTAMP.md"

# Create report directory
mkdir -p "$REPORT_DIR"

echo -e "${BLUE}🧪 ARTbeat Test Report Generator${NC}"
echo "=================================="

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

# Initialize report
cat > "$REPORT_FILE" << EOF
# ARTbeat Test Report

**Generated:** $(date)
**Flutter Version:** $(flutter --version | head -n 1)
**Dart Version:** $(dart --version | head -n 1)

---

## Summary

| Package | Tests | Status | Coverage | Notes |
|---------|-------|--------|----------|-------|
EOF

# Track totals
total_packages=0
total_tests=0
passed_packages=0
failed_packages=0
packages_with_coverage=0

print_status "Generating test report..."

# Function to run tests and collect metrics
run_package_analysis() {
    local package_path=$1
    local package_name=$2
    
    print_status "Analyzing $package_name..."
    
    cd "$package_path"
    
    # Initialize variables
    local test_count=0
    local test_status="❌ No Tests"
    local coverage_percent="N/A"
    local notes=""
    
    # Check if test directory exists
    if [ -d "test" ]; then
        # Count test files
        test_files=$(find test -name '*.dart' -type f | wc -l)
        
        if [ "$test_files" -gt 0 ]; then
            print_status "Running tests for $package_name..."
            
            # Run tests and capture output
            if flutter test --coverage > "../test_output_${package_name}.log" 2>&1; then
                test_status="✅ Passed"
                passed_packages=$((passed_packages + 1))
                
                # Count actual tests from output
                test_count=$(grep -c "✓" "../test_output_${package_name}.log" 2>/dev/null || echo "0")
                
                # Extract coverage if available
                if [ -f "coverage/lcov.info" ]; then
                    if command -v lcov &> /dev/null; then
                        coverage_info=$(lcov --summary coverage/lcov.info 2>/dev/null | grep "lines......" | head -1)
                        if [ -n "$coverage_info" ]; then
                            coverage_percent=$(echo "$coverage_info" | grep -o '[0-9.]*%')
                            packages_with_coverage=$((packages_with_coverage + 1))
                        fi
                    fi
                fi
            else
                test_status="❌ Failed"
                failed_packages=$((failed_packages + 1))
                notes="Check test_output_${package_name}.log for details"
            fi
            
            total_tests=$((total_tests + test_count))
        else
            notes="Test directory exists but no test files found"
        fi
    else
        notes="No test directory found"
    fi
    
    # Add to report
    echo "| $package_name | $test_count | $test_status | $coverage_percent | $notes |" >> "$REPORT_FILE"
    
    cd - > /dev/null
    total_packages=$((total_packages + 1))
}

# Run main app analysis
print_status "Analyzing main application..."
main_test_count=0
main_status="❌ No Tests"
main_coverage="N/A"
main_notes=""

if [ -d "test" ]; then
    test_files=$(find test -name '*.dart' -type f | wc -l)
    
    if [ "$test_files" -gt 0 ]; then
        if flutter test --coverage > "test_output_main.log" 2>&1; then
            main_status="✅ Passed"
            main_test_count=$(grep -c "✓" "test_output_main.log" 2>/dev/null || echo "0")
            
            if [ -f "coverage/lcov.info" ]; then
                if command -v lcov &> /dev/null; then
                    coverage_info=$(lcov --summary coverage/lcov.info 2>/dev/null | grep "lines......" | head -1)
                    if [ -n "$coverage_info" ]; then
                        main_coverage=$(echo "$coverage_info" | grep -o '[0-9.]*%')
                    fi
                fi
            fi
        else
            main_status="❌ Failed"
            main_notes="Check test_output_main.log for details"
        fi
        
        total_tests=$((total_tests + main_test_count))
    fi
fi

echo "| Main App | $main_test_count | $main_status | $main_coverage | $main_notes |" >> "$REPORT_FILE"

# Analyze all packages
for package_dir in packages/*/; do
    if [ -d "$package_dir" ]; then
        package_name=$(basename "$package_dir")
        run_package_analysis "$package_dir" "$package_name"
    fi
done

# Add detailed sections to report
cat >> "$REPORT_FILE" << EOF

---

## Detailed Results

### Statistics
- **Total Packages:** $((total_packages + 1)) (including main app)
- **Total Tests:** $total_tests
- **Passed Packages:** $passed_packages
- **Failed Packages:** $failed_packages
- **Packages with Coverage:** $packages_with_coverage

### Test Coverage Analysis
EOF

# Add coverage details if lcov is available
if command -v lcov &> /dev/null; then
    cat >> "$REPORT_FILE" << EOF

#### Coverage by Package
EOF
    
    # Combine all coverage files if they exist
    coverage_files=()
    for package_dir in packages/*/; do
        if [ -f "${package_dir}coverage/lcov.info" ]; then
            coverage_files+=("${package_dir}coverage/lcov.info")
        fi
    done
    
    if [ -f "coverage/lcov.info" ]; then
        coverage_files+=("coverage/lcov.info")
    fi
    
    if [ ${#coverage_files[@]} -gt 0 ]; then
        print_status "Generating combined coverage report..."
        
        # Create combined coverage file
        lcov_args=""
        for file in "${coverage_files[@]}"; do
            lcov_args="$lcov_args -a $file"
        done
        
        if [ -n "$lcov_args" ]; then
            lcov $lcov_args -o "$REPORT_DIR/combined_coverage.info" > /dev/null 2>&1
            
            # Generate HTML report
            genhtml "$REPORT_DIR/combined_coverage.info" -o "$REPORT_DIR/html_coverage" > /dev/null 2>&1
            
            # Get overall coverage
            overall_coverage=$(lcov --summary "$REPORT_DIR/combined_coverage.info" 2>/dev/null | grep "lines......" | head -1 | grep -o '[0-9.]*%')
            
            cat >> "$REPORT_FILE" << EOF

- **Overall Coverage:** $overall_coverage
- **HTML Report:** [View Coverage Report](html_coverage/index.html)

EOF
        fi
    fi
else
    cat >> "$REPORT_FILE" << EOF

*Note: lcov not installed. Install lcov for detailed coverage analysis.*

EOF
fi

# Add recommendations
cat >> "$REPORT_FILE" << EOF

### Recommendations

EOF

if [ $failed_packages -gt 0 ]; then
    cat >> "$REPORT_FILE" << EOF
- **🔴 Critical:** Fix failing tests in $failed_packages package(s)
EOF
fi

if [ $total_packages -gt $packages_with_coverage ]; then
    missing_coverage=$((total_packages - packages_with_coverage))
    cat >> "$REPORT_FILE" << EOF
- **🟡 Coverage:** Add test coverage to $missing_coverage package(s)
EOF
fi

if [ $total_tests -lt 50 ]; then
    cat >> "$REPORT_FILE" << EOF
- **🟡 Tests:** Consider adding more tests (current: $total_tests)
EOF
fi

cat >> "$REPORT_FILE" << EOF
- **🟢 Maintenance:** Keep tests up to date with code changes
- **🟢 Documentation:** Document testing procedures and expectations

### Test Execution Logs

The following log files were generated during this analysis:
EOF

# List log files
for log_file in test_output_*.log; do
    if [ -f "$log_file" ]; then
        echo "- \`$log_file\`" >> "$REPORT_FILE"
    fi
done

cat >> "$REPORT_FILE" << EOF

### How to Run Tests

#### All Tests
\`\`\`bash
./scripts/run_all_tests.sh
\`\`\`

#### Specific Package
\`\`\`bash
cd packages/package_name
flutter test --coverage
\`\`\`

#### Main App Only
\`\`\`bash
flutter test --coverage
\`\`\`

---

*Report generated by ARTbeat Test Suite*
EOF

# Move log files to report directory
mv test_output_*.log "$REPORT_DIR/" 2>/dev/null || true

# Summary
echo ""
echo "=================================="
print_status "Test Report Summary"
echo "=================================="
print_status "Total packages analyzed: $((total_packages + 1))"
print_status "Total tests executed: $total_tests"

if [ $failed_packages -eq 0 ]; then
    print_success "All packages passed! ✅"
else
    print_error "$failed_packages package(s) failed ❌"
fi

print_status "Detailed report saved to: $REPORT_FILE"

if [ -f "$REPORT_DIR/html_coverage/index.html" ]; then
    print_status "Coverage report: $REPORT_DIR/html_coverage/index.html"
fi

# Exit with error if any tests failed
if [ $failed_packages -gt 0 ]; then
    exit 1
fi

print_success "Test report generation completed! 🎉"