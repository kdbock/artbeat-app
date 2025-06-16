# ARTbeat To-Do List

## app security
1. ✅ Check for API, Keys, and other security issues in the app. Resolve any issues found.
   - ✅ Removed hardcoded API keys from all module initialization files
   - ✅ Implemented secure ConfigService for managing sensitive configuration
   - ✅ Added comprehensive security documentation (SECURITY.md)
   - ✅ Updated .gitignore for sensitive files
   - ✅ Fixed secure directions service implementation
   - ✅ Secured test configurations
   - ✅ Added proper environment variable handling

## administrator
- [x] Create admin module structure with secure architecture
- [x] Create admin login page with secure authentication
- [x] Create admin logout functionality
- [x] Implement role-based access control (RBAC)
- [x] Create admin dashboard with access to all data (users, artists, artwork, etc.)
- [x] Add ability to view and manage users in the admin dashboard
- [x] Add ability to edit users' roles from the admin dashboard
- [x] Add ability to delete users from the admin dashboard
- [x] Add ability to view user's activity history from the admin dashboard
- [x] Add ability to view user's payment history from the admin dashboard

Remaining Administrator Tasks:
- [] Implement two-factor authentication for admin accounts
- [] Add comprehensive activity logging
- [] Add admin audit trail functionality
- [] Implement automated security scanning
- [] Set up regular security audits and penetration testing
- [] Create backup and recovery procedures
- [] Set up monitoring and alerting for suspicious activities
- [] Add ability to view user's messages from the admin dashboard
- [] Add ability to view user's notifications from the admin dashboard
- [] Add ability to view user's reviews from the admin dashboard
- [] Add ability to view user's purchases from the admin dashboard
- [] Add ability to view user's subscriptions from the admin dashboard
- [] Add ability to view user's donations from the admin dashboard
- [] Add ability to view user's feedback from the admin dashboard
- [] Add ability to view user's support requests from the admin dashboard
- [] Add ability to view user's reports from the admin dashboard
- [] Add ability to view user's analytics from the admin dashboard
- [] Add ability to view user's settings from the admin dashboard
- [] Add ability to view user's privacy policy from the admin dashboard
- [] Add ability to view user's terms of service from the admin dashboard
- [] Add ability to view user's cookies policy from the admin dashboard
- [] Add ability to view user's data protection policy from the admin dashboard
- [] Add ability to view user's intellectual property rights policy from the admin dashboard
- [] Add ability to view user's refund policy from the admin dashboard
- [] Add ability to view user's shipping and handling policy from the admin dashboard
- []
## Visual changes:
1. Apply artbeat theme system (/Users/kristybock/artbeat/packages/artbeat_core/lib/theme) to all screens, widgets, navigations, headers and footers:
- [] `artbeat_core` 
- [] `artbeat_auth` 
      - the auth module only shows welcome user name and sign out button that doesn't work. 
- [] `artbeat_profile` 
     - fix profile suite page styling. It looks entirely too much like Facebook and Instagram.
- [] `artbeat_artwork` 
     - rework upload screen, there are more mediums and types of art that will need to be represented. The format looks clunky and dated. 
     - resolve errors: "Note: /Users/kristybock/.pub-cache/hosted/pub.dev/google_mlkit_commons-0.6.1/android/src/main/java/com/google_mlkit_commons/InputImageConverter.java uses unchecked or unsafe operations.
     Note: /Users/kristybock/.pub-cache/hosted/pub.dev/google_mlkit_text_recognition-0.11.0/android/src/main/java/com/google_mlkit_text_recognition/TextRecognizer.java uses unchecked or unsafe operations.
- [] `artbeat_artist` 
     - add Artist "start" page that walks a user to the process of creating an artist account.
- [] `artbeat_art_walk` 
     - The map isn't working correctly
     - the zip code feature isn't working
     - create module entry screen that walks a user through creating an artwalk
- [] `artbeat_community`
     - Fix the feed home screen [There are multile permissions errors on the feed screen.] 
     - resolve permissions errors for all screens
- [] `artbeat_messaging` 
- [] `artbeat_settings` 

