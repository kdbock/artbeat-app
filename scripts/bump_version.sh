#!/bin/bash

# ARTbeat Version Bump Script
# This script increments the version number in pubspec.yaml

set -e

PUBSPEC_FILE="pubspec.yaml"

# Function to display usage
usage() {
    echo "Usage: $0 [major|minor|patch|build]"
    echo "  major: Increment major version (1.0.0 -> 2.0.0)"
    echo "  minor: Increment minor version (1.0.0 -> 1.1.0)"
    echo "  patch: Increment patch version (1.0.0 -> 1.0.1)"
    echo "  build: Increment build number only (1.0.0+1 -> 1.0.0+2)"
    exit 1
}

# Check if argument is provided
if [ $# -eq 0 ]; then
    usage
fi

# Get current version from pubspec.yaml
CURRENT_VERSION=$(grep "^version:" $PUBSPEC_FILE | sed 's/version: //')
echo "Current version: $CURRENT_VERSION"

# Split version and build number
VERSION_PART=$(echo $CURRENT_VERSION | cut -d'+' -f1)
BUILD_PART=$(echo $CURRENT_VERSION | cut -d'+' -f2)

# Split version into major.minor.patch
MAJOR=$(echo $VERSION_PART | cut -d'.' -f1)
MINOR=$(echo $VERSION_PART | cut -d'.' -f2)
PATCH=$(echo $VERSION_PART | cut -d'.' -f3)

# Increment based on argument
case $1 in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        BUILD_PART=$((BUILD_PART + 1))
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        BUILD_PART=$((BUILD_PART + 1))
        ;;
    patch)
        PATCH=$((PATCH + 1))
        BUILD_PART=$((BUILD_PART + 1))
        ;;
    build)
        BUILD_PART=$((BUILD_PART + 1))
        ;;
    *)
        echo "Invalid argument: $1"
        usage
        ;;
esac

# Create new version string
NEW_VERSION="$MAJOR.$MINOR.$PATCH+$BUILD_PART"

echo "New version: $NEW_VERSION"

# Update pubspec.yaml
sed -i.bak "s/^version: .*/version: $NEW_VERSION/" $PUBSPEC_FILE

echo "✅ Version updated in $PUBSPEC_FILE"
echo "📝 Backup saved as ${PUBSPEC_FILE}.bak"

# Ask if user wants to commit the change
read -p "Do you want to commit this version change? (y/n) " COMMIT_CHANGE
if [[ $COMMIT_CHANGE == "y" || $COMMIT_CHANGE == "Y" ]]; then
    git add $PUBSPEC_FILE
    git commit -m "Bump version to $NEW_VERSION"
    echo "✅ Version change committed to git"
fi

echo "========================================="
echo "🎉 Version bump complete!"
echo "Old version: $CURRENT_VERSION"
echo "New version: $NEW_VERSION"
echo "========================================="