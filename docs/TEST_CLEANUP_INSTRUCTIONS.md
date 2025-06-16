# Test File Cleanup Instructions

## Background
We've identified some issues with test files in the ARTbeat project:
1. Type compatibility issues
2. Incomplete implementations
3. Redundant test files

## Cleanup Instructions

### 1. Create Backups
Run the cleanup script to create backups of all files before making changes:
```bash
cd /Users/kristybock/artbeat
./scripts/clean_test_files.sh
```

### 2. Fix Artist Profile Service Test
Run the fix script to create and implement a fixed version of the artist profile service test:
```bash
cd /Users/kristybock/artbeat
./scripts/fix_artist_profile_test.sh
```

After running the script, review the fixed version and replace the original:
```bash
mv "/Users/kristybock/artbeat/packages/artbeat_artist/test/services/testable_artist_profile_service_fixed.dart" "/Users/kristybock/artbeat/packages/artbeat_artist/test/services/testable_artist_profile_service_test.dart"
```

### 3. Run Tests to Verify
Run the tests to make sure they pass with the fixed implementation:
```bash
cd /Users/kristybock/artbeat
flutter test packages/artbeat_artist/test/services/testable_artist_profile_service_test.dart
```

### 4. Review Documentation
Review the comprehensive documentation in `/docs/TEST_CLEANUP_REPORT_JUNE_2025.md` for details on all issues and solutions.

## Conclusion
These steps should address the reported test file issues. The documentation provides more details on each problem and its solution.

If you encounter any issues during the cleanup process, please report them in the project tracking system.
