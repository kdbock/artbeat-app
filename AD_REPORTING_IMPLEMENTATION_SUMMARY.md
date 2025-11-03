# Ad Reporting and Moderation System Implementation Summary

## Overview

Successfully implemented a comprehensive advertisement reporting and moderation system for the ARTbeat app that includes:

## 🎯 Features Implemented

### 1. Ad Reporting System

- **AdReportModel**: Complete model for tracking ad reports with reasons, status, and admin review capabilities
- **AdReportReasons**: Predefined report reasons including spam, inappropriate content, misleading ads, etc.
- **AdReportDialog**: User-friendly dialog for reporting ads with clear categories and optional details
- **AdReportButton**: Reusable report button component that can be added to any ad display

### 2. Enhanced Ad Status Management

- **Updated LocalAdStatus enum** with new statuses:
  - `pendingReview`: New ads require review before going live
  - `flagged`: Ads automatically flagged after 3 reports
  - `rejected`: Ads rejected by moderators
  - Enhanced helper methods for visibility and review status

### 3. Updated LocalAd Model

- Added `reportCount` field to track number of reports
- Added `reviewedAt`, `reviewedBy`, and `rejectionReason` fields for admin workflow
- New helper methods:
  - `isFlagged`: Check if ad has 3+ reports
  - `needsReview`: Check if ad needs admin attention
  - `isVisibleToUsers`: Check if ad should be shown to users

### 4. Ad Report Service

- **AdReportService**: Complete service for handling ad reporting and moderation
  - `reportAd()`: Submit user reports with duplicate checking
  - `_checkAndFlagAd()`: Automatically flag ads after 3 reports
  - `approveAd()`, `rejectAd()`, `deleteAd()`: Admin moderation actions
  - `getAdsNeedingReview()`: Stream of flagged/pending ads
  - `getReportStatistics()`: Admin dashboard metrics

### 5. Enhanced LocalAdService

- Added methods for admin management:
  - `getAdsForReview()`: Get ads needing admin attention
  - `getAllAdsForAdmin()`: Get all ads for admin dashboard
  - `updateAdStatus()`: Update ad status with admin info
  - `getAdsForReviewStream()`: Real-time updates for admin dashboard
  - `getAdStatistics()`: Statistics by status

### 6. Admin Management Integration

- **AdminAdManagementWidget**: Complete admin interface for ad moderation
  - Statistics dashboard showing pending, flagged, active ads and reports
  - Filter tabs for different ad categories
  - Ad review cards with approve/reject actions
  - Report review functionality
  - Detailed ad view dialog
  - Rejection reason dialog

### 7. User-Facing Integration

- Updated **AdGridCardWidget** to include report functionality
- Filtered ads to only show approved, non-flagged ads to users
- Added report button to ad displays for user reporting

## 🔧 Implementation Details

### Workflow

1. **New Ad Creation**: Ads start with `pendingReview` status (requires admin approval)
2. **User Reporting**: Users can report ads with specific reasons and details
3. **Automatic Flagging**: Ads with 3+ reports are automatically flagged and removed from circulation
4. **Admin Review**: Admins can approve, reject, or delete ads through the dashboard
5. **Status Management**: Only approved, non-flagged, non-expired ads are visible to users

### Permissions & Roles

- **Users**: Can report ads they see in the app
- **Moderators**: Can review and approve/reject ads (contentAdmin, supportAdmin roles)
- **Admins**: Full access to ad management and reporting (superAdmin role)

### Data Collections

- `ad_reports`: Stores user reports with reasons and admin review status
- `local_ads`: Enhanced with reporting and review fields
- `admin_activities`: Logs all admin actions for audit trail

## 🚀 Key Benefits

1. **User Safety**: Users can report inappropriate ads
2. **Automated Moderation**: Ads with multiple reports are automatically removed
3. **Admin Oversight**: Complete admin dashboard for managing ads and reports
4. **Audit Trail**: All admin actions are logged for accountability
5. **Scalable**: System handles high volume of ads and reports efficiently

## 📝 Usage Examples

### For Users

```dart
// Report button is automatically added to ad widgets
AdReportButton(
  adId: ad.id,
  adTitle: ad.title,
  adDescription: ad.description,
  onReport: reportService.reportAd,
)
```

### For Admins

```dart
// Admin dashboard widget
AdminAdManagementWidget()
```

### For Developers

```dart
// Check if ad should be visible
if (ad.isVisibleToUsers) {
  // Show ad
}

// Report an ad programmatically
await reportService.reportAd(
  adId: 'ad123',
  reason: 'inappropriate_content',
  additionalDetails: 'Contains offensive material',
);
```

## 🔒 Security Considerations

- Users can only report ads once per ad
- Authentication required for all reporting actions
- Admin actions are logged with timestamps and user IDs
- Report reasons are pre-defined to prevent abuse
- Automatic flagging prevents malicious ads from staying visible

## 📊 Monitoring & Analytics

The system provides comprehensive statistics for:

- Total ads by status (pending, active, flagged, etc.)
- Report counts and trends
- Admin action history
- Flagged ad statistics

This implementation provides a complete, production-ready ad reporting and moderation system that ensures user safety while maintaining administrative oversight.
