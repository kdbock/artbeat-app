#!/usr/bin/env python3
"""
Script to help migrate Image.network calls to SecureNetworkImage
for Firebase Storage URLs in the ARTbeat Flutter app.
"""

import os
import re
import sys

def find_dart_files(root_dir):
    """Find all Dart files in the project."""
    dart_files = []
    for root, dirs, files in os.walk(root_dir):
        # Skip build directories and other non-source directories
        dirs[:] = [d for d in dirs if d not in ['.dart_tool', 'build', '.git', 'node_modules']]
        
        for file in files:
            if file.endswith('.dart'):
                dart_files.append(os.path.join(root, file))
    
    return dart_files

def analyze_image_network_usage(file_path):
    """Analyze Image.network usage in a Dart file."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Find Image.network patterns
        image_network_pattern = r'Image\.network\s*\('
        matches = list(re.finditer(image_network_pattern, content))
        
        if matches:
            return {
                'file': file_path,
                'matches': len(matches),
                'content': content,
                'has_secure_import': 'SecureNetworkImage' in content,
                'has_artbeat_core_import': 'artbeat_core' in content
            }
    
    except Exception as e:
        print(f"Error reading {file_path}: {e}")
    
    return None

def suggest_migration(analysis):
    """Suggest migration steps for a file."""
    suggestions = []
    
    # Check if import is needed
    if not analysis['has_secure_import']:
        if analysis['has_artbeat_core_import']:
            suggestions.append("Add SecureNetworkImage to existing artbeat_core import")
        else:
            suggestions.append("Add: import 'package:artbeat_core/artbeat_core.dart';")
    
    # Suggest replacement pattern
    suggestions.append("Replace Image.network( with SecureNetworkImage(imageUrl:")
    suggestions.append("Replace errorBuilder: parameter with errorWidget:")
    
    return suggestions

def main():
    if len(sys.argv) > 1:
        root_dir = sys.argv[1]
    else:
        root_dir = '/Users/kristybock/artbeat'
    
    print(f"🔍 Analyzing Image.network usage in {root_dir}")
    print("=" * 60)
    
    dart_files = find_dart_files(root_dir)
    print(f"Found {len(dart_files)} Dart files")
    
    files_with_image_network = []
    total_matches = 0
    
    for file_path in dart_files:
        analysis = analyze_image_network_usage(file_path)
        if analysis:
            files_with_image_network.append(analysis)
            total_matches += analysis['matches']
    
    print(f"\n📊 Summary:")
    print(f"Files with Image.network: {len(files_with_image_network)}")
    print(f"Total Image.network calls: {total_matches}")
    
    print(f"\n📋 Files that need migration:")
    print("=" * 60)
    
    for analysis in files_with_image_network:
        rel_path = analysis['file'].replace(root_dir, '').lstrip('/')
        print(f"\n📄 {rel_path}")
        print(f"   Image.network calls: {analysis['matches']}")
        print(f"   Has SecureNetworkImage import: {analysis['has_secure_import']}")
        print(f"   Has artbeat_core import: {analysis['has_artbeat_core_import']}")
        
        suggestions = suggest_migration(analysis)
        for i, suggestion in enumerate(suggestions, 1):
            print(f"   {i}. {suggestion}")
    
    # Priority files (likely to have Firebase Storage URLs)
    priority_patterns = [
        'artwork',
        'artist',
        'profile',
        'capture',
        'art_walk',
        'events'
    ]
    
    print(f"\n🔥 Priority files (likely Firebase Storage):")
    print("=" * 60)
    
    priority_files = []
    for analysis in files_with_image_network:
        rel_path = analysis['file'].replace(root_dir, '').lstrip('/')
        if any(pattern in rel_path.lower() for pattern in priority_patterns):
            priority_files.append((rel_path, analysis['matches']))
    
    priority_files.sort(key=lambda x: x[1], reverse=True)
    
    for rel_path, matches in priority_files:
        print(f"   {rel_path} ({matches} calls)")
    
    print(f"\n✅ Migration completed for core widgets:")
    completed_files = [
        'packages/artbeat_core/lib/src/widgets/user_avatar.dart',
        'packages/artbeat_core/lib/src/widgets/featured_content_row_widget.dart',
        'packages/artbeat_artwork/lib/src/widgets/local_artwork_row_widget.dart',
        'packages/artbeat_artwork/lib/src/screens/artwork_detail_screen.dart'
    ]
    
    for file in completed_files:
        print(f"   ✓ {file}")
    
    print(f"\n🚀 Next steps:")
    print("1. Update priority files listed above")
    print("2. Test the app to ensure SecureNetworkImage is working")
    print("3. Monitor debug logs for 403 error handling")
    print("4. Gradually migrate remaining files")

if __name__ == "__main__":
    main()