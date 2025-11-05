11/4/2025 - BUILD CONFIGURATION & VERSION UPDATE
✅ Updated app versions to 2.3.6+68
   - pubspec.yaml: 2.3.5+67 → 2.3.6+68
   - android/app/build.gradle.kts: versionCode 67 → 68, versionName 2.3.5 → 2.3.6
✅ Fixed Xcode Cloud build configuration
   - Created ios/ci_scripts/ci_post_clone.sh for Flutter dependency setup
   - Created ios/ci_scripts/ci_pre_xcodebuild.sh for Flutter file generation
   - See ios/XCODE_CLOUD_SETUP.md for complete Xcode Cloud configuration guide

11/4/2025 - APP STORE REJECTION RESPONSE
COMPLETED FIXES (5/7 CODE-RELATED ISSUES):
✅ Guideline 2.1 - Fixed: Sign in with Apple crash 
   - null identity token validation
   - Location: packages/artbeat_auth/lib/src/services/auth_service.dart:299-310

✅ Guideline 2.1 - Fixed: App Completeness 
   - TODOs completed (streaks, engagement, badges)
   - "Coming Soon" replaced with functional tabs
   - Location: packages/artbeat_profile/lib/src/screens/profile_view_screen.dart
   - Location: packages/artbeat_admin/lib/src/screens/unified_admin_dashboard.dart

✅ Guideline 2.3.2 - Fixed: IAP Metadata 
   - All 18 products with unique display names/descriptions
   - Location: packages/artbeat_ads/IAP_SKU_LIST.md

✅ Guideline 1.2 - Fixed: User-Generated Content Safety
   - Block User button on profile screens
   - Location: packages/artbeat_profile/lib/src/screens/profile_view_screen.dart:189-213, 372-429

⏳ REMAINING (2 ITEMS):
- Guideline 2.3.2: Create 18 unique promotional images (design task, not code)
  → See IMPLEMENTATION_GUIDES.md - Guide 1 for detailed promotional image specifications
- Guideline 2.1: Verify IAP products in App Store Connect sandbox (configuration, not code)
  → See IMPLEMENTATION_GUIDES.md - Guide 2 for complete sandbox verification instructions

📄 See APP_STORE_RESPONSE.md for detailed explanation of all changes
📄 See IMPLEMENTATION_GUIDES.md for step-by-step guides to complete remaining items

All code changes compile successfully. No errors. ✓

11/3/2025
- Cleared crashanalytics for android stripe crash (again)
- Working on Apple Production Rejection issues.

Hello,

Thank you for your resubmission. Upon further review, we identified additional issues that need your attention. See below for more information.

If you have any questions, we are here to help. Reply to this message in App Store Connect and let us know.


Review Environment

Submission ID: 6775f217-d6e0-4a49-8024-608def580762
Review date: November 03, 2025
Version reviewed: 1.0


Guideline 2.1 - Performance - App Completeness
Issue Description

The app exhibited one or more bugs that would negatively impact users.

Bug description: the app displayed an error upon Sign in with Apple.

Review device details:

- Device type: iPhone 17 Pro Max 
- OS version: iOS 26.0.1

Next Steps

Test the app on supported devices to identify and resolve bugs and stability issues before submitting for review.

If the bug cannot be reproduced, try the following:

- For new apps, uninstall all previous versions of the app from a device, then install and follow the steps to reproduce.
- For app updates, install the new version as an update to the previous version, then follow the steps to reproduce.

Resources

- For information about testing apps and preparing them for review, see Testing a Release Build.
- To learn about troubleshooting networking issues, see Networking Overview.



Guideline 2.3.2 - Performance - Accurate Metadata

We noticed that the display names and descriptions for your promoted in-app purchase products and/or win back offers, Small Banner - 3 Months, Small Banner - 1 Month, Big Square - 1 Week, Big Square - 3 Months, Small Banner - 1 Week, and Big Square - 1 Month, are the same, which makes it hard for users to identify what they are purchasing from the App Store.

Next Steps

To resolve this issue, please revise the display names or descriptions for your promoted in-app purchase products and win back offers to ensure each individual metadata item is unique. 

Please note that display names for promoted in-app purchases can be up to 30 characters long, while descriptions can be up to 45 characters long. 

If you have no future plans on promoting this in-app purchase product, you can delete the associated promotional image in App Store Connect. 

Resources

- Learn how to view and edit in-app purchase information in App Store Connect.
- Discover more best practices for promoting your in-app purchases on the App Store.


Guideline 2.3.2 - Performance - Accurate Metadata

We noticed that your promotional image to be displayed on the App Store does not sufficiently represent the associated promoted in-app purchase and/or win back offer. Specifically, we found the following issue with your promotional image:

 – Your promotional image is the same as your app’s icon.

 – You submitted duplicate or identical promotional images for different promoted in-app purchase products and/or win back offers. 

Next Steps

To resolve this issue, please revise your promotional image to ensure it is unique and accurately represents the associated promoted in-app purchase and/or win back offer. 

If you have no future plans on promoting this in-app purchase product, you can delete the associated promotional image in App Store Connect. 

Resources

- Learn how to view and edit in-app purchase information in App Store Connect.
- Discover more best practices for promoting your in-app purchases on the App Store.


Guideline 1.2 - Safety - User-Generated Content

We found in our review that your app includes user-generated content but does not have all the required precautions. Apps with user-generated content must take specific steps to moderate content and prevent abusive behavior.

Next Steps

To resolve this issue, please revise your app to implement the following precautions:

- A mechanism for users to block abusive users


Guideline 2.1 - Information Needed

We have started the review of your app, but we are not able to continue because we cannot locate the in-app purchases within your app at this time.

Next Steps

To help us proceed with the review of your app, please reply to this message providing the steps for locating the in-app purchases in your app.

Note that in-app purchases are reviewed in an Apple-provided sandbox environment. Make sure they have been appropriately configured for review in the Apple-provided sandbox environment.

If you are restricting access to in-app purchases based on factors such as storefront or device configurations, please include this information in your reply along with steps to enable the in-app purchases for our review. 

Additionally, note that the Account Holder must accept the Paid Apps Agreement in the Business section of App Store Connect before paid in-app purchases will function.

Resources

- Learn more about offering in-app purchases. 
- Learn more about testing in sandbox.


Support
- Reply to this message in your preferred language if you need assistance. If you need additional support, use the Contact Us module.
- Consult with fellow developers and Apple engineers on the Apple Developer Forums.
- Request an App Review Appointment at Meet with Apple to discuss your app's review. Appointments subject to availability during your local business hours on Tuesdays and Thursdays.
- Provide feedback on this message and your review experience by completing a short survey.

Request a phone call from App Review

At your request, we can arrange for an Apple Representative to call you within the next three to five business days to discuss your App Review issue.

Request a call to discuss your app's review