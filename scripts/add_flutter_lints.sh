#!/bin/bash

# List of all feature module directories
MODULES=(
    "artbeat_admin"
    "artbeat_art_walk"
    "artbeat_artist"
    "artbeat_artwork"
    "artbeat_auth"
    "artbeat_capture"
    "artbeat_community"
    "artbeat_core"
    "artbeat_messaging"
    "artbeat_profile"
    "artbeat_settings"
)

# Add dev_dependencies section with flutter_lints to each module's pubspec.yaml
for module in "${MODULES[@]}"; do
    pubspec="/Users/kristybock/updated_artbeat_app/packages/$module/pubspec.yaml"
    if [ -f "$pubspec" ]; then
        # Check if dev_dependencies section exists
        if grep -q "^dev_dependencies:" "$pubspec"; then
            # Add flutter_lints if not present
            if ! grep -q "flutter_lints:" "$pubspec"; then
                sed -i '' '/^dev_dependencies:/a\
  flutter_lints: ^6.0.0' "$pubspec"
            fi
        else
            # Add dev_dependencies section with flutter_lints
            echo -e "\ndev_dependencies:\n  flutter_test:\n    sdk: flutter\n  flutter_lints: ^6.0.0" >> "$pubspec"
        fi
        echo "Updated $module"
    fi
done
