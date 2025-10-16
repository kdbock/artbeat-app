#!/bin/bash

# Get Firebase App IDs from google-services.json files
# These IDs are needed for Firebase App Distribution in CI/CD

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Extract Firebase App IDs for GitHub Secrets              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}⚠️  jq is not installed. Installing via Homebrew...${NC}"
    brew install jq
fi

echo -e "${YELLOW}📱 Extracting Firebase App IDs...${NC}"
echo ""

# Android Staging
ANDROID_STAGING_FILE="$PROJECT_ROOT/android/app/google-services.json"
if [ -f "$ANDROID_STAGING_FILE" ]; then
    ANDROID_APP_ID=$(jq -r '.client[0].client_info.mobilesdk_app_id' "$ANDROID_STAGING_FILE")
    echo -e "${GREEN}✅ Android Staging App ID:${NC}"
    echo -e "   ${BLUE}$ANDROID_APP_ID${NC}"
    echo ""
    echo -e "${YELLOW}📋 Add to GitHub as:${NC}"
    echo -e "   Name: ${GREEN}FIREBASE_ANDROID_APP_ID_STAGING${NC}"
    echo -e "   Value: ${BLUE}$ANDROID_APP_ID${NC}"
    echo ""
    
    # Copy to clipboard
    echo -e "${YELLOW}Copy to clipboard? (y/n)${NC}"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "$ANDROID_APP_ID" | pbcopy
        echo -e "${GREEN}✅ Copied to clipboard!${NC}"
    fi
    echo ""
else
    echo -e "${RED}❌ Android google-services.json not found${NC}"
    echo -e "   Expected: $ANDROID_STAGING_FILE"
    echo ""
fi

# iOS Staging
IOS_STAGING_FILE="$PROJECT_ROOT/ios/Runner/GoogleService-Info.plist"
if [ -f "$IOS_STAGING_FILE" ]; then
    IOS_APP_ID=$(/usr/libexec/PlistBuddy -c "Print :GOOGLE_APP_ID" "$IOS_STAGING_FILE" 2>/dev/null || echo "")
    if [ -n "$IOS_APP_ID" ]; then
        echo -e "${GREEN}✅ iOS Staging App ID:${NC}"
        echo -e "   ${BLUE}$IOS_APP_ID${NC}"
        echo ""
        echo -e "${YELLOW}📋 Add to GitHub as:${NC}"
        echo -e "   Name: ${GREEN}FIREBASE_IOS_APP_ID_STAGING${NC}"
        echo -e "   Value: ${BLUE}$IOS_APP_ID${NC}"
        echo ""
        
        # Copy to clipboard
        echo -e "${YELLOW}Copy to clipboard? (y/n)${NC}"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            echo "$IOS_APP_ID" | pbcopy
            echo -e "${GREEN}✅ Copied to clipboard!${NC}"
        fi
        echo ""
    else
        echo -e "${RED}❌ Could not extract iOS App ID${NC}"
        echo ""
    fi
else
    echo -e "${YELLOW}⚠️  iOS GoogleService-Info.plist not found${NC}"
    echo -e "   Expected: $IOS_STAGING_FILE"
    echo -e "   ${BLUE}This is OK if you haven't set up iOS yet${NC}"
    echo ""
fi

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Firebase App IDs extracted!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}📝 Next Steps:${NC}"
echo ""
echo -e "1️⃣  Go to GitHub Secrets:"
echo -e "   ${BLUE}https://github.com/kdbock/artbeat-app/settings/secrets/actions${NC}"
echo ""
echo -e "2️⃣  Add the App IDs shown above as secrets"
echo ""
echo -e "3️⃣  Continue with other missing secrets (see FINAL_5_PERCENT_CHECKLIST.md)"
echo ""