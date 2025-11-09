#!/usr/bin/env python3
"""
Batch Translation Extractor for ArtBeat Phase 1 English Translation
Extracts hardcoded strings from Dart screen files and generates translation keys.
"""

import os
import re
import json
import sys
from pathlib import Path
from typing import Dict, List, Set, Tuple
from dataclasses import dataclass, field

@dataclass
class TranslationEntry:
    key: str
    value: str
    file: str
    line: int

@dataclass
class ScreenFile:
    path: str
    package: str
    screen_name: str
    strings: List[TranslationEntry] = field(default_factory=list)

class TranslationExtractor:
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.assets_dir = self.project_root / "assets" / "translations"
        self.language_files = {}
        self.existing_keys: Set[str] = set()
        self.new_entries: Dict[str, Dict[str, str]] = {
            'en': {}, 'es': {}, 'fr': {}, 'de': {}, 'pt': {}, 'zh': {}
        }
        self.load_language_files()
        
    def load_language_files(self):
        """Load existing translation files"""
        languages = ['en', 'es', 'fr', 'de', 'pt', 'zh']
        for lang in languages:
            file_path = self.assets_dir / f"{lang}.json"
            if file_path.exists():
                with open(file_path, 'r', encoding='utf-8') as f:
                    self.language_files[lang] = json.load(f)
                    self.existing_keys.update(self.language_files[lang].keys())
            else:
                self.language_files[lang] = {}
    
    def extract_strings_from_file(self, file_path: str) -> List[Tuple[str, int]]:
        """Extract hardcoded strings from a Dart file"""
        strings = []
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                lines = f.readlines()
            
            for line_num, line in enumerate(lines, 1):
                # Skip imports and comments
                if line.strip().startswith('import ') or line.strip().startswith('//'):
                    continue
                
                # Match Text('...'), const Text('...'), etc.
                text_patterns = [
                    r"Text\('([^']+)'\)",
                    r'Text\("([^"]+)"\)',
                    r"const Text\('([^']+)'\)",
                    r'const Text\("([^"]+)"\)',
                    r"label:\s*(?:const\s+)?Text\('([^']+)'\)",
                    r'label:\s*(?:const\s+)?Text\("([^"]+)"\)',
                    r"title:\s*'([^']+)'",
                    r'title:\s*"([^"]+)"',
                    r"'([^']+)' // string constant",
                ]
                
                for pattern in text_patterns:
                    matches = re.finditer(pattern, line)
                    for match in matches:
                        string_value = match.group(1)
                        # Filter out very short strings and common variables
                        if len(string_value) > 2 and not string_value.startswith('$'):
                            strings.append((string_value, line_num))
        except Exception as e:
            print(f"Error reading {file_path}: {e}")
        
        return strings
    
    def generate_key(self, package: str, screen: str, string: str, index: int) -> str:
        """Generate translation key following naming convention"""
        # Clean up package name (remove 'artbeat_' prefix)
        pkg = package.replace('artbeat_', '')
        
        # Clean up screen name (remove '_screen.dart')
        scr = screen.replace('_screen.dart', '').replace('.dart', '')
        
        # Create component/type from string content
        string_lower = string.lower()
        
        # Detect type of string
        if any(word in string_lower for word in ['error', 'failed', 'invalid']):
            component = 'error'
        elif any(word in string_lower for word in ['success', 'saved', 'updated']):
            component = 'success'
        elif any(word in string_lower for word in ['loading', 'loading...', 'please wait']):
            component = 'loading'
        elif any(word in string_lower for word in ['title', 'welcome', 'hello']):
            component = 'title'
        elif any(word in string_lower for word in ['label', 'name', 'email', 'password']):
            component = 'label'
        elif any(word in string_lower for word in ['button', 'click', 'press', 'tap']):
            component = 'button'
        elif any(word in string_lower for word in ['hint', 'search', 'enter', 'type']):
            component = 'hint'
        elif any(word in string_lower for word in ['message', 'description', 'info']):
            component = 'message'
        else:
            component = 'text'
        
        # Create a descriptive suffix from the string
        words = re.sub(r'[^a-z0-9\s]', '', string_lower).split()[:3]
        suffix = '_'.join(words) if words else f'item_{index}'
        
        # Build key
        key = f"{pkg}_{scr}_{component}_{suffix}"
        
        # Limit key length and clean up
        key = re.sub(r'_+', '_', key)  # Remove multiple underscores
        key = key.rstrip('_')  # Remove trailing underscores
        
        # Ensure uniqueness by adding index if needed
        if key in self.existing_keys or key in self.new_entries['en']:
            key = f"{key}_{index}"
        
        return key
    
    def process_package(self, package_name: str) -> Dict[str, List[str]]:
        """Process all screen files in a package"""
        package_path = self.project_root / 'packages' / package_name / 'lib' / 'src' / 'screens'
        
        if not package_path.exists():
            print(f"Package path not found: {package_path}")
            return {}
        
        results = {}
        dart_files = list(package_path.glob('*.dart'))
        
        print(f"\nProcessing {package_name}: {len(dart_files)} files")
        
        for dart_file in dart_files:
            screen_name = dart_file.name
            print(f"  - {screen_name}", end=' ')
            
            strings = self.extract_strings_from_file(str(dart_file))
            new_keys = []
            
            for idx, (string_value, line_num) in enumerate(strings, 1):
                key = self.generate_key(package_name, screen_name, string_value, idx)
                
                # Check if key already exists
                if key not in self.existing_keys and key not in self.new_entries['en']:
                    self.new_entries['en'][key] = string_value
                    new_keys.append(key)
                    
                    # Add placeholder for other languages
                    for lang in ['es', 'fr', 'de', 'pt', 'zh']:
                        self.new_entries[lang][key] = f"[{string_value}]"
            
            print(f"({len(new_keys)} new strings)")
            results[screen_name] = new_keys
        
        return results
    
    def save_language_files(self):
        """Save updated translation files"""
        languages = {
            'en': self.new_entries['en'],
            'es': self.new_entries['es'],
            'fr': self.new_entries['fr'],
            'de': self.new_entries['de'],
            'pt': self.new_entries['pt'],
            'zh': self.new_entries['zh'],
        }
        
        for lang, new_keys in languages.items():
            file_path = self.assets_dir / f"{lang}.json"
            
            # Load existing
            if file_path.exists():
                with open(file_path, 'r', encoding='utf-8') as f:
                    existing = json.load(f)
            else:
                existing = {}
            
            # Merge new keys
            existing.update(new_keys)
            
            # Save with pretty formatting
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(existing, f, ensure_ascii=False, indent=2, sort_keys=True)
            
            print(f"✓ Updated {lang}.json ({len(new_keys)} new keys)")
    
    def generate_report(self, package_name: str, results: Dict[str, List[str]]):
        """Generate a report of extracted strings"""
        total_new = sum(len(keys) for keys in results.values())
        
        print(f"\n{'='*60}")
        print(f"EXTRACTION REPORT: {package_name}")
        print(f"{'='*60}")
        print(f"Total screens processed: {len(results)}")
        print(f"Total new strings found: {total_new}")
        print(f"\nBreakdown:")
        for screen, keys in sorted(results.items()):
            print(f"  {screen}: {len(keys)} strings")
        print(f"{'='*60}\n")

def main():
    if len(sys.argv) < 2:
        print("Usage: python batch_translation_extractor.py <package_name> [package_name2 ...]")
        print("\nExample:")
        print("  python batch_translation_extractor.py artbeat_messaging")
        print("  python batch_translation_extractor.py artbeat_artist artbeat_art_walk")
        sys.exit(1)
    
    project_root = str(Path(__file__).parent.parent)
    extractor = TranslationExtractor(project_root)
    
    for package in sys.argv[1:]:
        results = extractor.process_package(package)
        extractor.generate_report(package, results)
    
    print("Saving updated language files...")
    extractor.save_language_files()
    
    total_new = sum(len(keys) for keys in extractor.new_entries['en'].items())
    print(f"\n✓ Successfully added {len(extractor.new_entries['en'])} new translation keys")
    print(f"  - All 6 language files updated")

if __name__ == '__main__':
    main()
