# 📱 Notification Types - Visual Reference Guide

## 🎯 Notification Type Comparison

### Quick Lookup Table

```
┌─────────────┬───────┬──────────────────────┬──────────┬──────────┐
│ Type        │ Icon  │ Appears When         │ Badge    │ Route    │
├─────────────┼───────┼──────────────────────┼──────────┼──────────┤
│ Message     │ 💬    │ Direct message sent  │ ✅ Count │ /msg     │
│ Gift        │ 🎁    │ Gift received        │ ❌ No    │ /gifts   │
│ Commission  │ 🎨    │ Commission request   │ ❌ No    │ /commis  │
│ Event       │ 📅    │ Event reminder       │ ❌ No    │ /events  │
└─────────────┴───────┴──────────────────────┴──────────┴──────────┘
```

---

## 📲 iOS Display Examples

### Message Notification

```
═══════════════════════════════════════
║                                     ║
║ 💬 Sarah: "I love your artwork!"   ║
║         [Dismiss] [View]            ║
║                                     ║
═══════════════════════════════════════
```

### Gift Notification

```
═══════════════════════════════════════
║                                     ║
║ 🎁 Gift from Alice                  ║
║ Alice sent you: Artist Bundle       ║
║         [Dismiss] [View]            ║
║                                     ║
═══════════════════════════════════════
```

### Commission Notification

```
═══════════════════════════════════════
║                                     ║
║ 🎨 Commission Request from Bob      ║
║ Budget: $500 • Custom portrait      ║
║         [Dismiss] [View]            ║
║                                     ║
═══════════════════════════════════════
```

### Event Notification

```
═══════════════════════════════════════
║                                     ║
║ 📅 Reminder: Downtown Art Walk      ║
║ Saturday at 10 AM • Main Street     ║
║         [Dismiss] [View]            ║
║                                     ║
═══════════════════════════════════════
```

---

## 🤖 Android Display Examples

### Message Notification (Heads-up)

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ 💬 Sarah                          ┃
┃ I love your artwork!              ┃
┃ [REPLY]          [MARK AS READ]   ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

### Gift Notification (Heads-up)

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ 🎁 Gift from Alice                ┃
┃ Alice sent you: Artist Bundle     ┃
┃                                   ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
[Vibrates] [Sound plays]
```

### Commission Notification (Heads-up)

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ 🎨 Commission Request from Bob    ┃
┃ Budget: $500 • Custom portrait    ┃
┃                                   ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
[Vibrates] [Sound plays]
```

### Event Notification (Heads-up)

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ 📅 Reminder: Downtown Art Walk    ┃
┃ Saturday at 10 AM • Main Street   ┃
┃                                   ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
[Vibrates] [Sound plays]
```

---

## 🔔 App Badge Examples

### With Messages Only (Badge Shows Count)

```
iOS Icon:                  Android Icon:
┌─────────────┐           ┌─────────────┐
│     AB      │           │     AB      │
│   ┌───┐     │           │   ┌───┐     │
│   │ 3 │     │           │   │ 3 │     │
└─────────────┘           └─────────────┘
3 unread messages         3 unread messages
```

### With Gifts, Commissions, Events

```
iOS Icon:                  Android Icon:
┌─────────────┐           ┌─────────────┐
│     AB      │           │     AB      │
│             │           │             │
│             │           │             │
└─────────────┘           └─────────────┘
No badge shown            No badge shown
(Gifts/Commission/Events  (Gifts/Commission/Events
don't increment badge)    don't increment badge)
```

---

## 🔄 Notification Flow Diagram

```
                    ┌─────────────────────┐
                    │  User Action        │
                    │  (Send gift,        │
                    │   Request commission,│
                    │   Event reminder)   │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │  Feature Service    │
                    │  (GiftService,      │
                    │   CommissionService,│
                    │   EventService)     │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────────────┐
                    │ sendXxxNotification()       │
                    │ Helper Method               │
                    └──────────┬──────────────────┘
                               │
                    ┌──────────▼──────────────────┐
                    │ sendNotificationToUser()    │
                    │ • Save to Firestore         │
                    │ • Add type field            │
                    │ • Trigger listener          │
                    └──────────┬──────────────────┘
                               │
                    ┌──────────▼──────────────────┐
                    │ _startNotificationListener()│
                    │ Detects new doc             │
                    └──────────┬──────────────────┘
                               │
                    ┌──────────▼──────────────────┐
                    │ _triggerLocalNotification() │
                    │ • Parse type                │
                    │ • Get type-specific details │
                    │ • Create payload            │
                    └──────────┬──────────────────┘
                               │
                    ┌──────────▼──────────────────┐
                    │ Platform Notification       │
                    ├─────────────────────────────┤
                    │ iOS: Banner at top          │
                    │ Android: Heads-up floating  │
                    │                             │
                    │ [Sound] [Vibration]         │
                    │ [Badge] (messages only)     │
                    └──────────┬──────────────────┘
                               │
                    ┌──────────▼──────────────────┐
                    │ User Taps Notification      │
                    └──────────┬──────────────────┘
                               │
                    ┌──────────▼──────────────────┐
                    │ _onNotificationResponse()   │
                    │ _handleNotificationTap()    │
                    │ • Parse payload             │
                    │ • Identify type             │
                    │ • Log routing info          │
                    └──────────┬──────────────────┘
                               │
                    ┌──────────▼──────────────────┐
                    │ App Navigates to Route      │
                    │ • /messaging (messages)     │
                    │ • /gifts/received (gifts)   │
                    │ • /commissions/requests     │
                    │ • /events/details (events)  │
                    └──────────────────────────────┘
```

---

## 📊 Code Method Map

```
┌─────────────────────────────────────────────────────────┐
│           NotificationService Methods                   │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  PUBLIC METHODS (Call These!)                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │ sendGiftNotification()           → 🎁 Notification │
│  │ sendCommissionNotification()     → 🎨 Notification │
│  │ sendEventReminderNotification()  → 📅 Notification │
│  │ sendNotificationToUser()         → Generic method  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  INTERNAL METHODS (Used Automatically)                 │
│  ┌──────────────────────────────────────────────────┐  │
│  │ _triggerLocalNotification()    → Shows popup     │
│  │ _getNotificationChannel()      → Channel info    │
│  │ _getChannelInfo()              → Type details    │
│  │ _getAndroidNotificationDetails()→ Android style  │
│  │ _getIOSNotificationDetails()   → iOS style       │
│  │ _onNotificationResponse()      → Handle tap      │
│  │ _handleNotificationTap()       → Route user      │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  BADGE METHODS                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │ incrementBadgeCount()     → Add 1 to badge       │
│  │ decrementBadgeCount()     → Remove 1 from badge  │
│  │ setBadgeCount()           → Set to specific #    │
│  │ clearBadge()              → Set to 0             │
│  │ onMessagingScreenOpened() → Clear badge + read   │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 📝 Data Structure Map

```
USER DOCUMENT
  users/{userId}
    │
    ├── notifications (subcollection)
    │   └── {notificationId}
    │       ├── title: String
    │       ├── body: String
    │       ├── timestamp: Timestamp
    │       ├── isRead: Boolean
    │       ├── type: String (message|gift|commission|event)
    │       └── data: Map<String, dynamic>
    │           ├── senderName: String
    │           ├── giftName: String
    │           ├── giftImageUrl: String
    │           ├── buyerName: String
    │           ├── artworkDescription: String
    │           ├── budget: String
    │           ├── eventName: String
    │           ├── eventTime: String
    │           ├── location: String
    │           └── route: String
    │
    └── deviceTokens: Array[String]
```

---

## 🎯 Type Selection Guide

### When to Send What

```
┌────────────────────┬──────────────────────────────────┐
│ Situation          │ Method to Call                   │
├────────────────────┼──────────────────────────────────┤
│ Direct message     │ sendNotificationToUser()         │
│ received           │ (type: 'message')                │
├────────────────────┼──────────────────────────────────┤
│ User receives a    │ sendGiftNotification()           │
│ digital gift       │                                  │
├────────────────────┼──────────────────────────────────┤
│ Artist gets a      │ sendCommissionNotification()     │
│ commission request │                                  │
├────────────────────┼──────────────────────────────────┤
│ Event reminder or  │ sendEventReminderNotification()  │
│ notification       │                                  │
├────────────────────┼──────────────────────────────────┤
│ Custom message     │ sendNotificationToUser() with    │
│ with custom type   │ custom data['type']              │
└────────────────────┴──────────────────────────────────┘
```

---

## 🔍 Debugging Guide

### Where to Look for Issues

```
┌──────────────────────┬────────────────────────────────────┐
│ Problem              │ Debug Location                     │
├──────────────────────┼────────────────────────────────────┤
│ Notification not     │ Check AppLogger for 💬 🎁 🎨 📅   │
│ showing              │ emojis - verify emit happened      │
├──────────────────────┼────────────────────────────────────┤
│ Wrong notification   │ Firestore: Check 'type' field in   │
│ appearing            │ user's notifications collection    │
├──────────────────────┼────────────────────────────────────┤
│ Badge not clearing   │ Verify onMessagingScreenOpened()   │
│                      │ is called in messaging screen      │
├──────────────────────┼────────────────────────────────────┤
│ Tap doesn't route    │ Check _handleNotificationTap()     │
│                      │ logs for parsing errors            │
├──────────────────────┼────────────────────────────────────┤
│ Permissions denied   │ iOS/Android settings: Check        │
│                      │ notification permissions granted   │
└──────────────────────┴────────────────────────────────────┘
```

---

## 📊 Log Output Examples

### Successful Gift Notification

```
🎁 gift notification: 🎁 Gift from Alice - Alice sent you: Art Bundle
📱 Notification sent to user_id_123: 🎁 Gift from Alice
🎁 Gift notification sent to user_id_123
```

### Successful Commission Notification

```
🎨 commission notification: 🎨 Commission Request from Bob - Budget: $500 • Portrait
📱 Notification sent to user_id_456: 🎨 Commission Request from Bob
🎨 Commission notification sent to user_id_456
```

### Successful Event Reminder

```
📅 event notification: 📅 Reminder: Downtown Art Walk - Saturday at 10 AM • Main Street
📱 Notification sent to user_id_789: 📅 Reminder: Downtown Art Walk
📅 Event notification sent to user_id_789
```

### User Taps Notification

```
🎁 Handling notification tap - Type: gift, Route: /gifts/received
🎁 Routing to gifts screen
```

---

## 🎨 Color/Icon Reference

### Notification Type Icons (Unicode)

```
Message     💬    U+1F4AC (Thought Bubble)
Gift        🎁    U+1F381 (Wrapped Gift)
Commission  🎨    U+1F3A8 (Artist Palette)
Event       📅    U+1F4C5 (Calendar)
```

### Associated Colors (Optional)

```
Message:    Blue         #667eea
Gift:       Red          #f5576c
Commission: Purple       #764ba2
Event:      Teal         #00f2fe
```

---

## 📱 Navigation Routes

### Recommended Route Structure

```
/messaging
  └─ Main messaging screen
     └─ Routes from message notifications

/gifts/received
  └─ Received gifts screen
     └─ Routes from gift notifications

/commissions/requests
  └─ Commission requests screen
     └─ Routes from commission notifications

/events/details
  └─ Event details screen
     └─ Routes from event notifications
```

---

## 🧪 Test Checklist

```
✅ Gift Notification
   [ ] Notification appears with 🎁 icon
   [ ] Shows sender name and gift name
   [ ] User can tap to open gifts
   [ ] No badge increment on app icon

✅ Commission Notification
   [ ] Notification appears with 🎨 icon
   [ ] Shows buyer name, description, budget
   [ ] User can tap to open commissions
   [ ] No badge increment on app icon

✅ Event Notification
   [ ] Notification appears with 📅 icon
   [ ] Shows event name, time, location
   [ ] User can tap to open event details
   [ ] No badge increment on app icon

✅ Message Notification
   [ ] Notification appears with 💬 icon
   [ ] Badge increments on app icon
   [ ] User can tap to open messaging
   [ ] Badge clears when messaging opens
```

---

## 🚀 Quick Reference Sheet

Print this and keep it handy!

```
╔════════════════════════════════════════════════════════╗
║          ARTBEAT NOTIFICATION TYPES CHEAT SHEET        ║
╠════════════════════════════════════════════════════════╣
║ Type        Icon  Method                              ║
╠════════════════════════════════════════════════════════╣
║ Message     💬    sendNotificationToUser()            ║
║ Gift        🎁    sendGiftNotification()              ║
║ Commission  🎨    sendCommissionNotification()        ║
║ Event       📅    sendEventReminderNotification()     ║
╠════════════════════════════════════════════════════════╣
║ Get NotificationService:                             ║
║   final notif = Provider.of<NotificationService>()   ║
╠════════════════════════════════════════════════════════╣
║ Call method with required parameters:                ║
║ • recipientUserId/userId                             ║
║ • title/senderName/eventName                         ║
║ • body/description/time                              ║
║ • Additional data (image URL, budget, location)      ║
╠════════════════════════════════════════════════════════╣
║ Badge: Only messages increment count                 ║
║ Routes: Automatic based on type                      ║
║ Storage: Firestore user.notifications collection     ║
║ Logs: Look for emoji prefixes in console             ║
╚════════════════════════════════════════════════════════╝
```

---

## 📚 Related Documentation

- `NOTIFICATION_TYPES_IMPLEMENTATION.md` - Full implementation
- `NOTIFICATION_TYPES_QUICK_REFERENCE.md` - Quick reference
- `NOTIFICATION_INTEGRATION_EXAMPLES.md` - Code examples
- `MULTI_TYPE_NOTIFICATIONS_SUMMARY.md` - Summary

---

**Everything you need to know at a glance!** 🎯
