#!/bin/bash
# Build iOS release IPA for production
# Usage: ./scripts/build_ios_release.sh [environment]
# Environment: development, staging, production (default: production)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=${1:-production}
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  ArtBeat iOS Release Build${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Environment: ${YELLOW}$ENVIRONMENT${NC}"
echo ""

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(development|staging|production)$ ]]; then
  echo -e "${RED}Error: Invalid environment '$ENVIRONMENT'${NC}"
  echo "Valid options: development, staging, production"
  exit 1
fi

# Check for environment file
ENV_FILE="$PROJECT_ROOT/.env.$ENVIRONMENT"
if [ "$ENVIRONMENT" = "production" ]; then
  ENV_FILE="$PROJECT_ROOT/.env.production"
fi

if [ ! -f "$ENV_FILE" ]; then
  echo -e "${RED}Error: Environment file not found: $ENV_FILE${NC}"
  echo "Please create the environment file with required variables."
  exit 1
fi

# Copy environment file
echo -e "${YELLOW}Setting up environment...${NC}"
cp "$ENV_FILE" "$PROJECT_ROOT/.env"
echo -e "${GREEN}✓ Environment configured${NC}"

# Check for Xcode
if ! command -v xcodebuild &> /dev/null; then
  echo -e "${RED}Error: Xcode not found${NC}"
  echo "Please install Xcode from the App Store"
  exit 1
fi

# Clean previous builds
echo -e "${YELLOW}Cleaning previous builds...${NC}"
flutter clean
flutter pub get
echo -e "${GREEN}✓ Clean complete${NC}"

# Install CocoaPods dependencies
echo -e "${YELLOW}Installing CocoaPods dependencies...${NC}"
cd "$PROJECT_ROOT/ios"
pod install
cd "$PROJECT_ROOT"
echo -e "${GREEN}✓ CocoaPods installed${NC}"

# Run tests
echo -e "${YELLOW}Running tests...${NC}"
if ./scripts/run_tests.sh; then
  echo -e "${GREEN}✓ Tests passed${NC}"
else
  echo -e "${RED}✗ Tests failed${NC}"
  read -p "Continue anyway? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# Build IPA
echo -e "${YELLOW}Building iOS IPA...${NC}"
if [ "$ENVIRONMENT" = "production" ]; then
  # Check for export options
  if [ ! -f "$PROJECT_ROOT/ios/ExportOptions-Production.plist" ]; then
    echo -e "${YELLOW}Warning: ExportOptions-Production.plist not found${NC}"
    echo "Building without export options..."
    flutter build ipa --release
  else
    flutter build ipa --release --export-options-plist=ios/ExportOptions-Production.plist
  fi
else
  if [ -f "$PROJECT_ROOT/ios/ExportOptions-$ENVIRONMENT.plist" ]; then
    flutter build ipa --release --export-options-plist=ios/ExportOptions-$ENVIRONMENT.plist --build-name="2.0.6-$ENVIRONMENT"
  else
    flutter build ipa --release --build-name="2.0.6-$ENVIRONMENT"
  fi
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Build Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "Environment: ${YELLOW}$ENVIRONMENT${NC}"
echo -e "Output: ${BLUE}build/ios/ipa/artbeat.ipa${NC}"
echo ""

if [ "$ENVIRONMENT" = "production" ]; then
  echo -e "${YELLOW}Next steps:${NC}"
  echo "1. Test the IPA file thoroughly"
  echo "2. Upload to App Store Connect via Xcode or Transporter"
  echo "3. Submit for review"
else
  echo -e "${YELLOW}Next steps:${NC}"
  echo "1. Test the IPA file"
  echo "2. Upload to TestFlight or Firebase App Distribution"
fi

echo ""