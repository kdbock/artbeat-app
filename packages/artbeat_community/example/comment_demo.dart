import 'package:flutter/material.dart';
import 'package:artbeat_community/models/art_models.dart';
import 'package:artbeat_community/widgets/art_gallery_widgets.dart';

void main() {
  runApp(const CommentDemoApp());
}

class CommentDemoApp extends StatelessWidget {
  const CommentDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Comment System Demo',
      theme: ThemeData(primarySwatch: Colors.purple, useMaterial3: true),
      home: const CommentDemoScreen(),
    );
  }
}

class CommentDemoScreen extends StatelessWidget {
  const CommentDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final samplePost = ArtPost(
      id: 'demo_post_1',
      userId: 'artist_1',
      userName: 'Maya Rodriguez',
      userAvatarUrl: '',
      content: 'Just finished this digital painting! What do you think? 🎨✨',
      imageUrls: ['https://picsum.photos/400/300?random=1'],
      tags: ['digital', 'painting', 'art', 'creative'],
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      likesCount: 42,
      commentsCount: 8,
      isArtistPost: true,
      isUserVerified: true,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comment System Demo'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple.withValues(alpha: 0.05), Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Interactive Comment System',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap the comment icon below to expand the comment section. You can:',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                '• View existing comments\n'
                '• Add new comments\n'
                '• See real-time comment count updates\n'
                '• Smooth animations when expanding/collapsing',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ResponsiveArtPostCard(
                post: samplePost,
                onLike: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❤️ Liked!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Post tapped!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '✨ Features Implemented:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '• Expandable comment section with smooth animations\n'
                        '• Comment input field with send button\n'
                        '• Mock comments loaded on first expand\n'
                        '• Real-time comment posting simulation\n'
                        '• Dynamic comment count updates\n'
                        '• Responsive design that works on all screen sizes\n'
                        '• Overflow protection with limited comment display\n'
                        '• Beautiful UI with gradient backgrounds and shadows',
                        style: TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
