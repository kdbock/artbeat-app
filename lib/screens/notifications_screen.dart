import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_artwork/artbeat_artwork.dart'
    show ArtworkCleanupService;

/// Basic Notifications Screen for ARTbeat
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        appBar: EnhancedUniversalHeader(
          title: 'Notifications',
          showLogo: false,
          showSearch: false,
          showBackButton: true,
        ),
        body: Center(child: Text('Please log in to view notifications.')),
      );
    }
    return Scaffold(
      appBar: const EnhancedUniversalHeader(
        title: 'Notifications',
        showLogo: false,
        showSearch: false,
        showBackButton: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: const [
                SizedBox(height: 40),
                Icon(Icons.notifications, size: 64, color: Colors.grey),
                SizedBox(height: 24),
                Center(
                  child: Text(
                    'No notifications yet',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 8),
                Center(
                  child: Text(
                    'You’ll see updates, messages, and alerts here.',
                    style: TextStyle(fontSize: 15, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            );
          }
          final docs = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 24),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final title = data['title'] is String
                  ? data['title'] as String
                  : 'Notification';
              final body = data['body'] is String ? data['body'] as String : '';
              final ts = data['createdAt'] as Timestamp?;
              final date = ts != null ? ts.toDate() : null;
              final hasBody = body.isNotEmpty;
              return ListTile(
                leading: Icon(
                  Icons.notifications,
                  color: Theme.of(context).primaryColor,
                ),
                title: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasBody) Text(body),
                    if (date != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${date.toLocal()}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
                isThreeLine: hasBody,
              );
            },
          );
        },
      ),
      // Debug functionality for admin users
      floatingActionButton: _isAdminUser(user.uid) && kDebugMode
          ? FloatingActionButton.extended(
              onPressed: _runImageCleanup,
              label: const Text('Fix Images'),
              icon: const Icon(Icons.build),
            )
          : null,
    );
  }

  /// Check if user is admin
  bool _isAdminUser(String userId) {
    return userId == 'ARFuyX0C44PbYlHSUSlQx55b9vt2'; // Kristy Kelly's admin ID
  }

  /// Run image cleanup service
  Future<void> _runImageCleanup() async {
    final cleanupService = ArtworkCleanupService();

    // First check the specific problematic image
    await cleanupService.checkSpecificImage();

    // Then run general cleanup (dry run first to see what would be fixed)
    await cleanupService.cleanupBrokenArtworkImages(dryRun: true);

    // Now actually fix the broken images
    await cleanupService.cleanupBrokenArtworkImages(dryRun: false);
  }
}
