# Google Play Data Safety Declaration for ARTbeat

## Overview

This document outlines all user data collection and sharing for ARTbeat v1.1.0 (Build 34) to ensure compliance with Google Play's Data Safety requirements.

## Data Collection Summary

### Personal Info

**Data Type: Name**

- ✅ Collected: YES
- Purpose: App functionality (user profiles, display names)
- Sharing: NO
- Optional: NO (required for account creation)

**Data Type: Email address**

- ✅ Collected: YES
- Purpose: App functionality (authentication, account management)
- Sharing: NO
- Optional: NO (required for account creation)

**Data Type: User IDs**

- ✅ Collected: YES
- Purpose: App functionality (user identification, data association)
- Sharing: NO
- Optional: NO (automatically generated)

### Financial Info

**Data Type: Payment info**

- ✅ Collected: YES
- Purpose: App functionality (subscription payments, commission tracking)
- Sharing: YES (with Stripe payment processor)
- Optional: YES (only for paid subscriptions)

### Location

**Data Type: Approximate location**

- ✅ Collected: YES
- Purpose: App functionality (local content discovery, art walks)
- Sharing: NO
- Optional: YES (can be disabled in settings)

**Data Type: Precise location**

- ✅ Collected: YES
- Purpose: App functionality (art walk GPS tracking, location-based features)
- Sharing: NO
- Optional: YES (can be disabled in settings)

### Photos and videos

**Data Type: Photos**

- ✅ Collected: YES
- Purpose: App functionality (profile pictures, artwork uploads, user-generated content)
- Sharing: NO
- Optional: YES (can use default avatars)

### Files and docs

**Data Type: Files and docs**

- ✅ Collected: YES
- Purpose: App functionality (artwork files, profile assets)
- Sharing: NO
- Optional: YES (for artwork uploads only)

### Messages

**Data Type: Messages**

- ✅ Collected: YES
- Purpose: App functionality (in-app messaging, comments, social interactions)
- Sharing: NO
- Optional: YES (social features only)

### App activity

**Data Type: App interactions**

- ✅ Collected: YES
- Purpose: Analytics (user engagement, feature usage)
- Sharing: NO
- Optional: NO (essential for app improvement)

**Data Type: In-app search history**

- ✅ Collected: YES
- Purpose: App functionality (search suggestions, personalization)
- Sharing: NO
- Optional: NO (improves search experience)

### App info and performance

**Data Type: Crash logs**

- ✅ Collected: YES
- Purpose: App functionality (bug fixes, stability improvements)
- Sharing: NO
- Optional: NO (automatic via Firebase Crashlytics)

**Data Type: Diagnostics**

- ✅ Collected: YES
- Purpose: App functionality (performance monitoring)
- Sharing: NO
- Optional: NO (automatic via Firebase Performance)

### Device or other IDs

**Data Type: Device or other IDs**

- ✅ Collected: YES
- Purpose: Analytics, App functionality (device identification, push notifications)
- Sharing: NO
- Optional: NO (required for notifications and analytics)

## Data Security Measures

### Data in transit

- ✅ Your data is encrypted in transit

### Data at rest

- ✅ Your data is encrypted at rest

### Data deletion

- ✅ You can request that data be deleted

## Third-Party Data Sharing

### Firebase (Google)

- **Data shared**: User analytics, crash reports, performance data
- **Purpose**: App functionality and analytics
- **Data types**: Device IDs, app interactions, diagnostics

### Stripe

- **Data shared**: Payment information, email addresses
- **Purpose**: Payment processing
- **Data types**: Financial info, email addresses

### Google Maps

- **Data shared**: Location data
- **Purpose**: Map functionality for Art Walks
- **Data types**: Precise location, approximate location

## Data Retention

- **User account data**: Retained until account deletion
- **Analytics data**: Retained for 26 months (Firebase default)
- **Payment data**: Retained per Stripe's data retention policy
- **Location data**: Retained until user disables location services or deletes account
- **User-generated content**: Retained until user deletes or account is deleted

## User Controls

- Users can delete their account and associated data
- Users can disable location tracking
- Users can opt out of analytics (where legally required)
- Users can manage notification preferences
- Users can delete their uploaded content

## Compliance Notes

- All data collection is disclosed to users
- Privacy policy available at: artbeat.app/privacy
- Terms of service available at: artbeat.app/terms
- Data processing complies with GDPR and CCPA requirements

## Recommended Google Play Data Safety Form Answers

### Data collection and security

- **Does your app collect or share any of the required user data types?**: YES

### Data types collected

Select the following categories and data types:

**Personal info**

- Name ✅
- Email address ✅
- User IDs ✅

**Financial info**

- Payment info ✅

**Location**

- Approximate location ✅
- Precise location ✅

**Photos and videos**

- Photos ✅

**Files and docs**

- Files and docs ✅

**Messages**

- Messages ✅

**App activity**

- App interactions ✅
- In-app search history ✅

**App info and performance**

- Crash logs ✅
- Diagnostics ✅

**Device or other IDs**

- Device or other IDs ✅

### For each data type, specify:

- **Is this data collected, shared, or both?**: Collected (except payment info which is "Collected and shared")
- **Is this data processed ephemerally?**: NO (for most types)
- **Is collecting this data required or optional?**: [See specific answers above]
- **Why is this user data collected/shared?**: [See purposes above]

### Data security

- **Is all of the user data collected by your app encrypted in transit?**: YES
- **Do you provide a way for users to request that their data is deleted?**: YES

## Important Notes for Developers

1. **Firebase Analytics**: Automatically collects device IDs and app interactions
2. **Firebase Crashlytics**: Automatically collects crash logs and diagnostics
3. **Firebase Auth**: Collects email addresses and user IDs
4. **Stripe SDK**: Collects and shares payment information
5. **Google Maps**: Collects location data when used
6. **Camera/Photo picker**: Collects photos when users upload content
7. **Push notifications**: Requires device ID collection

## Action Items

1. Update Google Play Console data safety form with the declarations above
2. Ensure privacy policy matches these declarations
3. Review all third-party SDKs for additional data collection
4. Test data deletion functionality
5. Verify all data collection is properly disclosed to users in-app

---

_This declaration is based on ARTbeat v1.1.0 (Build 34) as of August 23, 2025_
