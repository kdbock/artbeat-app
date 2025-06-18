#!/bin/bash

# Script to help set up Firebase configuration securely

# Check if firebase_options.dart exists
if [ ! -f "lib/firebase_options.dart" ]; then
    echo "❌ Error: lib/firebase_options.dart not found"
    exit 1
fi

# Create backup of current firebase_options.dart
cp lib/firebase_options.dart lib/firebase_options.backup.dart

# Copy template
cp lib/firebase_options.template.dart lib/firebase_options.dart

# Update .gitignore
if ! grep -q "lib/firebase_options.dart" .gitignore; then
    echo "lib/firebase_options.dart" >> .gitignore
    echo "✅ Added firebase_options.dart to .gitignore"
fi

# Instructions for developers
echo "
🎯 Next steps:

1. Your original Firebase configuration has been backed up to:
   lib/firebase_options.backup.dart

2. A new template has been created at:
   lib/firebase_options.dart

3. Update lib/firebase_options.dart with your Firebase configuration:
   - Go to Firebase Console
   - Get your project configuration
   - Update the file with your details

4. Once confirmed working, you can delete:
   lib/firebase_options.backup.dart

❗Important:
- Never commit firebase_options.dart to version control
- Keep your API keys secure
- See README.md for more security best practices

For more information, see the Firebase Configuration section in README.md
"
