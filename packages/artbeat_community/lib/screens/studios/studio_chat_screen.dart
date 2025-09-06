import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import '../../theme/community_colors.dart';
import '../../models/studio_model.dart';
import '../../services/firestore_service.dart';

class StudioChatScreen extends StatefulWidget {
  final String studioId;
  final StudioModel? studio;

  const StudioChatScreen({super.key, required this.studioId, this.studio});

  @override
  _StudioChatScreenState createState() => _StudioChatScreenState();
}

class _StudioChatScreenState extends State<StudioChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  StudioModel? _studio;
  bool _isLoading = true;
  Map<String, bool> _onlineUsers = {};

  @override
  void initState() {
    super.initState();
    _loadStudioDetails();
    _setupOnlineStatus();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadStudioDetails() async {
    if (widget.studio != null) {
      setState(() {
        _studio = widget.studio;
        _isLoading = false;
      });
      return;
    }

    try {
      final studios = await _firestoreService.getStudios();
      final studio = studios.firstWhere((s) => s.id == widget.studioId);
      setState(() {
        _studio = studio;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading studio: $e')));
      }
    }
  }

  void _setupOnlineStatus() {
    // Set up online status tracking for studio members
    final user = _auth.currentUser;
    if (user != null) {
      _firestore
          .collection('studios')
          .doc(widget.studioId)
          .collection('online_users')
          .doc(user.uid)
          .set({'online': true, 'lastSeen': FieldValue.serverTimestamp()});

      // Listen for online status changes
      _firestore
          .collection('studios')
          .doc(widget.studioId)
          .collection('online_users')
          .snapshots()
          .listen((snapshot) {
            final onlineUsers = <String, bool>{};
            for (final doc in snapshot.docs) {
              onlineUsers[doc.id] = doc.data()['online'] as bool? ?? false;
            }
            setState(() => _onlineUsers = onlineUsers);
          });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore
            .collection('studios')
            .doc(widget.studioId)
            .collection('messages')
            .add({
              'text': _messageController.text.trim(),
              'senderId': user.uid,
              'senderName': user.displayName ?? 'Anonymous',
              'timestamp': FieldValue.serverTimestamp(),
              'messageType': 'text',
            });
        _messageController.clear();

        // Scroll to bottom after sending message
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
        }
      }
    }
  }

  Widget _buildMessageBubble(DocumentSnapshot messageDoc) {
    final message = messageDoc.data() as Map<String, dynamic>;
    final isCurrentUser = message['senderId'] == _auth.currentUser?.uid;
    final timestamp = (message['timestamp'] as Timestamp?)?.toDate();

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isCurrentUser ? CommunityColors.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isCurrentUser)
              Text(
                message['senderName'] as String? ?? 'Unknown',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isCurrentUser ? Colors.white70 : Colors.black54,
                ),
              ),
            Text(
              message['text'] as String? ?? '',
              style: TextStyle(
                color: isCurrentUser ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
            if (timestamp != null)
              Text(
                _formatTimestamp(timestamp),
                style: TextStyle(
                  fontSize: 10,
                  color: isCurrentUser ? Colors.white70 : Colors.black45,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildOnlineIndicator() {
    final onlineCount = _onlineUsers.values.where((online) => online).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, color: Colors.green, size: 12),
          const SizedBox(width: 4),
          Text(
            '$onlineCount online',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return core.MainLayout(
      scaffoldKey: scaffoldKey,
      currentIndex: -1, // Detail screen
      appBar: core.EnhancedUniversalHeader(
        title: _studio?.name ?? 'Studio Chat',
        backgroundGradient: CommunityColors.communityGradient,
        titleGradient: const LinearGradient(
          colors: [Colors.white, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildOnlineIndicator(),
          ),
        ],
      ),
      child: Column(
        children: [
          // Studio info header
          if (_studio != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade50,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: CommunityColors.primary,
                    child: Text(
                      _studio!.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _studio!.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_studio!.memberList.length} members',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Messages list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('studios')
                  .doc(widget.studioId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        Text(
                          'Start the conversation!',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(messages[index]);
                  },
                );
              },
            ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: CommunityColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
