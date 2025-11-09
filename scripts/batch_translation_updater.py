#!/usr/bin/env python3
"""
Batch Translation Updater for ArtBeat
Updates Dart screen files to use .tr() for translation keys
"""

import os
import re
import json
import sys
from pathlib import Path
from typing import Dict, List, Set, Tuple

class TranslationUpdater:
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.assets_dir = self.project_root / "assets" / "translations"
        self.translation_keys = self.load_translation_keys()
        self.updated_files = []
        
    def load_translation_keys(self) -> Dict[str, str]:
        """Load English translation keys"""
        en_file = self.assets_dir / "en.json"
        if en_file.exists():
            with open(en_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        return {}
    
    def find_matching_key(self, string_value: str) -> str:
        """Find the translation key for a given string value"""
        for key, value in self.translation_keys.items():
            if value.lower() == string_value.lower():
                return key
        return None
    
    def update_file(self, file_path: str, package: str) -> int:
        """Update a single file with .tr() calls"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            original_content = content
            updated_count = 0
            
            # Check if easy_localization is already imported
            if 'package:easy_localization/easy_localization.dart' not in content:
                # Add import right after the first package import or after material import
                lines = content.split('\n')
                import_added = False
                
                for i, line in enumerate(lines):
                    if line.startswith('import \'package:') and not import_added:
                        # Find the end of this import line
                        if i + 1 < len(lines) and not lines[i + 1].startswith('    show'):
                            # Single line import, add after it
                            lines.insert(i + 1, 'import \'package:easy_localization/easy_localization.dart\';')
                            import_added = True
                            break
                        elif i + 1 < len(lines) and lines[i + 1].startswith('    show'):
                            # Multi-line import, find the closing ;
                            j = i + 1
                            while j < len(lines) and not lines[j].rstrip().endswith(';'):
                                j += 1
                            if j < len(lines):
                                lines.insert(j + 1, 'import \'package:easy_localization/easy_localization.dart\';')
                                import_added = True
                                break
                
                content = '\n'.join(lines)
            
            # Pattern 1: Text('string')
            def replace_text_single_quote(match):
                nonlocal updated_count
                string = match.group(1)
                key = self.find_matching_key(string)
                if key:
                    updated_count += 1
                    return f"Text('{key}'.tr())"
                return match.group(0)
            
            content = re.sub(r"Text\('([^']+)'\)", replace_text_single_quote, content)
            
            # Pattern 2: Text("string")
            def replace_text_double_quote(match):
                nonlocal updated_count
                string = match.group(1)
                key = self.find_matching_key(string)
                if key:
                    updated_count += 1
                    return f'Text("{key}".tr())'
                return match.group(0)
            
            content = re.sub(r'Text\("([^"]+)"\)', replace_text_double_quote, content)
            
            # Pattern 3: label: const Text('string') - must remove const
            content = re.sub(
                r"label:\s*const Text\('([^']+)'\)",
                lambda m: f"label: Text('{self.find_matching_key(m.group(1)) or m.group(1)}'.tr())" if self.find_matching_key(m.group(1)) else m.group(0),
                content
            )
            
            # Pattern 4: label: const Text("string") - must remove const
            content = re.sub(
                r'label:\s*const Text\("([^"]+)"\)',
                lambda m: f'label: Text("{self.find_matching_key(m.group(1)) or m.group(1)}".tr())' if self.find_matching_key(m.group(1)) else m.group(0),
                content
            )
            
            # Pattern 5: const Text('string') - must remove const
            def replace_const_text_single(match):
                nonlocal updated_count
                string = match.group(1)
                key = self.find_matching_key(string)
                if key:
                    updated_count += 1
                    return f"Text('{key}'.tr())"
                return match.group(0)
            
            content = re.sub(r"const Text\('([^']+)'\)", replace_const_text_single, content)
            
            # Pattern 6: const Text("string") - must remove const
            def replace_const_text_double(match):
                nonlocal updated_count
                string = match.group(1)
                key = self.find_matching_key(string)
                if key:
                    updated_count += 1
                    return f'Text("{key}".tr())'
                return match.group(0)
            
            content = re.sub(r'const Text\("([^"]+)"\)', replace_const_text_double, content)
            
            # Remove remaining const keywords from lines with .tr() that are const contexts
            lines = content.split('\n')
            for i, line in enumerate(lines):
                if '.tr()' in line:
                    # Check if this line has const Text, const Icon, etc. with .tr()
                    if 'const Text(' in line and '.tr()' in line:
                        lines[i] = line.replace('const Text(', 'Text(', 1)
                    if 'const Icon(' in line and '.tr()' in line:
                        lines[i] = lines[i].replace('const Icon(', 'Icon(', 1)
                    # For label parameters
                    if 'label: const' in line and '.tr()' in line:
                        lines[i] = lines[i].replace('label: const ', 'label: ', 1)
            
            content = '\n'.join(lines)
            
            # Only save if changes were made
            if content != original_content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                self.updated_files.append((file_path, updated_count))
                return updated_count
            
            return 0
        
        except Exception as e:
            print(f"  ✗ Error updating {Path(file_path).name}: {e}")
            return 0
    
    def process_package(self, package_name: str) -> int:
        """Process all screen files in a package"""
        package_path = self.project_root / 'packages' / package_name / 'lib' / 'src' / 'screens'
        
        if not package_path.exists():
            print(f"Package path not found: {package_path}")
            return 0
        
        dart_files = list(package_path.glob('*.dart'))
        total_updated = 0
        
        print(f"\nUpdating {package_name}: {len(dart_files)} files")
        
        for dart_file in dart_files:
            screen_name = dart_file.name
            updated = self.update_file(str(dart_file), package_name)
            if updated > 0:
                print(f"  ✓ {screen_name}: {updated} strings updated")
                total_updated += updated
            else:
                print(f"  - {screen_name}: No updates")
        
        return total_updated
    
    def generate_report(self):
        """Generate a report of updated files"""
        print(f"\n{'='*60}")
        print(f"UPDATE REPORT")
        print(f"{'='*60}")
        print(f"Total files updated: {len(self.updated_files)}")
        print(f"Total strings converted to .tr(): {sum(count for _, count in self.updated_files)}")
        
        if self.updated_files:
            print(f"\nUpdated files:")
            for file_path, count in self.updated_files:
                relative_path = Path(file_path).relative_to(self.project_root)
                print(f"  {relative_path}: {count} strings")
        
        print(f"{'='*60}\n")

def main():
    if len(sys.argv) < 2:
        print("Usage: python batch_translation_updater.py <package_name> [package_name2 ...]")
        print("\nExample:")
        print("  python batch_translation_updater.py artbeat_messaging")
        sys.exit(1)
    
    project_root = str(Path(__file__).parent.parent)
    updater = TranslationUpdater(project_root)
    
    total_all = 0
    for package in sys.argv[1:]:
        total = updater.process_package(package)
        total_all += total
    
    updater.generate_report()
    print(f"✓ Successfully updated {total_all} strings with .tr() calls")

if __name__ == '__main__':
    main()
