// ignore_for_file: avoid_print, avoid_catches_without_on_clauses, use_super_parameters
// ignore_for_file: sort_constructors_first, prefer_expression_function_bodies
// ignore_for_file: prefer_const_constructors, directives_ordering
// ignore_for_file: unawaited_futures, avoid_void_async, inference_failure_on_function_return_type
//
// ==============================================================================
// BADGE NOTIFICATION - COPY/PASTE CODE EXAMPLES
// ==============================================================================
// These are ready-to-use code snippets you can copy directly into your screens
// ==============================================================================

// ==============================================================================
// EXAMPLE 1: Basic Integration in Messaging Screen
// ==============================================================================
// Location: Your messaging screen file (e.g., MessagingScreen.dart)
// Copy & paste the initState() method into your messaging screen widget

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_messaging/artbeat_messaging.dart';

class MessagingScreen extends StatefulWidget {
  const MessagingScreen({Key? key}) : super(key: key);

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  @override
  void initState() {
    super.initState();
    // ✅ COPY THIS METHOD TO YOUR MESSAGING SCREEN
    _clearBadgeWhenScreenOpens();
  }

  /// Call this when messaging screen opens to clear badge and mark as read
  Future<void> _clearBadgeWhenScreenOpens() async {
    try {
      final chatService = Provider.of<ChatService>(context, listen: false);
      await chatService.onOpenMessaging();
      debugPrint('✅ Badge cleared on messaging screen open');
    } catch (e) {
      debugPrint('❌ Error clearing badge: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: Center(child: Text('Your messaging UI here')),
    );
  }
}

// ==============================================================================
// EXAMPLE 2: Without Provider (if you don't use Provider pattern)
// ==============================================================================

Future<void> clearBadgeWithoutProvider() async {
  try {
    final notificationService = NotificationService();
    await notificationService.onMessagingScreenOpened();
    debugPrint('✅ Badge cleared');
  } catch (e) {
    debugPrint('❌ Error clearing badge: $e');
  }
}

// ==============================================================================
// EXAMPLE 3: Display Badge Count in UI (e.g., in tab bar or button)
// ==============================================================================

// Use this widget to show unread count in your tab bar or message icon
class MessageBadgeIcon extends StatelessWidget {
  final NotificationService notificationService;

  const MessageBadgeIcon({Key? key, required this.notificationService})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: notificationService.getUnreadMessageCount(),
      initialData: 0,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Main message icon
            Icon(Icons.mail, size: 24),

            // Badge showing count
            if (count > 0)
              Positioned(
                right: -8,
                top: -8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
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
    );
  }
}

// Usage in your app bar or bottom nav:
// AppBar(
//   title: Text('Messages'),
//   actions: [
//     IconButton(
//       icon: MessageBadgeIcon(
//         notificationService: notificationService,
//       ),
//       onPressed: () {
//         Navigator.pushNamed(context, '/messaging');
//       },
//     ),
//   ],
// )

// ==============================================================================
// EXAMPLE 4: Manual Badge Control (for advanced use cases)
// ==============================================================================

Future<void> manualBadgeControl() async {
  final notificationService = NotificationService();

  // Get current badge count
  final currentCount = await notificationService.getBadgeCount();
  print('Current badge count: $currentCount');

  // Increment badge by 1
  final newCount = await notificationService.incrementBadgeCount();
  print('Badge incremented to: $newCount');

  // Decrement badge by 1
  final decremented = await notificationService.decrementBadgeCount();
  print('Badge decremented to: $decremented');

  // Set badge to specific number
  await notificationService.setBadgeCount(5);
  print('Badge set to: 5');

  // Clear badge completely
  await notificationService.clearBadge();
  print('Badge cleared');
}

// ==============================================================================
// EXAMPLE 5: Test Badge in Debug Button
// ==============================================================================
// Add this to a debug/test screen to manually test badge functionality

class BadgeTestScreen extends StatefulWidget {
  const BadgeTestScreen({Key? key}) : super(key: key);

  @override
  State<BadgeTestScreen> createState() => _BadgeTestScreenState();
}

class _BadgeTestScreenState extends State<BadgeTestScreen> {
  final notificationService = NotificationService();
  int _badgeCount = 0;

  @override
  void initState() {
    super.initState();
    _getBadgeCount();
  }

  Future<void> _getBadgeCount() async {
    final count = await notificationService.getBadgeCount();
    setState(() {
      _badgeCount = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Badge Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Current Badge Count: $_badgeCount',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await notificationService.incrementBadgeCount();
                _getBadgeCount();
              },
              child: const Text('Increment +1'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                await notificationService.decrementBadgeCount();
                _getBadgeCount();
              },
              child: const Text('Decrement -1'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                await notificationService.setBadgeCount(5);
                _getBadgeCount();
              },
              child: const Text('Set to 5'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                await notificationService.clearBadge();
                _getBadgeCount();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Clear Badge'),
            ),
            const SizedBox(height: 20),
            Text(
              'Watch your app icon for badge changes',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// EXAMPLE 6: Chat List with Badge Clearing
// ==============================================================================
// Integrate badge clearing when user taps on a chat

class ChatListItem extends StatelessWidget {
  final String chatId;
  final String chatName;
  final ChatService chatService;

  const ChatListItem({
    Key? key,
    required this.chatId,
    required this.chatName,
    required this.chatService,
  }) : super(key: key);

  void _onChatTap(BuildContext context) async {
    // Navigate to chat detail
    // Navigator.push(context, route);

    // Mark chat as read (this also decrements badge)
    await chatService.markChatAsRead(chatId);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(title: Text(chatName), onTap: () => _onChatTap(context));
  }
}

// ==============================================================================
// EXAMPLE 7: Initialize Badge System at App Startup
// ==============================================================================
// Location: main.dart or your app initialization code

Future<void> initializeBadgeSystem() async {
  try {
    // Create notification service
    final notificationService = NotificationService();

    // Initialize (includes badge setup)
    await notificationService.initialize();

    print('✅ Badge system initialized');

    // Optional: Get initial badge count
    final badgeCount = await notificationService.getBadgeCount();
    print('Current badge count: $badgeCount');
  } catch (e) {
    print('❌ Error initializing badge system: $e');
  }
}

// Call this in your main() or app initialization:
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await initializeBadgeSystem();  // ← Add this line
//   runApp(const MyApp());
// }

// ==============================================================================
// EXAMPLE 8: Bottom Navigation with Badge Indicator
// ==============================================================================

class BottomNavWithBadge extends StatelessWidget {
  final NotificationService notificationService;
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavWithBadge({
    Key? key,
    required this.notificationService,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: notificationService.getUnreadMessageCount(),
      initialData: 0,
      builder: (context, snapshot) {
        final badgeCount = snapshot.data ?? 0;

        return BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            // Clear badge if tapping messages tab
            if (index == 2) {
              notificationService.onMessagingScreenOpened();
            }
            onTap(index);
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Favorites',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                alignment: Alignment.topRight,
                children: [
                  Icon(Icons.mail),
                  if (badgeCount > 0)
                    Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
              label: 'Messages',
            ),
          ],
        );
      },
    );
  }
}

// ==============================================================================
// SUMMARY OF KEY METHODS
// ==============================================================================
/*
Most Common Use Cases:

1. Clear badge when opening messaging screen:
   await chatService.onOpenMessaging();

2. Get badge count:
   final count = await notificationService.getBadgeCount();

3. Update badge in UI:
   StreamBuilder<int>(
     stream: notificationService.getUnreadMessageCount(),
     builder: (context, snapshot) { ... }
   )

4. Manual control (rarely needed):
   await notificationService.incrementBadgeCount();
   await notificationService.clearBadge();
   await notificationService.setBadgeCount(5);

5. Auto-decrement when reading chat:
   await chatService.markChatAsRead(chatId);  // Built-in badge decrement
*/

// ==============================================================================
// END OF EXAMPLES
// ==============================================================================
