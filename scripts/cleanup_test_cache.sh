#!/bin/zsh

echo "Cleaning up test cache files..."

# Remove test cache directories
find . -type d -name "test_cache" -exec rm -rf {} +

# Remove .dill files in build directories
find . -type f -name "*.dill" -path "*/build/*" -exec rm -f {} +

# Remove build directories in packages
for dir in packages/*/build; do
  if [ -d "$dir" ]; then
    echo "Removing $dir"
    rm -rf "$dir"
  fi
done

# Remove .dart_tool directories in packages
for dir in packages/*/.dart_tool; do
  if [ -d "$dir" ]; then
    echo "Removing $dir"
    rm -rf "$dir"
  fi
done

echo "Cleanup complete!"
