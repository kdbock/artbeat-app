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

# Copy analysis_options.yaml to each module
for module in "${MODULES[@]}"; do
    module_dir="/Users/kristybock/updated_artbeat_app/packages/$module"
    if [ -d "$module_dir" ]; then
        cp "/Users/kristybock/updated_artbeat_app/analysis_options.yaml" "$module_dir/"
        echo "Copied analysis_options.yaml to $module"
    fi
done
