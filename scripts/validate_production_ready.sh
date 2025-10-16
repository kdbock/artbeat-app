#!/bin/bash

# ArtBeat - Production Readiness Validation Script
# This script checks if your app is ready for production deployment

set -e

echo "🔍 ArtBeat Production Readiness Check"
echo "======================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0
PASSED=0

# Function to print status
print_status() {
    local status=$1
    local message=$2
    
    if [ "$status" == "PASS" ]; then
        echo -e "${GREEN}✅ PASS${NC}: $message"
        ((PASSED++))
    elif [ "$status" == "FAIL" ]; then
        echo -e "${RED}❌ FAIL${NC}: $message"
        ((ERRORS++))
    elif [ "$status" == "WARN" ]; then
        echo -e "${YELLOW}⚠️  WARN${NC}: $message"
        ((WARNINGS++))
    else
        echo -e "${BLUE}ℹ️  INFO${NC}: $message"
    fi
}

echo "Checking Phase 1 Security Fixes..."
echo ""

# Check 1: Storage Rules
echo "1️⃣  Checking Firebase Storage Rules..."
if [ -f "storage.rules" ]; then
    if grep -q "return false" storage.rules && grep -q "isDebugMode()" storage.rules; then
        print_status "PASS" "Storage rules: isDebugMode() is set to false"
    else
        print_status "FAIL" "Storage rules: isDebugMode() should be set to false"
    fi
    
    if grep -q "isValidImageSize()" storage.rules; then
        print_status "PASS" "Storage rules: File size validation present"
    else
        print_status "FAIL" "Storage rules: File size validation missing"
    fi
    
    if grep -q "isValidImageType()" storage.rules; then
        print_status "PASS" "Storage rules: File type validation present"
    else
        print_status "FAIL" "Storage rules: File type validation missing"
    fi
else
    print_status "FAIL" "storage.rules file not found"
fi
echo ""

# Check 2: Firestore Rules
echo "2️⃣  Checking Firestore Rules..."
if [ -f "firestore.rules" ]; then
    print_status "PASS" "Firestore rules file exists"
else
    print_status "FAIL" "firestore.rules file not found"
fi
echo ""

# Check 3: API Keys Security
echo "3️⃣  Checking API Keys Security..."

# Check if .env is gitignored
if git check-ignore .env > /dev/null 2>&1; then
    print_status "PASS" ".env file is properly gitignored"
else
    print_status "FAIL" ".env file is NOT gitignored"
fi

# Check if key.properties is gitignored
if git check-ignore key.properties > /dev/null 2>&1; then
    print_status "PASS" "key.properties is properly gitignored"
else
    print_status "FAIL" "key.properties is NOT gitignored"
fi

# Check if .env exists
if [ -f ".env" ]; then
    print_status "PASS" ".env file exists"
    
    # Check if it has required keys
    if grep -q "GOOGLE_MAPS_API_KEY" .env && ! grep -q "YOUR_" .env; then
        print_status "PASS" ".env appears to be configured"
    else
        print_status "WARN" ".env exists but may need configuration"
    fi
else
    print_status "WARN" ".env file not found (copy from .env.example)"
fi

# Check if files are tracked in git
if git ls-tree -r HEAD --name-only 2>/dev/null | grep -q "^\.env$"; then
    print_status "FAIL" ".env is tracked in git (SECURITY RISK!)"
else
    print_status "PASS" ".env is not tracked in git"
fi

if git ls-tree -r HEAD --name-only 2>/dev/null | grep -q "key\.properties$"; then
    print_status "FAIL" "key.properties is tracked in git (SECURITY RISK!)"
else
    print_status "PASS" "key.properties is not tracked in git"
fi
echo ""

# Check 4: Android Build Configuration
echo "4️⃣  Checking Android Build Configuration..."
if [ -f "android/app/build.gradle.kts" ]; then
    if grep -q "throw GradleException" android/app/build.gradle.kts; then
        print_status "PASS" "Build config: Requires keystore for release builds"
    else
        print_status "WARN" "Build config: May allow debug signing for release"
    fi
    
    if grep -q "proguard-rules.pro" android/app/build.gradle.kts; then
        print_status "PASS" "ProGuard rules configured"
    else
        print_status "WARN" "ProGuard rules not configured"
    fi
else
    print_status "FAIL" "android/app/build.gradle.kts not found"
fi
echo ""

# Check 5: Android Keystore
echo "5️⃣  Checking Android Keystore..."
if [ -f "android/key.properties" ]; then
    print_status "PASS" "key.properties file exists"
    
    # Check if it's configured
    if grep -q "YOUR_" android/key.properties; then
        print_status "WARN" "key.properties needs configuration"
    else
        # Check if keystore file exists
        KEYSTORE_PATH=$(grep "storeFile=" android/key.properties | cut -d'=' -f2)
        if [ -f "$KEYSTORE_PATH" ]; then
            print_status "PASS" "Keystore file exists at: $KEYSTORE_PATH"
        else
            print_status "WARN" "Keystore file not found at: $KEYSTORE_PATH"
            echo "         Run: ./scripts/setup_android_keystore.sh"
        fi
    fi
else
    print_status "WARN" "key.properties not found (run ./scripts/setup_android_keystore.sh)"
fi
echo ""

# Check 6: iOS Configuration
echo "6️⃣  Checking iOS Configuration..."
if [ -d "ios" ]; then
    print_status "PASS" "iOS directory exists"
    
    if [ -f "ios/Runner.xcworkspace/contents.xcworkspacedata" ]; then
        print_status "PASS" "Xcode workspace exists"
    else
        print_status "WARN" "Xcode workspace not found"
    fi
else
    print_status "FAIL" "iOS directory not found"
fi
echo ""

# Check 7: Documentation
echo "7️⃣  Checking Documentation..."
if [ -f "SECURITY_SETUP.md" ]; then
    print_status "PASS" "SECURITY_SETUP.md exists"
else
    print_status "WARN" "SECURITY_SETUP.md not found"
fi

if [ -f "PHASE_1_COMPLETE.md" ]; then
    print_status "PASS" "PHASE_1_COMPLETE.md exists"
else
    print_status "WARN" "PHASE_1_COMPLETE.md not found"
fi

if [ -f "QUICK_START_PRODUCTION.md" ]; then
    print_status "PASS" "QUICK_START_PRODUCTION.md exists"
else
    print_status "WARN" "QUICK_START_PRODUCTION.md not found"
fi
echo ""

# Check 8: Flutter Dependencies
echo "8️⃣  Checking Flutter Dependencies..."
if command -v flutter &> /dev/null; then
    print_status "PASS" "Flutter is installed"
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    echo "         $FLUTTER_VERSION"
else
    print_status "FAIL" "Flutter is not installed"
fi
echo ""

# Check 9: Firebase CLI
echo "9️⃣  Checking Firebase CLI..."
if command -v firebase &> /dev/null; then
    print_status "PASS" "Firebase CLI is installed"
    FIREBASE_VERSION=$(firebase --version)
    echo "         Version: $FIREBASE_VERSION"
else
    print_status "WARN" "Firebase CLI not installed (needed for deployment)"
    echo "         Install: npm install -g firebase-tools"
fi
echo ""

# Summary
echo "======================================"
echo "📊 Summary"
echo "======================================"
echo -e "${GREEN}✅ Passed: $PASSED${NC}"
echo -e "${YELLOW}⚠️  Warnings: $WARNINGS${NC}"
echo -e "${RED}❌ Failed: $ERRORS${NC}"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}🎉 Congratulations! Your app is production ready!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Deploy Firebase rules: firebase deploy --only firestore:rules,storage:rules"
    echo "2. Build release: flutter build appbundle --release (Android)"
    echo "3. Build release: flutter build ios --release (iOS)"
    echo ""
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Your app is mostly ready, but has some warnings.${NC}"
    echo ""
    echo "Review warnings above and address them before production deployment."
    echo "See QUICK_START_PRODUCTION.md for detailed instructions."
    echo ""
    exit 0
else
    echo -e "${RED}❌ Your app is NOT ready for production.${NC}"
    echo ""
    echo "Please fix the errors above before deploying."
    echo "See SECURITY_SETUP.md for detailed instructions."
    echo ""
    exit 1
fi