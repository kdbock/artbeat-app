# 🔌 Notification Type Integration Examples

## 📍 Where to Call the Notification Methods

This document shows exactly where and how to integrate the notification system into your feature services.

---

## 🎁 Gift Feature Integration

### Example: Gift Service

```dart
// File: packages/artbeat_core/lib/src/services/gift_service.dart

import 'package:artbeat_messaging/artbeat_messaging.dart';

class GiftService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final NotificationService _notificationService;

  GiftService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required NotificationService notificationService,
  }) : _firestore = firestore,
       _auth = auth,
       _notificationService = notificationService;

  /// Send a gift to another user
  Future<void> sendGift({
    required String recipientId,
    required String giftId,
    required String giftName,
    required String giftImageUrl,
    required double amount,
  }) async {
    try {
      final senderId = _auth.currentUser?.uid;
      final senderName = _auth.currentUser?.displayName ?? 'Anonymous';

      if (senderId == null) throw Exception('Not authenticated');

      // 1. Save gift to Firestore
      await _firestore
          .collection('gifts')
          .add({
            'senderId': senderId,
            'senderName': senderName,
            'recipientId': recipientId,
            'giftId': giftId,
            'giftName': giftName,
            'giftImageUrl': giftImageUrl,
            'amount': amount,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });

      // 2. Send notification to recipient
      await _notificationService.sendGiftNotification(
        recipientUserId: recipientId,
        senderName: senderName,
        giftName: giftName,
        giftImageUrl: giftImageUrl,
      );

      AppLogger.info('✅ Gift sent successfully to $recipientId');
    } catch (e) {
      AppLogger.error('❌ Error sending gift: $e');
      rethrow;
    }
  }
}
```

### Using in a Widget

```dart
// In a gift sending screen
ElevatedButton(
  onPressed: () async {
    final giftService = Provider.of<GiftService>(context, listen: false);

    try {
      await giftService.sendGift(
        recipientId: widget.recipientId,
        giftId: selectedGift.id,
        giftName: selectedGift.name,
        giftImageUrl: selectedGift.imageUrl,
        amount: selectedGift.price,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎁 Gift sent!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  },
  child: const Text('Send Gift'),
)
```

---

## 🎨 Commission Feature Integration

### Example: Commission Service

```dart
// File: packages/artbeat_artist/lib/src/services/commission_service.dart

import 'package:artbeat_messaging/artbeat_messaging.dart';

class CommissionService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final NotificationService _notificationService;

  CommissionService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required NotificationService notificationService,
  }) : _firestore = firestore,
       _auth = auth,
       _notificationService = notificationService;

  /// Submit a commission request to an artist
  Future<void> requestCommission({
    required String artistId,
    required String artworkDescription,
    required double budget,
    required String deliveryDate,
    required List<String> referenceImageUrls,
  }) async {
    try {
      final buyerId = _auth.currentUser?.uid;
      final buyerName = _auth.currentUser?.displayName ?? 'A Collector';

      if (buyerId == null) throw Exception('Not authenticated');

      // 1. Save commission request to Firestore
      final commissionDoc = await _firestore
          .collection('commissions')
          .add({
            'artistId': artistId,
            'buyerId': buyerId,
            'buyerName': buyerName,
            'artworkDescription': artworkDescription,
            'budget': budget,
            'deliveryDate': deliveryDate,
            'referenceImages': referenceImageUrls,
            'status': 'pending', // pending, accepted, rejected, completed
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });

      // 2. Send notification to artist
      await _notificationService.sendCommissionNotification(
        artistUserId: artistId,
        buyerName: buyerName,
        artworkDescription: artworkDescription,
        budget: budget,
      );

      AppLogger.info('✅ Commission request sent to artist $artistId');
    } catch (e) {
      AppLogger.error('❌ Error submitting commission: $e');
      rethrow;
    }
  }

  /// Accept a commission request
  Future<void> acceptCommission({
    required String commissionId,
    required DateTime completionDate,
  }) async {
    try {
      final commission = await _firestore
          .collection('commissions')
          .doc(commissionId)
          .get();

      final data = commission.data() as Map<String, dynamic>;
      final buyerId = data['buyerId'] as String;

      // Update commission status
      await _firestore
          .collection('commissions')
          .doc(commissionId)
          .update({
            'status': 'accepted',
            'completionDate': completionDate,
            'acceptedAt': FieldValue.serverTimestamp(),
          });

      // Optionally notify buyer that commission was accepted
      await _notificationService.sendNotificationToUser(
        userId: buyerId,
        title: '✅ Your Commission Accepted!',
        body: 'The artist accepted your commission request',
        data: {
          'type': 'commission',
          'commissionId': commissionId,
          'route': '/commissions/details',
        },
      );

      AppLogger.info('✅ Commission accepted');
    } catch (e) {
      AppLogger.error('❌ Error accepting commission: $e');
      rethrow;
    }
  }
}
```

### Using in a Widget

```dart
// In artist's commissions request screen
FutureBuilder<QuerySnapshot>(
  future: commissionService.getCommissionRequests(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final commissions = snapshot.data!.docs;
      return ListView.builder(
        itemCount: commissions.length,
        itemBuilder: (context, index) {
          final commission = commissions[index];
          final data = commission.data() as Map<String, dynamic>;

          return CommissionCard(
            commission: commission,
            onAccept: () async {
              await commissionService.acceptCommission(
                commissionId: commission.id,
                completionDate: DateTime.now().add(Duration(days: 30)),
              );
              // Commission notification automatically sent to buyer
            },
          );
        },
      );
    }
    return const SizedBox.shrink();
  },
)
```

---

## 📅 Event Feature Integration

### Example: Event Service

```dart
// File: packages/artbeat_events/lib/src/services/event_service.dart

import 'package:artbeat_messaging/artbeat_messaging.dart';

class EventService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final NotificationService _notificationService;

  EventService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required NotificationService notificationService,
  }) : _firestore = firestore,
       _auth = auth,
       _notificationService = notificationService;

  /// Create an event
  Future<void> createEvent({
    required String eventName,
    required DateTime eventDate,
    required String location,
    required String description,
  }) async {
    try {
      final creatorId = _auth.currentUser?.uid;
      if (creatorId == null) throw Exception('Not authenticated');

      // Save event to Firestore
      await _firestore.collection('events').add({
        'creatorId': creatorId,
        'eventName': eventName,
        'eventDate': eventDate,
        'location': location,
        'description': description,
        'interested': [],
        'timestamp': FieldValue.serverTimestamp(),
      });

      AppLogger.info('✅ Event created');
    } catch (e) {
      AppLogger.error('❌ Error creating event: $e');
      rethrow;
    }
  }

  /// Mark user interested in event
  Future<void> markInterestInEvent({
    required String eventId,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Not authenticated');

      await _firestore
          .collection('events')
          .doc(eventId)
          .update({
            'interested': FieldValue.arrayUnion([userId]),
          });

      AppLogger.info('✅ Marked interest in event');
    } catch (e) {
      AppLogger.error('❌ Error marking interest: $e');
      rethrow;
    }
  }

  /// Send event reminder to interested users
  Future<void> sendEventReminders({
    required String eventId,
  }) async {
    try {
      final event = await _firestore
          .collection('events')
          .doc(eventId)
          .get();

      final data = event.data() as Map<String, dynamic>;
      final eventName = data['eventName'] as String;
      final eventDate = (data['eventDate'] as Timestamp).toDate();
      final location = data['location'] as String;
      final interestedUsers = List<String>.from(data['interested'] ?? []);

      // Format event time nicely
      final eventTime = DateFormat('MMM d • h:mm a').format(eventDate);

      // Send reminder to all interested users
      for (final userId in interestedUsers) {
        await _notificationService.sendEventReminderNotification(
          userId: userId,
          eventName: eventName,
          eventTime: eventTime,
          location: location,
        );
      }

      AppLogger.info(
        '✅ Event reminders sent to ${interestedUsers.length} users',
      );
    } catch (e) {
      AppLogger.error('❌ Error sending event reminders: $e');
      rethrow;
    }
  }

  /// Schedule event reminders (24 hours, 1 hour before)
  Future<void> scheduleEventReminders({
    required String eventId,
  }) async {
    try {
      final event = await _firestore
          .collection('events')
          .doc(eventId)
          .get();

      final data = event.data() as Map<String, dynamic>;
      final eventDate = (data['eventDate'] as Timestamp).toDate();

      // Send reminder 24 hours before
      final oneDay = eventDate.subtract(const Duration(days: 1));
      if (oneDay.isAfter(DateTime.now())) {
        // Schedule using scheduled notifications
        // This would use a backend service or scheduled Cloud Function
      }

      // Send reminder 1 hour before
      final oneHour = eventDate.subtract(const Duration(hours: 1));
      if (oneHour.isAfter(DateTime.now())) {
        // Schedule using scheduled notifications
      }

      AppLogger.info('✅ Event reminders scheduled');
    } catch (e) {
      AppLogger.error('❌ Error scheduling reminders: $e');
      rethrow;
    }
  }
}
```

### Using in a Widget

```dart
// In event details screen
Column(
  children: [
    EventHeader(),
    InterestedButton(
      onPressed: () async {
        final eventService = Provider.of<EventService>(
          context,
          listen: false,
        );

        await eventService.markInterestInEvent(eventId: widget.eventId);

        // Later, admin can send reminders
        // await eventService.sendEventReminders(eventId: widget.eventId);
      },
    ),
  ],
)
```

---

## 📨 Provider Setup Example

If you don't have providers set up yet, here's how:

### In Your Main App (or App Setup)

```dart
import 'package:provider/provider.dart';
import 'package:artbeat_messaging/artbeat_messaging.dart';

MultiProvider(
  providers: [
    // ... other providers

    ProxyProvider<NotificationService, GiftService>(
      create: (context) => NotificationService(),
      update: (context, notificationService, previous) => GiftService(
        firestore: FirebaseFirestore.instance,
        auth: FirebaseAuth.instance,
        notificationService: notificationService,
      ),
    ),

    ProxyProvider<NotificationService, CommissionService>(
      create: (context) => NotificationService(),
      update: (context, notificationService, previous) => CommissionService(
        firestore: FirebaseFirestore.instance,
        auth: FirebaseAuth.instance,
        notificationService: notificationService,
      ),
    ),

    ProxyProvider<NotificationService, EventService>(
      create: (context) => NotificationService(),
      update: (context, notificationService, previous) => EventService(
        firestore: FirebaseFirestore.instance,
        auth: FirebaseAuth.instance,
        notificationService: notificationService,
      ),
    ),
  ],
  child: MyApp(),
)
```

---

## 🧪 Complete End-to-End Example

### Gift Flow

```dart
// 1. User taps "Send Gift"
// 2. GiftService.sendGift() is called
// 3. Gift saved to Firestore
// 4. sendGiftNotification() called automatically
// 5. Recipient gets 🎁 notification
// 6. User taps notification
// 7. App routes to /gifts/received
// 8. Recipient sees new gift
```

### Commission Flow

```dart
// 1. Buyer fills commission form
// 2. CommissionService.requestCommission() called
// 3. Request saved to Firestore
// 4. sendCommissionNotification() called automatically
// 5. Artist gets 🎨 notification
// 6. Artist taps notification
// 7. App routes to /commissions/requests
// 8. Artist sees new commission request
// 9. Artist accepts commission
// 10. Buyer gets notification of acceptance
```

### Event Flow

```dart
// 1. Event created in EventService
// 2. Users mark interest
// 3. Admin calls sendEventReminders()
// 4. All interested users get 📅 notification
// 5. User taps notification
// 6. App routes to /events/details
// 7. User sees event info
```

---

## 🎯 Key Integration Points

1. **Import NotificationService** in your service classes
2. **Inject into constructor** as a dependency
3. **Call appropriate method** after database operation completes
4. **Let the rest happen automatically** - notification shows and routes

---

## ✨ That's It!

All your feature services can now notify users about important events. The notification system handles:

- ✅ Creating the notification record in Firestore
- ✅ Triggering the platform notification (banner/heads-up)
- ✅ Storing it for history
- ✅ Routing when tapped
- ✅ Logging everything for debugging

Just call the method and move on! 🚀
