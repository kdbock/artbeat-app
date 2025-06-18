#!/bin/bash

# Test Runner for ARTbeat modules
# This script runs tests across all ARTbeat modules

# Set colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}ARTbeat Test Runner${NC}"
echo "============================="

# Initialize counters
TOTAL_PASSED=0
TOTAL_FAILED=0

# Function to run tests for a specific module
run_module_tests() {
  local module=$1
  echo -e "\n${YELLOW}Running tests for ${module}...${NC}"
  
  # Run Flutter tests for the module
  cd "packages/${module}" && flutter test
  
  # Check the result of the test run
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed for ${module}${NC}"
    ((TOTAL_PASSED++))
  else
    echo -e "${RED}✗ Tests failed for ${module}${NC}"
    ((TOTAL_FAILED++))
  fi
  
  # Return to root directory
  cd ../..
}

# Get start time
START_TIME=$(date +%s)

# Run tests for each module
modules=(
  "artbeat_core" 
  "artbeat_auth"
  "artbeat_profile"
  "artbeat_artwork"
)

echo -e "\n${GREEN}Running tests for core modules...${NC}"

# Add modules as they are implemented
# Uncomment when artist module tests are implemented
# modules+=(
#   "artbeat_artist"
# )

# Core modules with working tests
for module in "${modules[@]}"; do
  # Check if the module directory exists and has test files
  if [ -d "packages/${module}/test" ] && [ -n "$(find "packages/${module}/test" -name "*_test.dart" 2>/dev/null)" ]; then
    run_module_tests $module
  else
    echo -e "${YELLOW}⚠ No tests found for ${module}${NC}"
  fi
done

# List other modules that need tests in the future
future_modules=(
  "artbeat_artist"
  "artbeat_art_walk"
  "artbeat_community"
  "artbeat_settings"
  "artbeat_messaging"
)

echo -e "\n${YELLOW}Modules that need tests in the future:${NC}"
for module in "${future_modules[@]}"; do
  echo -e " - ${module}"
done

# Calculate execution time
END_TIME=$(date +%s)
EXECUTION_TIME=$((END_TIME - START_TIME))

# Display summary
echo -e "\n${YELLOW}Test Summary${NC}"
echo "============================="
echo -e "${GREEN}Modules passed: ${TOTAL_PASSED}${NC}"
echo -e "${RED}Modules failed: ${TOTAL_FAILED}${NC}"
echo -e "Total execution time: ${EXECUTION_TIME} seconds"

# Exit with error code if any module failed
if [ $TOTAL_FAILED -gt 0 ]; then
  exit 1
fi

exit 0
