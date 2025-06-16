# Test File Cleanup ToDo

## Completed (June 15, 2025)
- [x] Created documentation of test file issues in `/docs/TEST_CLEANUP_REPORT_JUNE_2025.md`
- [x] Created backup script (`/scripts/clean_test_files.sh`)
- [x] Created fix script for artist profile service test (`/scripts/fix_artist_profile_test.sh`)
- [x] Checked art walk service test for type compatibility issues (already fixed)

## To Do
- [x] Run the cleanup script to create backups
- [x] Run the fix script to update the artist profile service test
- [x] Run tests to verify fixed implementations
- [ ] Update the all_tests.dart files to reference only working test files
- [ ] Document the changes to the team

## Notes
1. The reported type compatibility issues in art_walk service test are already fixed
2. No need to fix subscription service tests as only one exists
3. No chat service test exists yet
4. Artist profile service test has implementation issues that are fixed in the script
