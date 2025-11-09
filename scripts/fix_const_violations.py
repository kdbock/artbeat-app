#!/usr/bin/env python3
"""
Fix const expression violations in Dart files
Removes const from const declarations that contain .tr() calls
"""

import re
import sys
from pathlib import Path

def find_const_block_for_tr(lines: list, tr_line_idx: int) -> int:
    """Find the line with const that starts the block containing the .tr() call"""
    # Look backward from the .tr() line to find the opening const
    paren_depth = 0
    for i in range(tr_line_idx, -1, -1):
        line = lines[i]
        
        # Count closing parens to opening parens going backwards
        for char in reversed(line):
            if char == ')':
                paren_depth += 1
            elif char == '(':
                paren_depth -= 1
                if paren_depth == -1:  # Found the opening paren
                    # This line should have 'const' somewhere before the (
                    if 'const' in line and '(' in line:
                        return i
                    # Otherwise keep looking
        
        # If this line has const and an opening paren, check if it matches
        if 'const ' in line and '(' in line:
            paren_depth = line.count('(') - line.count(')')
            if paren_depth > 0:
                return i
    
    return -1

def fix_const_violations_in_file(file_path: str) -> int:
    """Fix const violations in a single file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        fixed_count = 0
        
        lines = content.split('\n')
        fixed_lines_set = set()  # Track which lines we've already fixed
        
        # First pass: Find all .tr() calls and fix their const containers
        for i, line in enumerate(lines):
            if '.tr()' not in line or i in fixed_lines_set:
                continue
            
            # Check for const in the same line
            if 'const ' in line and '.tr()' in line:
                # Single-line const with .tr()
                if re.search(r'const\s+\w+\(.*\.tr\(\).*\)', line):
                    lines[i] = re.sub(r'const\s+', '', line, count=1)
                    fixed_count += 1
                    fixed_lines_set.add(i)
                    continue
            
            # Multi-line case: find the const block that this .tr() belongs to
            const_line_idx = find_const_block_for_tr(lines, i)
            if const_line_idx >= 0 and const_line_idx not in fixed_lines_set:
                # Remove const from that line
                lines[const_line_idx] = re.sub(r'const\s+', '', lines[const_line_idx], count=1)
                fixed_count += 1
                fixed_lines_set.add(const_line_idx)
        
        # Second pass: Handle const IconButton, etc. with .tr() in label/tooltip
        for i, line in enumerate(lines):
            if i in fixed_lines_set:
                continue
            
            patterns = [
                ('label: const Text(', 'label: Text('),
                ('tooltip: const Text(', 'tooltip: Text('),
                ('title: const Text(', 'title: Text('),
                ('hint: const Text(', 'hint: Text('),
                ('content: const Text(', 'content: Text('),
            ]
            
            for pattern, replacement in patterns:
                if pattern in line and '.tr()' in line:
                    lines[i] = line.replace(pattern, replacement, 1)
                    fixed_count += 1
                    break
        
        content = '\n'.join(lines)
        
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            return fixed_count
        
        return 0
    
    except Exception as e:
        print(f"Error fixing {file_path}: {e}")
        return 0

def main():
    if len(sys.argv) < 2:
        print("Usage: python fix_const_violations.py <package_name>")
        print("\nExample:")
        print("  python fix_const_violations.py artbeat_messaging")
        sys.exit(1)
    
    project_root = Path(__file__).parent.parent
    
    for package in sys.argv[1:]:
        package_path = project_root / 'packages' / package / 'lib' / 'src' / 'screens'
        
        if not package_path.exists():
            print(f"Package path not found: {package_path}")
            continue
        
        print(f"\nFixing const violations in {package}...")
        
        dart_files = list(package_path.glob('*.dart'))
        total_fixed = 0
        
        for dart_file in sorted(dart_files):
            fixed = fix_const_violations_in_file(str(dart_file))
            if fixed > 0:
                print(f"  ✓ {dart_file.name}: {fixed} violations fixed")
                total_fixed += fixed
        
        if total_fixed == 0:
            print("  - No const violations found")
        else:
            print(f"\n✓ Fixed {total_fixed} const violations in {package}")

if __name__ == '__main__':
    main()
