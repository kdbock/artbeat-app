#!/bin/bash

# ARTbeat Ads - Export Update Script
# Updates the main library export file to remove references to deleted legacy components

set -e  # Exit on any error

PACKAGE_ROOT="/Users/kristybock/artbeat/packages/artbeat_ads"
EXPORT_FILE="$PACKAGE_ROOT/lib/artbeat_ads.dart"

echo "📝 ARTbeat Ads Export Update"
echo "============================"
echo ""

# Create backup of current exports
echo "📦 Creating backup of current exports..."
cp "$EXPORT_FILE" "$EXPORT_FILE.backup.$(date +%Y%m%d_%H%M%S)"

echo "🔄 Updating exports to remove legacy components..."

# Create new export file with only simplified components
cat > "$EXPORT_FILE" << 'EOF'
library artbeat_ads;

// Core Models
export 'src/models/ad_model.dart';
export 'src/models/ad_type.dart';
export 'src/models/ad_size.dart';
export 'src/models/ad_status.dart';
export 'src/models/ad_location.dart';
export 'src/models/ad_duration.dart';

// Simplified Services
export 'src/services/simple_ad_service.dart';
export 'src/services/ad_cleanup_service.dart';

// Simplified Widgets
export 'src/widgets/simple_ad_display_widget.dart';
export 'src/widgets/simple_ad_placement_widget.dart';
export 'src/widgets/missing_ad_widgets.dart'; // BannerAdWidget, FeedAdWidget, etc.

// Simplified Screens
export 'src/screens/simple_ad_create_screen.dart';
export 'src/screens/simple_ad_management_screen.dart';

// Examples
export 'src/examples/simple_ad_example.dart';
EOF

echo "✅ Export file updated successfully!"
echo ""
echo "📋 New exports include:"
echo "  • Core models (AdModel, AdType, AdSize, etc.)"
echo "  • SimpleAdService & AdCleanupService"
echo "  • Simplified widgets (SimpleAdDisplayWidget, etc.)"
echo "  • Banner & Feed ad widgets"
echo "  • Simplified screens (create & management)"
echo "  • Usage examples"
echo ""
echo "🚫 Removed exports:"
echo "  • All legacy user-type specific components"
echo "  • Complex form widgets"
echo "  • Legacy services"
echo "  • Debug/test components"
echo ""