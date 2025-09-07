# Universal ARTbeat Header Implementation Guide

## Overview

This guide provides a comprehensive solution for implementing consistent, color-coded headers across all ARTbeat modules. The universal header system ensures visual consistency while maintaining module-specific branding through color schemes.

## 🎨 Color Scheme Reference

| Module                | Primary Color           | Secondary Color               | Notes                        |
| --------------------- | ----------------------- | ----------------------------- | ---------------------------- |
| **artbeat_admin**     | Blue → Green            | `#1976D2` → `#4CAF50`         | Administrative interface     |
| **artbeat_ads**       | Tan → Purple            | `#D2B48C` → `#9C27B0`         | Advertising management       |
| **artbeat_art_walk**  | Teal → Peach            | `#009688` → `#FF9800`         | Location-based art discovery |
| **artbeat_artwork**   | Pink → Blue             | `#E91E63` → `#2196F3`         | Artwork management           |
| **artbeat_artist**    | Violet → Yellow         | `#9C27B0` → `#FFEB3B`         | Artist profiles and tools    |
| **artbeat_auth**      | No header               | Transparent                   | Authentication flows         |
| **artbeat_capture**   | Hunter Green → Lavender | `#2E7D32` → `#E1BEE7`         | Content capture              |
| **artbeat_community** | Burgundy → Green        | `#880E4F` → `#4CAF50`         | Social features              |
| **artbeat_profile**   | Gold → Purple           | `#FFD700` → `#9C27B0`         | User profiles                |
| **artbeat_messaging** | Multicolor              | Pink/Blue/Green/Orange/Purple | Communication hub            |
| **artbeat_core**      | Purple → Green          | `#9C27B0` → `#4CAF50`         | Core functionality           |
| **artbeat_events**    | Red → Silver            | `#F44336` → `#B0BEC5`         | Event management             |
| **artbeat_settings**  | Orange → Mint Green     | `#FF9800` → `#4DB6AC`         | Settings and preferences     |

## 📱 Implementation Examples

### Basic Header Implementation

```dart
import 'package:artbeat_core/src/widgets/universal_artbeat_header.dart';

class ExampleScreen extends StatelessWidget {
  const ExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          UniversalArtbeatHeader(
            moduleName: 'artbeat_core',
            title: 'Dashboard',
            subtitle: 'Welcome back!',
            showBackButton: true,
          ),
          // Rest of your screen content
          Expanded(
            child: Center(
              child: Text('Screen Content'),
            ),
          ),
        ],
      ),
    );
  }
}
```

### Header with Actions

```dart
UniversalArtbeatHeader(
  moduleName: 'artbeat_community',
  title: 'Community Feed',
  subtitle: 'Latest posts from artists',
  actions: [
    IconButton(
      icon: Icon(Icons.search, color: Colors.white),
      onPressed: () => _searchPosts(),
    ),
    IconButton(
      icon: Icon(Icons.filter_list, color: Colors.white),
      onPressed: () => _showFilters(),
    ),
  ],
)
```

### Header with Custom Back Action

```dart
UniversalArtbeatHeader(
  moduleName: 'artbeat_artwork',
  title: 'Artwork Details',
  showBackButton: true,
  onBackPressed: () {
    // Custom back navigation logic
    Navigator.of(context).pushReplacementNamed('/artwork-gallery');
  },
)
```

## 🔧 Module-Specific Implementation

### Admin Module Header

```dart
// In artbeat_admin screens
UniversalArtbeatHeader(
  moduleName: 'artbeat_admin',
  title: 'User Management',
  subtitle: 'Admin Dashboard',
  actions: [
    IconButton(
      icon: Icon(Icons.settings, color: Colors.white),
      onPressed: () => _showAdminSettings(),
    ),
  ],
)
```

### Art Walk Module Header

```dart
// In artbeat_art_walk screens
UniversalArtbeatHeader(
  moduleName: 'artbeat_art_walk',
  title: 'Art Walk Explorer',
  subtitle: 'Discover public art near you',
  showBackButton: true,
)
```

### Community Module Header

```dart
// In artbeat_community screens
UniversalArtbeatHeader(
  moduleName: 'artbeat_community',
  title: 'Community Feed',
  subtitle: '${postCount} posts today',
  actions: [
    IconButton(
      icon: Icon(Icons.add, color: Colors.white),
      onPressed: () => _createNewPost(),
    ),
  ],
)
```

## 🎯 Migration Strategy

### Step 1: Update Imports

Add the universal header import to all screen files:

```dart
import 'package:artbeat_core/src/widgets/universal_artbeat_header.dart';
```

### Step 2: Replace Existing Headers

Replace existing AppBar or custom headers with UniversalArtbeatHeader:

```dart
// Before
AppBar(
  title: Text('Dashboard'),
  backgroundColor: Colors.blue,
)

// After
UniversalArtbeatHeader(
  moduleName: 'artbeat_core',
  title: 'Dashboard',
)
```

### Step 3: Update Screen Structure

Modify screen layouts to accommodate the header:

```dart
// Before
Scaffold(
  appBar: AppBar(title: Text('Screen Title')),
  body: Content(),
)

// After
Scaffold(
  body: Column(
    children: [
      UniversalArtbeatHeader(
        moduleName: 'your_module_name',
        title: 'Screen Title',
      ),
      Expanded(child: Content()),
    ],
  ),
)
```

## 📋 Module-Specific Guidelines

### Auth Module (No Header)

The auth module should not use headers for security and UX reasons:

```dart
// Correct - No header for auth screens
Scaffold(
  body: AuthForm(),
)

// Incorrect - Don't add headers to auth screens
UniversalArtbeatHeader(
  moduleName: 'artbeat_auth', // This will be transparent
  title: 'Login',
)
```

### Messaging Module (Multicolor)

The messaging module uses a special multicolor gradient:

```dart
UniversalArtbeatHeader(
  moduleName: 'artbeat_messaging',
  title: 'Messages',
  subtitle: '${unreadCount} unread messages',
)
```

## 🔍 Best Practices

### 1. Consistent Module Naming

Always use the exact module name as defined in the color scheme:

```dart
// ✅ Correct
moduleName: 'artbeat_art_walk'

// ❌ Incorrect
moduleName: 'art_walk'
moduleName: 'ARTBEAT_ART_WALK'
```

### 2. Title Formatting

- Use sentence case for titles
- Keep titles concise (max 30 characters)
- Use subtitles for additional context

### 3. Action Buttons

- Limit to 2-3 action buttons per header
- Use consistent icons across similar screens
- Ensure proper contrast with header colors

### 4. Back Button Usage

- Show back button on detail screens
- Hide back button on main navigation screens
- Use custom back actions when needed

## 🛠️ Customization Options

### Custom Height

```dart
UniversalArtbeatHeader(
  moduleName: 'artbeat_core',
  title: 'Dashboard',
  height: 100.0, // Custom height
)
```

### Disable Gradient

```dart
UniversalArtbeatHeader(
  moduleName: 'artbeat_core',
  title: 'Dashboard',
  useGradient: false, // Solid color instead of gradient
)
```

### Custom Colors (Advanced)

For special cases, you can extend the color scheme:

```dart
// Create custom color scheme
final customScheme = ModuleColorScheme(
  primary: Colors.indigo,
  secondary: Colors.teal,
  onPrimary: Colors.white,
);

// Use in header (requires modification of the widget)
```

## 📱 Responsive Design

The universal header is fully responsive:

- **Mobile**: Compact layout with smaller icons
- **Tablet**: Optimized spacing and typography
- **Desktop**: Enhanced visual effects and spacing

## 🔧 Troubleshooting

### Common Issues

1. **Header not showing correct colors**

   - Verify module name spelling
   - Check if module is in the color scheme map

2. **Text contrast issues**

   - The header automatically uses appropriate text colors
   - For custom colors, ensure proper contrast ratios

3. **Layout overflow**
   - Use `Expanded` for content below header
   - Check for proper SafeArea usage

### Debug Mode

Enable debug mode to see header boundaries:

```dart
UniversalArtbeatHeader(
  moduleName: 'artbeat_core',
  title: 'Dashboard',
  // Debug borders will be visible in debug mode
)
```

## 📚 Additional Resources

- [Material Design Guidelines](https://material.io/design)
- [Flutter Layout Best Practices](https://flutter.dev/docs/development/ui/layout)
- [Accessibility Guidelines](https://material.io/design/usability/accessibility.html)

## 🔄 Future Enhancements

- Animated transitions between screens
- Dynamic color schemes based on user preferences
- Voice-controlled navigation
- Advanced accessibility features

---

**Last Updated**: September 2025
**Version**: 1.0.0
