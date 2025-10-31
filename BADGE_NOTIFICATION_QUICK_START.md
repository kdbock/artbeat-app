# 🚀 Badge Notification - Quick Start (3 Steps)

## Summary

Your app now sends a **red notification badge** with unread message count on the app icon. The badge automatically clears when users open the messaging screen.

---

## ✅ STEP 1: Already Done! ✅

Badge functionality is **fully implemented** in `NotificationService` and `ChatService`.

```dart
✅ NotificationService:
   - Badge increment/decrement
   - Badge persistence with SharedPreferences
   - iOS + Android support

✅ ChatService:
   - Auto-decrement badge when chat is read
   - Clear badge when opening messaging screen
```

---

## STEP 2: Open Your Messaging Screen File

Find your main messaging/chat list screen (likely in one of these locations):

- `lib/screens/messaging_screen.dart`
- `packages/artbeat_messaging/lib/src/screens/chat_screen.dart`
- `packages/artbeat_messaging/lib/src/screens/messaging_screen.dart`

---

## STEP 3: Add This Code to the Messaging Screen

### Add to `initState()`:

```dart
@override
void initState() {
  super.initState();
  _clearBadgeWhenScreenOpens();
}

Future<void> _clearBadgeWhenScreenOpens() async {
  try {
    final chatService = Provider.of<ChatService>(context, listen: false);
    await chatService.onOpenMessaging();  // Clears badge and marks messages as read
  } catch (e) {
    print('Error clearing badge: $e');
  }
}
```

### Or if you don't use Provider, use this approach:

```dart
@override
void initState() {
  super.initState();
  _clearBadgeWhenScreenOpens();
}

Future<void> _clearBadgeWhenScreenOpens() async {
  try {
    final notificationService = NotificationService();
    await notificationService.onMessagingScreenOpened();  // Clears badge
  } catch (e) {
    print('Error clearing badge: $e');
  }
}
```

---

## 📱 That's It! Your Badge System is Now Active

### What happens automatically:

1. **New message arrives** → Badge appears on app icon with count (+1)
2. **User opens app** → Badge remains visible
3. **User opens messaging screen** → Badge clears automatically (0)
4. **App restarts** → Badge persists from SharedPreferences

### What you can manually control (optional):

```dart
// In any screen, import:
import 'package:artbeat_messaging/artbeat_messaging.dart';

// Then use:
final notificationService = NotificationService();

await notificationService.incrementBadgeCount();   // Add 1
await notificationService.decrementBadgeCount();   // Subtract 1
await notificationService.setBadgeCount(5);        // Set to 5
await notificationService.clearBadge();            // Clear (0)
await notificationService.getBadgeCount();         // Get current
```

---

## 🧪 Quick Test

1. **Open the app**
2. **Close the app completely** (go to home screen)
3. **Have someone send you a private message**
4. **Look at your app icon on home screen** → You should see a red badge with "1"
5. **Open the app** → Badge remains
6. **Open the Messaging screen** → Badge automatically clears

---

## 🎯 Badge Behavior Summary

| Action                        | Badge                   |
| ----------------------------- | ----------------------- |
| Message received (app closed) | Shows count (e.g., "3") |
| Open app                      | Badge stays visible     |
| Open Messaging screen         | Clears to "0"           |
| Mark chat as read             | Decrements by 1         |
| Receive another message       | Increments by 1         |

---

## 📁 Files Modified

- ✅ `/packages/artbeat_messaging/lib/src/services/notification_service.dart` - Badge methods added
- ✅ `/packages/artbeat_messaging/lib/src/services/chat_service.dart` - Integration added

## 📚 Files Created

- ✅ `/APP_BADGE_NOTIFICATION_SETUP.md` - Full documentation
- ✅ `/BADGE_NOTIFICATION_QUICK_START.md` - This file

---

## 🔍 How It Works Behind the Scenes

```
notificationService.initialize()
    ↓ [Requests badge permission from user]
    ↓ [Initializes SharedPreferences]
    ↓ [Sets up Firebase Messaging listeners]

New message arrives
    ↓ [Notification handler triggered]
    ↓ notificationService._triggerLocalNotification()
    ↓ incrementBadgeCount()
    ↓ [Saves to SharedPreferences: "app_badge_count" = 1]
    ↓ [Updates iOS app icon: setBadgeNumber(1)]
    ↓ [Updates Android notification: badge = 1]
    ↓ [User sees "1" on app icon]

User opens messaging screen
    ↓ chatService.onOpenMessaging()
    ↓ notificationService.onMessagingScreenOpened()
    ↓ clearBadge()
    ↓ [Saves to SharedPreferences: "app_badge_count" = 0]
    ↓ [Updates iOS app icon: setBadgeNumber(0)]
    ↓ [Badge disappears from app icon]
```

---

## ⚠️ Important Notes

1. **iOS Requirements**

   - User must grant notification permission (badge is part of it)
   - Badge number appears on app icon in home screen

2. **Android Requirements**

   - Some launchers support badge numbers
   - If your launcher doesn't, badge shows in notification tray instead
   - Badge still works, just visible in different location

3. **Data Persistence**

   - Badge count survives app restart
   - Stored in `SharedPreferences` with key `app_badge_count`

4. **Manual Control**
   - If you need to manually control badges (advanced), all methods are public
   - Most use cases are covered by `onOpenMessaging()` and auto-increment

---

## 🆘 Debugging

If badge doesn't work:

### Check 1: Is NotificationService initialized?

```dart
// In your app startup
notificationService.initialize();  // Must be called
```

### Check 2: Is the method called when opening messaging?

```dart
// In your messaging screen's initState()
await chatService.onOpenMessaging();  // Must be called
```

### Check 3: Check permissions

- iOS: Settings → Your App → Notifications → Badge (must be ON)
- Android: Settings → Your App → Notifications (must be ON)

### Check 4: Check logs

Look for these log messages:

- `📲 Badge incremented to 1` - Badge updated
- `📲 Badge cleared` - Badge cleared
- If you see errors, check the error message

---

## 🎉 You're Done!

Your app badge notification system is now fully functional. Users will see a visual indicator (red badge with count) on your app icon whenever they have unread messages.

**No complicated setup required—just add 6 lines of code to your messaging screen!**

Need help? Check `APP_BADGE_NOTIFICATION_SETUP.md` for detailed documentation.
