# 🚀 Notification Types - Quick Reference

## One-Minute Overview

You now have **4 notification types**:

| Type              | When to Use                    | Method                            | Example             |
| ----------------- | ------------------------------ | --------------------------------- | ------------------- |
| **💬 Message**    | User receives a direct message | `sendNotificationToUser()`        | Already implemented |
| **🎁 Gift**       | User receives a gift           | `sendGiftNotification()`          | User sends gift     |
| **🎨 Commission** | User gets a commission request | `sendCommissionNotification()`    | Buyer requests art  |
| **📅 Event**      | Event reminder for user        | `sendEventReminderNotification()` | Art walk in 1 hour  |

---

## 💻 Copy-Paste Code Examples

### Send a Gift Notification

```dart
import 'package:provider/provider.dart';
import 'package:artbeat_messaging/src/services/notification_service.dart';

// In any widget or service
void sendGiftNotif(BuildContext context) async {
  final notif = Provider.of<NotificationService>(context, listen: false);

  await notif.sendGiftNotification(
    recipientUserId: 'recipient_uid_here',
    senderName: 'Alice Cooper',
    giftName: 'Exclusive Art Pack',
    giftImageUrl: 'https://example.com/gift.jpg',
  );
}
```

### Send a Commission Notification

```dart
void sendCommissionNotif(BuildContext context) async {
  final notif = Provider.of<NotificationService>(context, listen: false);

  await notif.sendCommissionNotification(
    artistUserId: 'artist_uid_here',
    buyerName: 'Bob Smith',
    artworkDescription: '20x24 oil portrait',
    budget: 800.0,
  );
}
```

### Send an Event Reminder

```dart
void sendEventNotif(BuildContext context) async {
  final notif = Provider.of<NotificationService>(context, listen: false);

  await notif.sendEventReminderNotification(
    userId: 'user_uid_here',
    eventName: 'Downtown Art Walk',
    eventTime: 'Saturday at 10:00 AM',
    location: 'Main Street Gallery',
  );
}
```

---

## 📱 What User Sees

### iPhone

```
┌─────────────────────────────┐
│ 🎁 Gift from Alice Cooper   │
│ Alice Cooper sent you:      │
│ Exclusive Art Pack          │
│         [Tap to view]       │
└─────────────────────────────┘
```

### Android

```
[High priority banner at top of screen]
┌─────────────────────────────┐
│ 🎁 Gift from Alice Cooper   │
│ Alice Cooper sent you:...   │
└─────────────────────────────┘
+ Phone vibrates
+ Sound plays
```

---

## 🔑 Key Points

1. **Each method requires specific parameters:**

   - Gifts: sender name, gift name, image URL
   - Commissions: buyer name, artwork description, budget
   - Events: event name, time, location

2. **Parameters must be strings (except budget which is double)**

3. **Errors are logged** - check console for any issues

4. **Notifications stored in Firestore** - in user's `notifications` collection

5. **Badge only increments for messages** - keeps icon clean

---

## 🎯 Where to Call These Methods

### In a Gift Feature:

```dart
// When gift is sent
await notificationService.sendGiftNotification(
  recipientUserId: receiverUID,
  senderName: currentUserName,
  giftName: giftName,
  giftImageUrl: giftImageURL,
);
```

### In a Commission Feature:

```dart
// When buyer requests commission
await notificationService.sendCommissionNotification(
  artistUserId: artistUID,
  buyerName: buyerName,
  artworkDescription: artDescription,
  budget: quotedPrice,
);
```

### In an Events Feature:

```dart
// When event reminder scheduled
await notificationService.sendEventReminderNotification(
  userId: userUID,
  eventName: eventTitle,
  eventTime: eventDateTime,
  location: eventLocation,
);
```

---

## 🧪 Test It in 30 Seconds

Add this to any screen and tap a button:

```dart
ElevatedButton(
  onPressed: () async {
    final notif = Provider.of<NotificationService>(context, listen: false);
    await notif.sendGiftNotification(
      recipientUserId: FirebaseAuth.instance.currentUser!.uid,
      senderName: 'Test Sender',
      giftName: 'Test Gift',
      giftImageUrl: 'https://via.placeholder.com/100',
    );
  },
  child: Text('Test Gift Notification'),
)
```

---

## 📊 Available Methods

```dart
// Gift notification
Future<void> sendGiftNotification({
  required String recipientUserId,
  required String senderName,
  required String giftName,
  required String giftImageUrl,
})

// Commission notification
Future<void> sendCommissionNotification({
  required String artistUserId,
  required String buyerName,
  required String artworkDescription,
  required double budget,
})

// Event notification
Future<void> sendEventReminderNotification({
  required String userId,
  required String eventName,
  required String eventTime,
  required String location,
})

// Also available (already existed):
Future<void> sendNotificationToUser({
  required String userId,
  required String title,
  required String body,
  required Map<String, dynamic> data,
})
```

---

## 🔧 Advanced Usage

### Send Generic Notification (for custom types later)

```dart
await notificationService.sendNotificationToUser(
  userId: 'user_uid',
  title: 'Custom Title',
  body: 'Custom Body',
  data: {
    'type': 'message',  // or 'gift', 'commission', 'event'
    'customField': 'customValue',
    'route': '/custom/route',
  },
);
```

### Get Unread Count

```dart
notificationService.getUnreadNotificationsCount()
  .listen((count) {
    print('Unread notifications: $count');
  });
```

### Mark as Read

```dart
await notificationService.markNotificationAsRead(notificationId);
```

---

## 📋 Troubleshooting

### Notification not showing?

- Check user has notification permissions granted
- Verify `userId` is correct
- Check console logs for emoji-prefixed messages (💬 🎁 🎨 📅)

### Badge not clearing?

- Badge only for message notifications
- Call `onMessagingScreenOpened()` when opening messaging screen
- Check that it was already integrated in `artistic_messaging_screen.dart`

### Wrong screen navigation?

- Notifications route based on type
- Gift → `/gifts/received`
- Commission → `/commissions/requests`
- Event → `/events/details`
- Make sure these routes are registered in your app

---

## ✅ Checklist for Implementation

- [ ] Import `NotificationService` where needed
- [ ] Get provider instance: `Provider.of<NotificationService>(context, listen: false)`
- [ ] Call appropriate method with correct parameters
- [ ] Test with test button
- [ ] Create destination screens for each type
- [ ] Update navigation routes if needed
- [ ] Test actual end-to-end flow

---

## 🎯 Next Steps

1. **Create Gift Screen** at `/gifts/received`
2. **Create Commission Screen** at `/commissions/requests`
3. **Create Event Screen** at `/events/details`
4. **Call methods** in your feature services
5. **Test** with real data

That's it! 🚀
