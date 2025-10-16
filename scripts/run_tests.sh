#!/bin/bash
# Run all tests across the project
# Usage: ./scripts/run_tests.sh [--coverage]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
COVERAGE=false
FAILED_MODULES=()
PASSED_MODULES=()

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --coverage)
      COVERAGE=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  ArtBeat Test Suite Runner${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# List of modules to test
MODULES=(
  "artbeat_core"
  "artbeat_auth"
  "artbeat_profile"
  "artbeat_artwork"
  "artbeat_artist"
  "artbeat_art_walk"
  "artbeat_community"
  "artbeat_settings"
  "artbeat_messaging"
  "artbeat_events"
  "artbeat_capture"
  "artbeat_ads"
  "artbeat_admin"
)

# Function to run tests for a module
run_module_tests() {
  local module=$1
  local module_path="packages/$module"
  
  echo -e "${YELLOW}Testing: $module${NC}"
  
  # Check if module exists
  if [ ! -d "$module_path" ]; then
    echo -e "${RED}  ✗ Module not found: $module_path${NC}"
    FAILED_MODULES+=("$module (not found)")
    return 1
  fi
  
  # Check if tests exist
  if [ ! -d "$module_path/test" ]; then
    echo -e "${YELLOW}  ⊘ No tests found for $module${NC}"
    return 0
  fi
  
  # Count test files
  test_count=$(find "$module_path/test" -name "*_test.dart" | wc -l | tr -d ' ')
  if [ "$test_count" -eq 0 ]; then
    echo -e "${YELLOW}  ⊘ No test files found for $module${NC}"
    return 0
  fi
  
  echo -e "  Found $test_count test file(s)"
  
  # Install dependencies
  cd "$module_path"
  flutter pub get > /dev/null 2>&1
  
  # Generate mocks if needed
  if grep -q "build_runner" pubspec.yaml 2>/dev/null; then
    echo -e "  Generating mocks..."
    flutter pub run build_runner build --delete-conflicting-outputs > /dev/null 2>&1 || true
  fi
  
  # Run tests
  if [ "$COVERAGE" = true ]; then
    if flutter test --coverage; then
      echo -e "${GREEN}  ✓ Tests passed${NC}"
      PASSED_MODULES+=("$module")
      
      # Show coverage summary
      if [ -f "coverage/lcov.info" ]; then
        lines=$(lcov --summary coverage/lcov.info 2>&1 | grep "lines" || echo "Coverage data available")
        echo -e "  $lines"
      fi
    else
      echo -e "${RED}  ✗ Tests failed${NC}"
      FAILED_MODULES+=("$module")
      cd - > /dev/null
      return 1
    fi
  else
    if flutter test; then
      echo -e "${GREEN}  ✓ Tests passed${NC}"
      PASSED_MODULES+=("$module")
    else
      echo -e "${RED}  ✗ Tests failed${NC}"
      FAILED_MODULES+=("$module")
      cd - > /dev/null
      return 1
    fi
  fi
  
  cd - > /dev/null
  echo ""
}

# Run tests for all modules
for module in "${MODULES[@]}"; do
  run_module_tests "$module" || true
done

# Run main app tests
echo -e "${YELLOW}Testing: Main App${NC}"
if [ -d "test" ]; then
  flutter pub get > /dev/null 2>&1
  if [ "$COVERAGE" = true ]; then
    if flutter test --coverage; then
      echo -e "${GREEN}  ✓ Main app tests passed${NC}"
      PASSED_MODULES+=("main_app")
    else
      echo -e "${RED}  ✗ Main app tests failed${NC}"
      FAILED_MODULES+=("main_app")
    fi
  else
    if flutter test; then
      echo -e "${GREEN}  ✓ Main app tests passed${NC}"
      PASSED_MODULES+=("main_app")
    else
      echo -e "${RED}  ✗ Main app tests failed${NC}"
      FAILED_MODULES+=("main_app")
    fi
  fi
else
  echo -e "${YELLOW}  ⊘ No tests found for main app${NC}"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Test Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Passed: ${#PASSED_MODULES[@]}${NC}"
echo -e "${RED}Failed: ${#FAILED_MODULES[@]}${NC}"

if [ ${#FAILED_MODULES[@]} -gt 0 ]; then
  echo ""
  echo -e "${RED}Failed modules:${NC}"
  for module in "${FAILED_MODULES[@]}"; do
    echo -e "${RED}  - $module${NC}"
  done
  exit 1
else
  echo ""
  echo -e "${GREEN}✓ All tests passed!${NC}"
  exit 0
fi