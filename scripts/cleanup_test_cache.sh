#!/bin/zsh

echo "Cleaning up test cache files..."

# Remove test cache directories
find . -type d -name "test_cache" -exec rm -rf {} +

# Remove .dill files in build directories
find . -type f -name "*.dill" -path "*/build/*" -exec rm -f {} +

# Remove build directories in packages
find ./packages -type d -name "build" -exec rm -rf {} +

# Remove .dart_tool directories in packages
find ./packages -type d -name ".dart_tool" -exec rm -rf {} +

echo "Cleanup complete!"
