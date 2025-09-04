# Enhanced Content Review System

## Overview

The Enhanced Content Review System provides comprehensive content moderation capabilities for the ArtBeat platform. This system allows administrators to efficiently review, approve, reject, or delete various types of content including ads, captures, posts, comments, and artwork.

## Features

### 1. Content Types Support

- **Ads**: Advertisement content moderation
- **Captures**: User-generated capture content
- **Posts**: Social media posts and updates
- **Comments**: User comments and replies
- **Artwork**: Artist portfolio pieces
- **All**: View all content types together

### 2. Review Statuses

- **Pending Review**: Content awaiting moderation
- **Approved**: Content approved for public display
- **Rejected**: Content rejected with reason
- **Flagged**: Content flagged by users or automated systems
- **Under Review**: Content currently being reviewed

### 3. Advanced Filtering

- **Content Type Filter**: Filter by specific content types
- **Status Filter**: Filter by review status
- **Search**: Text search across titles and descriptions
- **Date Range**: Filter by creation date
- **Author Filter**: Filter by author name or ID
- **Flag Reason**: Filter by specific flag reasons

### 4. Bulk Operations

- **Bulk Approve**: Approve multiple items at once
- **Bulk Reject**: Reject multiple items with reason
- **Bulk Delete**: Permanently delete multiple items
- **Select All**: Quick selection of all visible items

### 5. Enhanced UI/UX

- **Responsive Design**: Works on desktop and mobile
- **Real-time Updates**: Live data synchronization
- **Detailed Content View**: Expandable content details
- **Image Previews**: Thumbnail previews for visual content
- **Action Confirmations**: Confirmation dialogs for destructive actions

## Implementation Details

### Models

#### ContentType Enum

```dart
enum ContentType {
  ads,
  captures,
  posts,
  comments,
  artwork,
  all
}
```

#### ReviewStatus Enum

```dart
enum ReviewStatus {
  pending,
  approved,
  rejected,
  flagged,
  underReview
}
```

#### ModerationFilters Class

```dart
class ModerationFilters {
  final ContentType? contentType;
  final ReviewStatus? status;
  final String? searchQuery;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? userId;
  final String? authorName;
  final String? flagReason;
  final int? limit;
}
```

#### ContentReviewModel Class

```dart
class ContentReviewModel {
  final String id;
  final String contentId;
  final ContentType contentType;
  final String title;
  final String description;
  final String authorId;
  final String authorName;
  final ReviewStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;
  final Map<String, dynamic>? metadata;
}
```

### Services

#### ContentReviewService

The service provides comprehensive content review functionality:

- **getPendingReviews()**: Fetch content awaiting review
- **getFilteredReviews()**: Get reviews with applied filters
- **approveContent()**: Approve individual content
- **rejectContent()**: Reject content with reason
- **deleteContent()**: Permanently delete content
- **bulkApproveReviews()**: Bulk approve multiple reviews
- **bulkRejectReviews()**: Bulk reject with reason
- **bulkDeleteReviews()**: Bulk delete multiple reviews
- **getReviewStats()**: Get moderation statistics

### Screens

#### EnhancedAdminContentReviewScreen

The main UI component providing:

- **Filter Panel**: Advanced filtering options
- **Content List**: Paginated content display
- **Bulk Actions**: Multi-select operations
- **Detail View**: Expandable content details
- **Action Buttons**: Individual content actions

## Usage

### Navigation

The enhanced content review screen is accessible via:

```dart
Navigator.pushNamed(context, AdminRoutes.enhancedContentReview);
```

### Route Configuration

```dart
static const String enhancedContentReview = '/admin/enhanced-content-review';
```

### Service Integration

```dart
final contentReviewService = ContentReviewService();

// Get filtered reviews
final reviews = await contentReviewService.getFilteredReviews(
  filters: ModerationFilters(
    contentType: ContentType.posts,
    status: ReviewStatus.pending,
  ),
);

// Bulk approve
await contentReviewService.bulkApproveReviews(selectedReviews);
```

## Testing

Comprehensive test suite covering:

- Model validation and serialization
- Filter functionality
- Service operations
- UI component behavior

Run tests with:

```bash
flutter test packages/artbeat_admin/test/enhanced_content_review_test.dart
```

## Security Considerations

1. **Authentication**: All operations require admin authentication
2. **Authorization**: Role-based access control for different admin levels
3. **Audit Trail**: All moderation actions are logged
4. **Data Validation**: Input validation and sanitization
5. **Rate Limiting**: Protection against bulk operation abuse

## Performance Optimizations

1. **Pagination**: Large datasets are paginated
2. **Lazy Loading**: Content loaded on demand
3. **Caching**: Frequently accessed data is cached
4. **Batch Operations**: Efficient bulk operations
5. **Indexed Queries**: Optimized database queries

## Future Enhancements

1. **AI-Powered Moderation**: Automated content classification
2. **Advanced Analytics**: Detailed moderation metrics
3. **Custom Workflows**: Configurable review processes
4. **Integration APIs**: Third-party moderation tools
5. **Mobile App**: Dedicated mobile moderation app

## Migration Notes

This enhanced system replaces the basic content review functionality while maintaining backward compatibility. Existing data structures are preserved, and the migration is seamless.

## Support

For technical support or feature requests, please contact the development team or create an issue in the project repository.
