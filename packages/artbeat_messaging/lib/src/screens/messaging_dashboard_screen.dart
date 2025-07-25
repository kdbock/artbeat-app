import 'package:flutter/material.dart';
// Assume these are available in artbeat_core or messaging module
// import 'package:artbeat_core/models/user_model.dart';
// import '../services/messaging_service.dart';

class MessagingDashboardScreen extends StatefulWidget {
  const MessagingDashboardScreen({Key? key}) : super(key: key);

  @override
  State<MessagingDashboardScreen> createState() =>
      _MessagingDashboardScreenState();
}

class _MessagingDashboardScreenState extends State<MessagingDashboardScreen> {
  // Dummy data for demonstration; replace with actual service calls
  List<Map<String, dynamic>> onlineUsers = [
    {
      'name': 'Alice',
      'avatar': 'https://i.pravatar.cc/150?img=1',
      'isOnline': true,
    },
    {
      'name': 'Bob',
      'avatar': 'https://i.pravatar.cc/150?img=2',
      'isOnline': true,
    },
    {
      'name': 'Charlie',
      'avatar': 'https://i.pravatar.cc/150?img=3',
      'isOnline': true,
    },
  ];

  List<Map<String, dynamic>> recentChats = [
    {
      'name': 'Alice',
      'avatar': 'https://i.pravatar.cc/150?img=1',
      'lastMessage': 'Hey, are you coming to the event?',
      'timestamp': '2 min ago',
      'unread': 2,
    },
    {
      'name': 'Bob',
      'avatar': 'https://i.pravatar.cc/150?img=2',
      'lastMessage': 'Let’s catch up soon!',
      'timestamp': '10 min ago',
      'unread': 0,
    },
    {
      'name': 'Charlie',
      'avatar': 'https://i.pravatar.cc/150?img=3',
      'lastMessage': 'Sent you the artwork details.',
      'timestamp': '1 hr ago',
      'unread': 1,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Online Users',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: onlineUsers.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final user = onlineUsers[index];
                  final String avatar = user['avatar'] as String;
                  final String name = user['name'] as String;
                  final bool isOnline = user['isOnline'] as bool;
                  return SizedBox(
                    width: 44,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: NetworkImage(avatar),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isOnline ? Colors.green : Colors.grey,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(fontSize: 9),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Recent Chats',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final chat = recentChats[index];
              final String avatar = chat['avatar'] as String;
              final String name = chat['name'] as String;
              final String lastMessage = chat['lastMessage'] as String;
              final String timestamp = chat['timestamp'] as String;
              final int unread = chat['unread'] as int;
              return Column(
                children: [
                  SizedBox(
                    height: 68, // Reduced height for ListTile
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(avatar),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (unread > 0)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$unread',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        timestamp,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      onTap: () {
                        // TODO: Navigate to chat detail screen
                      },
                    ),
                  ),
                  const Divider(height: 1),
                ],
              );
            }, childCount: recentChats.length),
          ),
          // Add bottom padding to prevent overflow
          const SliverToBoxAdapter(
            child: SizedBox(height: 80), // Space for FAB
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.chat),
        onPressed: () {
          // TODO: Start new chat
        },
      ),
    );
  }
}
