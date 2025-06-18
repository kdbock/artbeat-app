#!/bin/zsh

echo "Starting module finalization process..."

# Function to create export files
create_export_file() {
  local dir=$1
  local module=$2
  local file_type=$3
  local export_file="${dir}/${file_type}s.dart"
  
  # Check if the directory exists
  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir"
  fi
  
  # Create header for the file
  echo "// ${module} ${file_type}s export file" > "$export_file"
  echo "// Generated on $(date)" >> "$export_file"
  echo "" >> "$export_file"
  
  # Find all dart files in the directory and generate export statements
  find "$dir" -name "*.dart" | grep -v "${file_type}s.dart" | while read -r file; do
    file_name=$(basename "$file" .dart)
    echo "export '${file_name}.dart';" >> "$export_file"
  done
  
  echo "✅ Created export file: $export_file"
}

# Function to create entry point export files for each module
create_module_exports() {
  local module_dir=$1
  local module_name=$2
  local entry_file="${module_dir}/lib/${module_name}.dart"
  
  echo "// ${module_name} entry point" > "$entry_file"
  echo "// Generated on $(date)" >> "$entry_file"
  echo "" >> "$entry_file"
  
  # Add exports for model files if they exist
  if [[ -d "${module_dir}/lib/src/models" && "$(find ${module_dir}/lib/src/models -name "*.dart" | wc -l)" -gt 0 ]]; then
    echo "export 'src/models/models.dart';" >> "$entry_file"
  fi
  
  # Add exports for service files if they exist
  if [[ -d "${module_dir}/lib/src/services" && "$(find ${module_dir}/lib/src/services -name "*.dart" | wc -l)" -gt 0 ]]; then
    echo "export 'src/services/services.dart';" >> "$entry_file"
  fi
  
  # Add exports for screen files if they exist
  if [[ -d "${module_dir}/lib/src/screens" && "$(find ${module_dir}/lib/src/screens -name "*.dart" | wc -l)" -gt 0 ]]; then
    echo "export 'src/screens/screens.dart';" >> "$entry_file"
  fi
  
  # Add exports for widget files if they exist
  if [[ -d "${module_dir}/lib/src/widgets" && "$(find ${module_dir}/lib/src/widgets -name "*.dart" | wc -l)" -gt 0 ]]; then
    echo "export 'src/widgets/widgets.dart';" >> "$entry_file"
  fi
  
  # Add exports for utility files if they exist
  if [[ -d "${module_dir}/lib/src/utils" && "$(find ${module_dir}/lib/src/utils -name "*.dart" | wc -l)" -gt 0 ]]; then
    echo "export 'src/utils/utils.dart';" >> "$entry_file"
  fi
  
  # Add exports for data files if they exist
  if [[ -d "${module_dir}/lib/src/data" && "$(find ${module_dir}/lib/src/data -name "*.dart" | wc -l)" -gt 0 ]]; then
    echo "export 'src/data/data.dart';" >> "$entry_file"
  fi
  
  echo "✅ Created module entry point: $entry_file"
}

# Process each module
echo "Creating export files for each module..."

for module in artbeat_core artbeat_auth artbeat_artist artbeat_artwork artbeat_art_walk artbeat_community artbeat_profile artbeat_settings artbeat_calendar artbeat_capture; do
  module_dir="packages/$module"
  
  if [[ -d "$module_dir" ]]; then
    echo "Processing module: $module"
    
    # Create export files for each category
    if [[ -d "${module_dir}/lib/src/models" ]]; then
      create_export_file "${module_dir}/lib/src/models" "$module" "model"
    fi
    
    if [[ -d "${module_dir}/lib/src/services" ]]; then
      create_export_file "${module_dir}/lib/src/services" "$module" "service"
    fi
    
    if [[ -d "${module_dir}/lib/src/screens" ]]; then
      create_export_file "${module_dir}/lib/src/screens" "$module" "screen"
    fi
    
    if [[ -d "${module_dir}/lib/src/widgets" ]]; then
      create_export_file "${module_dir}/lib/src/widgets" "$module" "widget"
    fi
    
    if [[ -d "${module_dir}/lib/src/utils" ]]; then
      create_export_file "${module_dir}/lib/src/utils" "$module" "util"
    fi
    
    if [[ -d "${module_dir}/lib/src/data" ]]; then
      create_export_file "${module_dir}/lib/src/data" "$module" "data"
    fi
    
    # Create module entry point
    create_module_exports "$module_dir" "$module"
  fi
done

# Create default pubspec.yaml for modules that might not have one yet
for module in artbeat_core artbeat_auth artbeat_artist artbeat_artwork artbeat_art_walk artbeat_community artbeat_profile artbeat_settings artbeat_calendar artbeat_capture; do
  module_dir="packages/$module"
  pubspec_file="${module_dir}/pubspec.yaml"
  
  if [[ ! -f "$pubspec_file" ]]; then
    echo "Creating pubspec.yaml for $module"
    
    # Generate a basic pubspec.yaml file
    cat > "$pubspec_file" << EOF
name: $module
description: ${module} module for ARTbeat app
version: 0.1.0

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: ">=3.0.0"

dependencies:
  flutter:
    sdk: flutter
  
  # Core dependencies
  firebase_core: ^2.15.0
  firebase_auth: ^4.7.2
  cloud_firestore: ^4.8.4
  firebase_storage: ^11.2.5
EOF
    
    # Add specific dependencies based on the module
    if [[ "$module" == "artbeat_core" ]]; then
      cat >> "$pubspec_file" << EOF
  
  # Additional dependencies
  shared_preferences: ^2.2.0
  http: ^1.1.0
  provider: ^6.0.5
  intl: ^0.18.1
EOF
    elif [[ "$module" == "artbeat_art_walk" ]]; then
      cat >> "$pubspec_file" << EOF
  
  # Maps dependencies
  google_maps_flutter: ^2.4.0
  geolocator: ^10.0.0
  geocoding: ^2.1.0
  
  # Core module dependency
  artbeat_core:
    path: ../artbeat_core
EOF
    elif [[ "$module" == "artbeat_artwork" ]]; then
      cat >> "$pubspec_file" << EOF
  
  # Image handling
  image_picker: ^1.0.2
  
  # Core module dependency
  artbeat_core:
    path: ../artbeat_core
EOF
    elif [[ "$module" == "artbeat_artist" ]]; then
      cat >> "$pubspec_file" << EOF
  
  # Stripe integration
  flutter_stripe: ^9.3.0
  
  # Core module dependency
  artbeat_core:
    path: ../artbeat_core
  
  # Artwork module dependency
  artbeat_artwork:
    path: ../artbeat_artwork
EOF
    else
      cat >> "$pubspec_file" << EOF
  
  # Core module dependency
  artbeat_core:
    path: ../artbeat_core
EOF
    fi
    
    # Close the pubspec.yaml file
    cat >> "$pubspec_file" << EOF

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.2

flutter:
  uses-material-design: true
EOF
    
    echo "✅ Created pubspec.yaml for $module"
  fi
done

# Update main app's pubspec.yaml to reference all modules
echo "Updating main app's pubspec.yaml to reference all modules..."

# Create a backup of the current pubspec.yaml
cp pubspec.yaml pubspec.yaml.bak

# Read existing pubspec.yaml to a temp file with module dependencies
cat pubspec.yaml > pubspec.yaml.tmp

# Ensure we're not duplicating the modules if they already exist in the file
if ! grep -q "# Local modules" pubspec.yaml; then
  cat >> pubspec.yaml.tmp << EOF

  # Local modules
  artbeat_core:
    path: packages/artbeat_core
  artbeat_auth:
    path: packages/artbeat_auth  
  artbeat_artist:
    path: packages/artbeat_artist
  artbeat_artwork:
    path: packages/artbeat_artwork
  artbeat_art_walk:
    path: packages/artbeat_art_walk
  artbeat_community:
    path: packages/artbeat_community
  artbeat_profile:
    path: packages/artbeat_profile
  artbeat_settings:
    path: packages/artbeat_settings
  artbeat_calendar:
    path: packages/artbeat_calendar
  artbeat_capture:
    path: packages/artbeat_capture
EOF

  # Replace the original pubspec.yaml
  mv pubspec.yaml.tmp pubspec.yaml
  echo "✅ Updated main pubspec.yaml with module dependencies"
else
  echo "Module dependencies already exist in pubspec.yaml"
  rm pubspec.yaml.tmp
fi

echo "Modularization finalization completed!"
echo "Next steps:"
echo "1. Run 'flutter pub get' to update dependencies"
echo "2. Add missing files to the appropriate modules"
echo "3. Update import statements in the main app"
echo "4. Test the application to ensure everything works"