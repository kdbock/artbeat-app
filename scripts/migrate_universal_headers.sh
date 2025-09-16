#!/bin/bash

# Universal ARTbeat Header Migration Script
# This script helps migrate existing screens to use the universal header system

set -e

echo "🎨 Starting Universal ARTbeat Header Migration"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Base directory
BASE_DIR="/Users/kristybock/artbeat/packages"

# Function to update a screen file
update_screen_file() {
    local file_path="$1"
    local module_name="$2"

    echo -e "${BLUE}Updating: ${file_path}${NC}"

    # Check if file exists
    if [[ ! -f "$file_path" ]]; then
        echo -e "${RED}❌ File not found: $file_path${NC}"
        return 1
    fi

    # Add import if not present
    if ! grep -q "universal_artbeat_header.dart" "$file_path"; then
        # Find the first import line and add our import after it
        sed -i '' '1a\
import '\''package:artbeat_core/src/widgets/universal_artbeat_header.dart'\'';
' "$file_path"
        echo -e "${GREEN}✅ Added universal header import${NC}"
    fi

    # Replace AppBar with UniversalArtbeatHeader
    if grep -q "AppBar(" "$file_path"; then
        # This is a complex replacement that would need more sophisticated parsing
        # For now, we'll just flag files that need manual updates
        echo -e "${YELLOW}⚠️  Manual update needed for AppBar in: $file_path${NC}"
        echo -e "${YELLOW}   Please replace AppBar with UniversalArtbeatHeader${NC}"
    fi

    # Replace custom headers with universal header
    if grep -q "EnhancedUniversalHeader\|ArtbeatGradientBackground" "$file_path"; then
        echo -e "${YELLOW}⚠️  Custom header found in: $file_path${NC}"
        echo -e "${YELLOW}   Please replace with UniversalArtbeatHeader${NC}"
    fi
}

# Function to process a module
process_module() {
    local module_name="$1"
    local module_dir="$BASE_DIR/$module_name"

    echo -e "${GREEN}📁 Processing module: $module_name${NC}"

    # Check if module directory exists
    if [[ ! -d "$module_dir" ]]; then
        echo -e "${RED}❌ Module directory not found: $module_dir${NC}"
        return 1
    fi

    # Find all Dart screen files
    local screen_files=$(find "$module_dir" -name "*.dart" -path "*/screens/*" 2>/dev/null || true)

    if [[ -z "$screen_files" ]]; then
        echo -e "${YELLOW}⚠️  No screen files found in $module_name${NC}"
        return 0
    fi

    # Process each screen file
    while IFS= read -r screen_file; do
        update_screen_file "$screen_file" "$module_name"
    done <<< "$screen_files"
}

# Main migration process
echo -e "${BLUE}🔍 Scanning modules for screens to update...${NC}"

# List of modules to process (excluding auth which doesn't use headers)
modules=(
    "artbeat_admin"
    "artbeat_ads"
    "artbeat_art_walk"
    "artbeat_artwork"
    "artbeat_artist"
    "artbeat_capture"
    "artbeat_community"
    "artbeat_core"
    "artbeat_events"
    "artbeat_messaging"
    "artbeat_profile"
    "artbeat_settings"
)

# Process each module
for module in "${modules[@]}"; do
    process_module "$module"
    echo ""
done

echo -e "${GREEN}✅ Migration scan complete!${NC}"
echo ""
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo "1. Review the flagged files above"
echo "2. Manually replace AppBar and custom headers with UniversalArtbeatHeader"
echo "3. Update screen layouts to use Column with Expanded for content"
echo "4. Test all screens for proper header display"
echo "5. Verify color schemes match the module specifications"
echo ""
echo -e "${BLUE}📖 For detailed implementation examples, see:${NC}"
echo "   packages/artbeat_core/UNIVERSAL_HEADER_GUIDE.md"
echo "   packages/artbeat_core/lib/src/screens/example_dashboard_with_universal_header.dart"
