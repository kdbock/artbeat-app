# App Badge Notification Setup Guide

## Overview

This implementation adds **notification badges** to your app icon showing the count of unread messages. When users receive a new private message, a badge number appears on the app icon in the phone's home screen. The badge automatically clears when users open the messaging screen.

## ✅ What's Been Implemented

### 1. **NotificationService Enhancements**

Added new methods to manage app badges:

- `getBadgeCount()` - Get current badge count
- `incrementBadgeCount()` - Increment and update badge (+1)
- `decrementBadgeCount()` - Decrement and update badge (-1)
- `setBadgeCount(int count)` - Set badge to specific number
- `clearBadge()` - Clear badge completely (set to 0)
- `onMessagingScreenOpened()` - Auto-clear badge & mark notifications as read
- `getUnreadMessageCount()` - Stream for UI unread count display

### 2. **ChatService Integration**

- `markChatAsRead()` now decrements the badge count
- `onOpenMessaging()` - Call when opening messaging screen to auto-clear badge

### 3. **Persistence**

- Badge count is saved to `SharedPreferences` with key `app_badge_count`
- Badge persists across app restarts

### 4. **Platform Support**

- **iOS**: Badge number displayed on app icon + in system notification
- **Android**: Badge number in notification (launcher icon badge)

## 🔧 Integration Steps

### Step 1: Initialize Badges in Your App Startup

In your main app initialization or after Firebase setup:

```dart
// Example: In your main.dart or app initialization code
import 'package:artbeat_messaging/artbeat_messaging.dart';

// After Firebase is initialized:
final notificationService = NotificationService();
await notificationService.initialize();  // This now includes badge setup
```

### Step 2: Call When User Opens Messaging Screen

In your messaging/chat screen widget:

```dart
import 'package:artbeat_messaging/artbeat_messaging.dart';
import 'package:provider/provider.dart';

class MessagingScreen extends StatefulWidget {
  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  @override
  void initState() {
    super.initState();
    _clearBadgeOnOpen();
  }

  Future<void> _clearBadgeOnOpen() async {
    // Get the chat service from your provider setup
    final chatService = Provider.of<ChatService>(context, listen: false);
    await chatService.onOpenMessaging();  // Clears badge and marks as read
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: // ... your messaging UI
    );
  }
}
```

### Step 3: Display Unread Count in UI (Optional)

Show badge count in a tab or button:

```dart
import 'package:artbeat_messaging/artbeat_messaging.dart';

// In your tab or button widget
StreamBuilder<int>(
  stream: notificationService.getUnreadMessageCount(),
  initialData: 0,
  builder: (context, snapshot) {
    final count = snapshot.data ?? 0;

    return Stack(
      children: [
        Icon(Icons.mail),
        if (count > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  },
)
```

### Step 4: When Messages Are Read

The badge automatically decrements when:

- User opens the messaging screen (`onOpenMessaging()`)
- User marks a chat as read (built-in to `markChatAsRead()`)

Manual control if needed:

```dart
// Manually update badge
await notificationService.decrementBadgeCount();  // -1
await notificationService.incrementBadgeCount();  // +1
await notificationService.setBadgeCount(5);       // Set to 5
await notificationService.clearBadge();           // Clear to 0
```

## 📱 Platform Configuration

### iOS (Already Configured)

The implementation automatically requests badge permission:

```dart
// In NotificationService.initialize():
DarwinInitializationSettings(
  requestBadgeSetting: true,  // ✅ Enabled
  requestSoundSetting: true,
  requestAlertSetting: true,
)
```

Badge updates are handled by:

```dart
await _localNotifications.resolvePlatformSpecificImplementation<
    IOSFlutterLocalNotificationsPlugin>()?.setBadgeNumber(count);
```

### Android (Already Configured)

Android badges are shown in:

- System notification badge (if supported by launcher)
- Notification badge count

Configured through:

```dart
AndroidNotificationDetails(
  badge: badgeCount,  // ✅ Enabled
  // ... other settings
)
```

## 🧪 Testing Badge Notifications

### Test 1: Manual Badge Increment

```dart
// In a test or debug screen button
onPressed: () async {
  final notificationService = NotificationService();
  await notificationService.incrementBadgeCount();
  print('Badge incremented');
}
```

### Test 2: Send Message & Check Badge

1. Open app and go to messaging screen
2. Have another user send you a message
3. Badge should appear on app icon with count: "1"
4. Open messaging screen → badge should clear

### Test 3: Multiple Messages

1. Receive 3 messages while app is closed/backgrounded
2. Badge should show "3"
3. Mark one chat as read → badge updates to "2"
4. Open messaging screen → badge clears to "0"

## 🔄 Flow Diagram

```
Incoming Message
    ↓
Firebase Messaging Handler
    ↓
incrementBadgeCount()
    ↓
SharedPreferences: badge_count + 1
    ↓
Update iOS app icon badge
    ↓
User sees red badge with count on home screen
    ↓
User taps app or opens messaging
    ↓
onOpenMessaging() / onMessagingScreenOpened()
    ↓
clearBadge() → badge_count = 0
    ↓
Badge disappears from app icon
```

## 🛠️ Troubleshooting

### Badge Not Showing on iOS

- Ensure user granted notification permission with badge enabled
- Check `requestBadgeSetting: true` in `DarwinInitializationSettings`
- Verify iOS app capabilities include "Push Notifications"

### Badge Not Showing on Android

- Some Android launchers don't support badge counts
- Badge will show in notification tray instead
- Test on different launchers (Samsung, Google Pixel, etc.)

### Badge Not Clearing

- Ensure `onOpenMessaging()` is called when opening messaging screen
- Check `SharedPreferences` is initialized in `NotificationService`
- Verify `clearBadge()` has no errors in logs

### Badge Count Wrong

- Check `SharedPreferences` for `app_badge_count` key
- Ensure no multiple increments happening for same message
- Monitor logs for badge operation errors

## 📊 Storage

Badge count is stored in SharedPreferences:

- **Key**: `app_badge_count`
- **Type**: Integer
- **Persistence**: Survives app restart
- **Reset**: Only cleared via `clearBadge()` or `setBadgeCount(0)`

## 🚀 Next Steps (Optional Enhancements)

1. **Per-Chat Badges**: Show badge per conversation instead of total

   ```dart
   Stream<int> getUnreadCountForChat(String chatId)
   ```

2. **Badge Animations**: Animate badge number changes

3. **Sound & Haptics**: Add sound/vibration with badge increment

4. **Custom Badge Colors**: Different colors for different notification types

5. **Badge Limit**: Cap badge at 99+ like typical apps

## 📝 API Reference

### NotificationService Methods

| Method                      | Returns        | Purpose                                  |
| --------------------------- | -------------- | ---------------------------------------- |
| `getBadgeCount()`           | `Future<int>`  | Get current badge count                  |
| `incrementBadgeCount()`     | `Future<int>`  | Add 1 to badge, return new count         |
| `decrementBadgeCount()`     | `Future<int>`  | Subtract 1 from badge, return new count  |
| `setBadgeCount(int)`        | `Future<void>` | Set badge to specific count (0-999)      |
| `clearBadge()`              | `Future<void>` | Set badge to 0                           |
| `onMessagingScreenOpened()` | `Future<void>` | Clear badge & mark notifications as read |
| `getUnreadMessageCount()`   | `Stream<int>`  | Stream of unread message count           |

### ChatService Methods

| Method                   | Returns        | Purpose                                 |
| ------------------------ | -------------- | --------------------------------------- |
| `markChatAsRead(String)` | `Future<void>` | Mark chat as read + decrement badge     |
| `onOpenMessaging()`      | `Future<void>` | Auto-clear badge when opening messaging |

---

## ✨ Summary

You now have a complete app badge notification system that:

- ✅ Shows badge count on app icon
- ✅ Increments when new messages arrive
- ✅ Decrements when messages are read
- ✅ Clears when messaging screen opens
- ✅ Persists across app restarts
- ✅ Works on iOS & Android
- ✅ Fully integrated with existing notification system

**No additional platform configuration needed!** The badge system is already set up and ready to use.
