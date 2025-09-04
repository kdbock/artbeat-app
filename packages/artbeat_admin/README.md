# ARTbeat Admin Package

A comprehensive admin dashboard package for the ARTbeat application, providing full administrative capabilities for user management, content moderation, analytics, and system settings.

## Features

### 🎯 **Core Admin Dashboard**

- Real-time statistics overview
- User activity monitoring
- Quick action tiles
- Modern Material Design UI

### 👥 **User Management**

- View all users with filtering and sorting
- Change user types (Regular, Artist, Gallery, Moderator, Admin)
- Suspend/unsuspend users with reasons
- Verify/unverify user accounts
- Bulk operations for multiple users
- Detailed user profiles with admin notes
- Experience points and level management

### 📊 **Analytics & Reporting**

- User registration trends
- Activity statistics
- Content metrics
- User type distribution

### 🔧 **Admin Tools**

- User creation with full profile data
- Admin notes and flags system
- Content management capabilities
- System settings configuration

## Getting started

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  artbeat_admin:
    path: ../artbeat_admin
```

## Usage

### Basic Setup

```dart
import 'package:artbeat_admin/artbeat_admin.dart';

// Navigate to admin dashboard
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const AdminEnhancedDashboardScreen(),
  ),
);
```

### User Management

```dart
import 'package:artbeat_admin/artbeat_admin.dart';

final adminService = AdminService();

// Get admin statistics
final stats = await adminService.getAdminStats();

// Get all users
final users = await adminService.getAllUsers(
  limit: 50,
  orderBy: 'createdAt',
  descending: true,
  filterByType: UserType.artist,
);

// Update user type
await adminService.updateUserType(userId, UserType.artist);

// Suspend user
await adminService.suspendUser(userId, 'Violation of terms', 'admin');
```

## User Types

The system supports the following user types:

- **Regular** (`UserType.regular`): Standard app users
- **Artist** (`UserType.artist`): Artists who can upload artwork
- **Gallery** (`UserType.gallery`): Gallery owners and managers
- **Moderator** (`UserType.moderator`): Content moderators
- **Admin** (`UserType.admin`): Full system administrators

## Additional information

This package integrates seamlessly with Firebase Firestore for data storage and provides a complete admin interface for managing ARTbeat application users and content. All admin operations include proper error handling, validation, and security measures.
