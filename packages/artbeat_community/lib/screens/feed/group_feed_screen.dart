import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../../models/post_model.dart';
import '../../widgets/enhanced_post_card.dart';
import '../../models/group_models.dart';
import 'create_group_post_screen.dart';

/// Group feed screen showing posts from a specific group
class GroupFeedScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupFeedScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupFeedScreen> createState() => _GroupFeedScreenState();
}

class _GroupFeedScreenState extends State<GroupFeedScreen> {
  List<PostModel> _posts = [];
  bool _isLoading = true;
  bool _isMember = false;
  bool _checkingMembership = true;
  GroupType? _groupType;

  @override
  void initState() {
    super.initState();
    _checkMembership();
    _loadGroupType();
    _loadGroupPosts();
  }

  Future<void> _checkMembership() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _checkingMembership = false);
      return;
    }

    try {
      final membershipDoc = await FirebaseFirestore.instance
          .collection('groupMembers')
          .where('groupId', isEqualTo: widget.groupId)
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      setState(() {
        _isMember = membershipDoc.docs.isNotEmpty;
        _checkingMembership = false;
      });
    } catch (e) {
      AppLogger.error('Error checking group membership: $e');
      setState(() => _checkingMembership = false);
    }
  }

  Future<void> _loadGroupType() async {
    try {
      final groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      if (groupDoc.exists) {
        final data = groupDoc.data();
        final groupTypeString = data?['groupType'] as String?;
        if (groupTypeString != null) {
          _groupType = GroupType.values.firstWhere(
            (type) => type.value == groupTypeString,
            orElse: () => GroupType.artist, // default
          );
        }
      }
    } catch (e) {
      AppLogger.error('Error loading group type: $e');
    }
  }

  Future<void> _loadGroupPosts() async {
    setState(() => _isLoading = true);

    try {
      // Load posts from this group
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('groupId', isEqualTo: widget.groupId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final posts = postsSnapshot.docs.map((doc) {
        return PostModel.fromDocument(doc);
      }).toList();

      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading group posts: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _joinGroup() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to join groups')),
      );
      return;
    }

    try {
      // Add user to group members
      await FirebaseFirestore.instance.collection('groupMembers').add({
        'groupId': widget.groupId,
        'userId': user.uid,
        'role': 'member',
        'joinedAt': FieldValue.serverTimestamp(),
      });

      // Update group member count
      final groupRef = FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId);
      await groupRef.update({'memberCount': FieldValue.increment(1)});

      setState(() => _isMember = true);

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully joined ${widget.groupName}!')),
      );
    } catch (e) {
      AppLogger.error('Error joining group: $e');
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to join group. Please try again.'),
        ),
      );
    }
  }

  Future<void> _leaveGroup() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Remove user from group members
      final membershipDocs = await FirebaseFirestore.instance
          .collection('groupMembers')
          .where('groupId', isEqualTo: widget.groupId)
          .where('userId', isEqualTo: user.uid)
          .get();

      for (final doc in membershipDocs.docs) {
        await doc.reference.delete();
      }

      // Update group member count
      final groupRef = FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId);
      await groupRef.update({'memberCount': FieldValue.increment(-1)});

      setState(() => _isMember = false);

      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text('Left ${widget.groupName}')));
    } catch (e) {
      AppLogger.error('Error leaving group: $e');
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to leave group. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 3, // Community tab
      appBar: EnhancedUniversalHeader(
        title: widget.groupName,
        showBackButton: true,
        showSearch: false,
        showDeveloperTools: false,
        backgroundGradient: const LinearGradient(
          colors: [ArtbeatColors.primaryPurple, ArtbeatColors.primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        titleGradient: const LinearGradient(
          colors: [Colors.white, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        foregroundColor: Colors.white,
        actions: [
          if (!_checkingMembership) ...[
            if (_isMember)
              TextButton.icon(
                onPressed: _leaveGroup,
                icon: const Icon(Icons.exit_to_app, color: Colors.white),
                label: const Text(
                  'Leave',
                  style: TextStyle(color: Colors.white),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _joinGroup,
                icon: const Icon(Icons.group_add),
                label: const Text('Join'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: ArtbeatColors.primaryPurple,
                ),
              ),
          ],
        ],
      ),
      drawer: const ArtbeatDrawer(),
      child: Stack(
        children: [
          _checkingMembership
              ? const Center(child: CircularProgressIndicator())
              : !_isMember
              ? _buildJoinPrompt()
              : _buildFeed(),
          if (_isMember)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: () => _createGroupPost(context),
                backgroundColor: ArtbeatColors.primaryPurple,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildJoinPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.group,
                size: 64,
                color: ArtbeatColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Join ${widget.groupName}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: ArtbeatColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Become a member to view posts and participate in this community.',
              style: TextStyle(
                fontSize: 16,
                color: ArtbeatColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _joinGroup,
              icon: const Icon(Icons.group_add),
              label: const Text('Join Group'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ArtbeatColors.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeed() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            ArtbeatColors.primaryPurple,
          ),
        ),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.article_outlined,
                size: 64,
                color: ArtbeatColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No posts yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ArtbeatColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Be the first to share something with the group!',
              style: TextStyle(color: ArtbeatColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGroupPosts,
      color: ArtbeatColors.primaryPurple,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          return EnhancedPostCard(
            post: post,
            onLike: () => _handleLike(post),
            onComment: () => _handleComment(post),
            onShare: () => _handleShare(post),
          );
        },
      ),
    );
  }

  void _createGroupPost(BuildContext context) {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (context) => CreateGroupPostScreen(
              groupType: _groupType ?? GroupType.artist,
              postType: 'update',
              groupId: widget.groupId,
            ),
          ),
        )
        .then((_) => _loadGroupPosts()); // Refresh posts after creating
  }

  void _handleLike(PostModel post) {
    // Handle like functionality
    AppLogger.info('Liked post: ${post.id}');
  }

  void _handleComment(PostModel post) {
    // Handle comment functionality
    AppLogger.info('Commented on post: ${post.id}');
  }

  void _handleShare(PostModel post) {
    // Handle share functionality
    AppLogger.info('Shared post: ${post.id}');
  }
}
