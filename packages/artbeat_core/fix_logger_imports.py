#!/usr/bin/env python3

import os
import re

# List of files that need the logger import
files_to_fix = [
    "lib/src/examples/order_review_example.dart",    
    "lib/src/providers/messaging_provider.dart",
    "lib/src/screens/advanced_analytics_dashboard.dart",
    "lib/src/screens/enhanced_gift_purchase_screen.dart",
    "lib/src/screens/fluid_dashboard_screen_refactored.dart",
    "lib/src/screens/leaderboard_screen.dart",
    "lib/src/services/ai_features_service.dart",
    "lib/src/services/app_initialization_service.dart",
    "lib/src/services/artist_feature_testing_service.dart",
    "lib/src/services/artist_service.dart",
    "lib/src/services/auth_service.dart",
    "lib/src/services/caching_service.dart",
    "lib/src/services/config_service.dart",
    "lib/src/services/content_engagement_service.dart",
    "lib/src/services/engagement_migration_service.dart",
    "lib/src/services/enhanced_gift_service.dart",
    "lib/src/services/enhanced_storage_service.dart",
    "lib/src/services/feedback_service.dart",
    "lib/src/services/filter_service.dart",
    "lib/src/services/firebase_config_service.dart",
    "lib/src/services/firebase_diagnostic_service.dart",
    "lib/src/services/firebase_storage_auth_service.dart",
    "lib/src/services/image_management_service.dart",
    "lib/src/services/internationalization_service.dart",
    "lib/src/services/leaderboard_service.dart",
    "lib/src/services/maps_diagnostic_service.dart",
    "lib/src/services/notification_service.dart",
    "lib/src/services/offline_data_provider.dart",
    "lib/src/services/payment_service.dart",
    "lib/src/services/sponsorship_service.dart",
    "lib/src/services/subscription_plan_validator.dart",
    "lib/src/services/subscription_service.dart",
    "lib/src/services/user_service.dart",
    "lib/src/storage/enhanced_storage_service.dart",
    "lib/src/utils/env_loader.dart",
    "lib/src/utils/env_validator.dart",
    "lib/src/utils/location_utils.dart",
    "lib/src/utils/order_review_helpers.dart",
    "lib/src/utils/performance_monitor.dart",
    "lib/src/utils/permission_utils.dart",
    "lib/src/utils/user_sync_helper.dart",
    "lib/src/viewmodels/dashboard_view_model.dart",
    "lib/src/widgets/artbeat_drawer.dart",
    "lib/src/widgets/dashboard/dashboard_artwork_section.dart",
    "lib/src/widgets/dashboard/dashboard_community_section.dart",
    "lib/src/widgets/dashboard/dashboard_events_section.dart",
    "lib/src/widgets/enhanced_navigation_menu.dart",
    "lib/src/widgets/leaderboard_preview_widget.dart",
    "lib/src/widgets/loading_screen.dart",
    "lib/src/widgets/secure_network_image.dart",
    "lib/src/widgets/temp_capture_fix.dart",
    "lib/src/widgets/user_avatar.dart"
]

def calculate_relative_path(from_file, to_file="lib/src/utils/logger.dart"):
    """Calculate relative path from one file to another"""
    from_dir = os.path.dirname(from_file)
    from_parts = from_dir.split('/')
    to_parts = to_file.split('/')
    
    # Remove common parts
    while from_parts and to_parts and from_parts[0] == to_parts[0]:
        from_parts.pop(0)
        to_parts.pop(0)
    
    # Go up directories
    up_dirs = ['..'] * len(from_parts)
    
    # Combine with remaining path to target
    relative_path = '/'.join(up_dirs + to_parts)
    
    return relative_path

def fix_file(file_path):
    """Add logger import to a file if it doesn't already have it"""
    
    if not os.path.exists(file_path):
        print(f"Warning: {file_path} does not exist")
        return False
    
    # Calculate relative import path
    relative_import = calculate_relative_path(file_path)
    import_line = f"import '{relative_import}';"
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Check if the import already exists
    if relative_import in content or 'logger.dart' in content:
        print(f"✓ {file_path} already has logger import")
        return True
    
    # Find the last import line
    lines = content.split('\n')
    last_import_index = -1
    
    for i, line in enumerate(lines):
        if line.strip().startswith('import '):
            last_import_index = i
    
    if last_import_index >= 0:
        # Insert after the last import
        lines.insert(last_import_index + 1, import_line)
        new_content = '\n'.join(lines)
        
        with open(file_path, 'w') as f:
            f.write(new_content)
        
        print(f"✓ Added logger import to {file_path}")
        return True
    else:
        print(f"✗ Could not find import section in {file_path}")
        return False

def main():
    success_count = 0
    total_count = len(files_to_fix)
    
    print(f"Fixing logger imports in {total_count} files...")
    
    for file_path in files_to_fix:
        if fix_file(file_path):
            success_count += 1
    
    print(f"\nCompleted: {success_count}/{total_count} files fixed successfully")

if __name__ == "__main__":
    main()
