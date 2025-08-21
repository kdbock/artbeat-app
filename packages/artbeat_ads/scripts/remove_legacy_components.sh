#!/bin/bash

# ARTbeat Ads - Legacy Component Removal Script
# This script safely removes legacy components that have been replaced by the simplified ad system

set -e  # Exit on any error

PACKAGE_ROOT="/Users/kristybock/artbeat/packages/artbeat_ads"
BACKUP_DIR="$PACKAGE_ROOT/legacy_backup_$(date +%Y%m%d_%H%M%S)"

echo "🧹 ARTbeat Ads Legacy Component Removal"
echo "========================================"
echo ""

# Create backup directory
echo "📦 Creating backup at: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Function to safely remove file with backup
remove_with_backup() {
    local file_path="$1"
    local relative_path="${file_path#$PACKAGE_ROOT/}"
    
    if [ -f "$file_path" ]; then
        echo "  🗑️  Removing: $relative_path"
        
        # Create backup directory structure
        local backup_file="$BACKUP_DIR/$relative_path"
        local backup_dir=$(dirname "$backup_file")
        mkdir -p "$backup_dir"
        
        # Copy to backup then remove
        cp "$file_path" "$backup_file"
        rm "$file_path"
    else
        echo "  ⚠️  File not found: $relative_path"
    fi
}

echo ""
echo "🗂️  REMOVING LEGACY SCREENS"
echo "============================"

# Legacy Ad Creation Screens
remove_with_backup "$PACKAGE_ROOT/lib/src/screens/artist_ad_create_screen.dart"
remove_with_backup "$PACKAGE_ROOT/lib/src/screens/gallery_ad_create_screen.dart"
remove_with_backup "$PACKAGE_ROOT/lib/src/screens/user_ad_create_screen.dart"
remove_with_backup "$PACKAGE_ROOT/lib/src/screens/base_ad_create_screen.dart"

# Legacy Status/Review Screens
remove_with_backup "$PACKAGE_ROOT/lib/src/screens/artist_ad_status_screen.dart"
remove_with_backup "$PACKAGE_ROOT/lib/src/screens/gallery_ad_status_screen.dart"
remove_with_backup "$PACKAGE_ROOT/lib/src/screens/user_ad_review_screen.dart"
remove_with_backup "$PACKAGE_ROOT/lib/src/screens/admin_ad_review_screen.dart"
remove_with_backup "$PACKAGE_ROOT/lib/src/screens/admin_ad_management_screen.dart"

# Test/Debug Screens
remove_with_backup "$PACKAGE_ROOT/lib/src/screens/ad_creation_test_screen.dart"
remove_with_backup "$PACKAGE_ROOT/lib/src/screens/ad_location_test_screen.dart"
remove_with_backup "$PACKAGE_ROOT/lib/src/screens/quick_test_screen.dart"

echo ""
echo "🧩 REMOVING LEGACY WIDGETS"
echo "=========================="

# Legacy Form Components
remove_with_backup "$PACKAGE_ROOT/lib/src/widgets/universal_ad_form.dart"
remove_with_backup "$PACKAGE_ROOT/lib/src/widgets/ad_form_sections.dart"
remove_with_backup "$PACKAGE_ROOT/lib/src/widgets/ad_type_picker_widget.dart"
remove_with_backup "$PACKAGE_ROOT/lib/src/widgets/ad_payment_widget.dart"

# Legacy Display Widgets
remove_with_backup "$PACKAGE_ROOT/lib/src/widgets/ad_display_widget.dart"
remove_with_backup "$PACKAGE_ROOT/lib/src/widgets/ad_display_widget_old.dart"
remove_with_backup "$PACKAGE_ROOT/lib/src/widgets/dashboard_ad_placement_widget.dart"
remove_with_backup "$PACKAGE_ROOT/lib/src/widgets/dashboard_ad_placement_widget_simple.dart"
remove_with_backup "$PACKAGE_ROOT/lib/src/widgets/dashboard_ad_placement_widget_old.dart"

# Legacy Utility Widgets
remove_with_backup "$PACKAGE_ROOT/lib/src/widgets/dashboard_ad_quick_create_widget.dart"
remove_with_backup "$PACKAGE_ROOT/lib/src/widgets/profile_ad_widget.dart"
remove_with_backup "$PACKAGE_ROOT/lib/src/widgets/ad_debug_widget.dart"
remove_with_backup "$PACKAGE_ROOT/lib/src/widgets/ad_test_widget.dart"

# UI Components
remove_with_backup "$PACKAGE_ROOT/lib/src/widgets/ads_header.dart"
remove_with_backup "$PACKAGE_ROOT/lib/src/widgets/ads_drawer.dart"

# Picker Widgets (replaced by simplified forms)
remove_with_backup "$PACKAGE_ROOT/lib/src/widgets/ad_duration_picker_widget.dart"
remove_with_backup "$PACKAGE_ROOT/lib/src/widgets/ad_location_picker_widget.dart"
remove_with_backup "$PACKAGE_ROOT/lib/src/widgets/ad_status_widget.dart"

echo ""
echo "⚙️  REMOVING LEGACY SERVICES"
echo "============================"

# User-Type Specific Services
remove_with_backup "$PACKAGE_ROOT/lib/src/services/ad_artist_service.dart"
remove_with_backup "$PACKAGE_ROOT/lib/src/services/ad_gallery_service.dart"
remove_with_backup "$PACKAGE_ROOT/lib/src/services/ad_user_service.dart"
remove_with_backup "$PACKAGE_ROOT/lib/src/services/ad_business_service.dart"

# Specialized Services
remove_with_backup "$PACKAGE_ROOT/lib/src/services/ad_upload_service.dart"
remove_with_backup "$PACKAGE_ROOT/lib/src/services/ad_approval_service.dart"
remove_with_backup "$PACKAGE_ROOT/lib/src/services/ad_payment_service.dart"

# Legacy Services
remove_with_backup "$PACKAGE_ROOT/lib/src/services/ad_service.dart"
remove_with_backup "$PACKAGE_ROOT/lib/src/services/ad_fix_service.dart"
remove_with_backup "$PACKAGE_ROOT/lib/src/services/ad_diagnostic_service.dart"
remove_with_backup "$PACKAGE_ROOT/lib/src/services/ad_debug_service.dart"

echo ""
echo "📊 REMOVING LEGACY MODELS"
echo "========================="

# User-Type Specific Models
remove_with_backup "$PACKAGE_ROOT/lib/src/models/ad_artist_model.dart"
remove_with_backup "$PACKAGE_ROOT/lib/src/models/ad_gallery_model.dart"
remove_with_backup "$PACKAGE_ROOT/lib/src/models/ad_user_model.dart"

# Legacy Models
remove_with_backup "$PACKAGE_ROOT/lib/src/models/ad_display_type.dart"
remove_with_backup "$PACKAGE_ROOT/lib/src/models/ad_approval_model.dart"

echo ""
echo "🎛️  REMOVING LEGACY CONTROLLERS"
echo "==============================="

# Controllers (if they exist)
remove_with_backup "$PACKAGE_ROOT/lib/src/controllers/ad_form_controller.dart"

echo ""
echo "🧪 REMOVING LEGACY UTILS"
echo "========================"

# Utility files that are no longer needed
remove_with_backup "$PACKAGE_ROOT/lib/src/utils/placeholder_images.dart"

echo ""
echo "✅ REMOVAL COMPLETE"
echo "==================="
echo ""
echo "📊 Summary:"
echo "  • Legacy screens removed"
echo "  • Legacy widgets removed"  
echo "  • Legacy services removed"
echo "  • Legacy models removed"
echo "  • All files backed up to: $BACKUP_DIR"
echo ""
echo "🔄 Next Steps:"
echo "  1. Run: ./scripts/update_exports.sh"
echo "  2. Run: flutter pub get"
echo "  3. Run: flutter analyze"
echo "  4. Test the simplified system"
echo ""
echo "💡 To restore files if needed:"
echo "  cp -r $BACKUP_DIR/* $PACKAGE_ROOT/"
echo ""