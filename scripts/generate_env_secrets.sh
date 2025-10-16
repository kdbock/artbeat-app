#!/bin/bash

# Generate Environment Secrets for GitHub Actions
# This script creates the ENV_STAGING and ENV_PRODUCTION secrets content

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
echo -e "${BLUE}║  Generate Environment Secrets for GitHub Actions          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Create temp directory
TEMP_DIR="/tmp/artbeat-secrets"
mkdir -p "$TEMP_DIR"

echo -e "${YELLOW}📝 Generating ENV_STAGING secret...${NC}"
echo ""

# Generate ENV_STAGING
cat > "$TEMP_DIR/ENV_STAGING.txt" << 'EOF'
# Staging Environment Variables
FIREBASE_ANDROID_API_KEY=AIzaSyBUWD0WyB4XIk7aRbewY-TxFbx-kam7ufw
FIREBASE_IOS_API_KEY=AIzaSyBUWD0WyB4XIk7aRbewY-TxFbx-kam7ufw
GOOGLE_MAPS_API_KEY=placeholder_staging_maps_key
STRIPE_PUBLISHABLE_KEY=pk_test_placeholder
ENVIRONMENT=staging
DEBUG_MODE=false
ENABLE_LOGGING=true
FIREBASE_REGION=us-central1
ENABLE_ANALYTICS=true
ENABLE_CRASH_REPORTING=true
ENABLE_PERFORMANCE_MONITORING=true
ENABLE_DEBUG_FEATURES=false
API_BASE_URL=https://staging-api.artbeat.app
EOF

echo -e "${GREEN}✅ ENV_STAGING generated${NC}"
echo -e "   Location: $TEMP_DIR/ENV_STAGING.txt"
echo ""

echo -e "${YELLOW}📝 Generating ENV_PRODUCTION secret...${NC}"
echo ""

# Generate ENV_PRODUCTION
cat > "$TEMP_DIR/ENV_PRODUCTION.txt" << 'EOF'
# Production Environment Variables
FIREBASE_ANDROID_API_KEY=AIzaSyDDUfVnn2i20lPMNcERAG55ohKLhyK8ptg
FIREBASE_IOS_API_KEY=AIzaSyDDUfVnn2i20lPMNcERAG55ohKLhyK8ptg
GOOGLE_MAPS_API_KEY=placeholder_production_maps_key
STRIPE_PUBLISHABLE_KEY=pk_live_51QpJ6iAO5ulTKoALD0MCyfwOCP2ivyVgKNK457uvrjJ0N9uj9Y7uSAtWfYq7nyuFZFqMjF4BHaDOYuMpwxd0PdbK00Ooktqk6z
ENVIRONMENT=production
DEBUG_MODE=false
ENABLE_LOGGING=false
FIREBASE_REGION=us-central1
ENABLE_ANALYTICS=true
ENABLE_CRASH_REPORTING=true
ENABLE_PERFORMANCE_MONITORING=true
ENABLE_DEBUG_FEATURES=false
API_BASE_URL=https://api.artbeat.app
EOF

echo -e "${GREEN}✅ ENV_PRODUCTION generated${NC}"
echo -e "   Location: $TEMP_DIR/ENV_PRODUCTION.txt"
echo ""

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Environment secrets generated successfully!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}📋 Next Steps:${NC}"
echo ""
echo -e "1️⃣  Copy ENV_STAGING to clipboard:"
echo -e "   ${BLUE}cat $TEMP_DIR/ENV_STAGING.txt | pbcopy${NC}"
echo ""
echo -e "2️⃣  Add to GitHub:"
echo -e "   • Go to: ${BLUE}https://github.com/kdbock/artbeat-app/settings/secrets/actions${NC}"
echo -e "   • Click 'New repository secret'"
echo -e "   • Name: ${GREEN}ENV_STAGING${NC}"
echo -e "   • Value: Paste from clipboard"
echo ""
echo -e "3️⃣  Copy ENV_PRODUCTION to clipboard:"
echo -e "   ${BLUE}cat $TEMP_DIR/ENV_PRODUCTION.txt | pbcopy${NC}"
echo ""
echo -e "4️⃣  Add to GitHub:"
echo -e "   • Name: ${GREEN}ENV_PRODUCTION${NC}"
echo -e "   • Value: Paste from clipboard"
echo ""
echo -e "${YELLOW}💡 Tip: Files will remain in $TEMP_DIR until you delete them${NC}"
echo ""

# Offer to copy to clipboard
echo -e "${YELLOW}Would you like to copy ENV_STAGING to clipboard now? (y/n)${NC}"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    cat "$TEMP_DIR/ENV_STAGING.txt" | pbcopy
    echo -e "${GREEN}✅ ENV_STAGING copied to clipboard!${NC}"
    echo -e "${YELLOW}Now add it to GitHub, then come back to copy ENV_PRODUCTION${NC}"
    echo ""
    echo -e "${YELLOW}Press Enter when ready to copy ENV_PRODUCTION...${NC}"
    read -r
    cat "$TEMP_DIR/ENV_PRODUCTION.txt" | pbcopy
    echo -e "${GREEN}✅ ENV_PRODUCTION copied to clipboard!${NC}"
    echo -e "${YELLOW}Now add it to GitHub${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Done!${NC}"