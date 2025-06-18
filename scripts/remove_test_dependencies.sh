#!/bin/zsh

# Make script exit on first error
set -e

# Function to remove test dependencies from a pubspec.yaml file
remove_test_deps() {
    local file=$1
    echo "Cleaning $file..."
    
    # Create a temporary file
    temp_file=$(mktemp)
    
    # Process the file while maintaining proper YAML structure
    awk '
        BEGIN { in_dev_deps = 0; in_deps = 0; blank_lines = 0 }
        
        # Track sections
        /^dependencies:/ { in_deps = 1 }
        /^dev_dependencies:/ { in_dev_deps = 1; next }
        /^[a-zA-Z][^:]*:/ && !/^dependencies:/ { in_deps = 0; in_dev_deps = 0 }
        
        # Skip dev_dependencies section
        in_dev_deps { next }
        
        # Skip test-related dependencies
        in_deps && /^ *(flutter_test|test|mockito|build_runner|fake_cloud_firestore|firebase_auth_mocks|firebase_storage_mocks|golden_toolkit):/ { next }
        
        # Print non-empty lines
        /^[[:space:]]*$/ { blank_lines++; next }
        {
            # Print at most one blank line
            if (blank_lines > 0) {
                print ""
                blank_lines = 0
            }
            print
        }
    ' "$file" > "$temp_file"
    
    # Replace original file with cleaned version
    mv "$temp_file" "$file"
}

# Clean main pubspec.yaml
remove_test_deps "pubspec.yaml"

# Clean all module pubspec.yaml files
for module_pubspec in packages/*/pubspec.yaml; do
    remove_test_deps "$module_pubspec"
done

# Run flutter pub get in all directories
echo "Updating dependencies..."
flutter pub get

for dir in packages/*; do
    if [ -d "$dir" ]; then
        echo "Updating dependencies in $dir..."
        (cd "$dir" && flutter pub get)
    fi
done

echo "All test dependencies have been removed!"
