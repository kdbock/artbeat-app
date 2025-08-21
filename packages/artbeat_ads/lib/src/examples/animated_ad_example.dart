import 'package:flutter/material.dart';
import '../widgets/ad_display_widget.dart';
import '../models/ad_display_type.dart';

/// Example showing how to use AdDisplayWidget with four animated images
/// This demonstrates the gif-like cycling animation through multiple images
class AnimatedAdExample extends StatelessWidget {
  const AnimatedAdExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Animated Ad Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rectangle Ad (300x100) with 4 Images:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Rectangle ad with 4 images cycling every 3 seconds (built-in)
            AdDisplayWidget(
              imageUrl: '', // Not used when artworkUrls is provided
              artworkUrls: const [
                'https://firebasestorage.googleapis.com/v0/b/your-project/o/ads%2Fimage1.jpg?alt=media',
                'https://firebasestorage.googleapis.com/v0/b/your-project/o/ads%2Fimage2.jpg?alt=media',
                'https://firebasestorage.googleapis.com/v0/b/your-project/o/ads%2Fimage3.jpg?alt=media',
                'https://firebasestorage.googleapis.com/v0/b/your-project/o/ads%2Fimage4.jpg?alt=media',
              ],
              title: 'Sample Ad', // Not displayed in image-only mode
              description:
                  'This is a sample ad', // Not displayed in image-only mode
              displayType: AdDisplayType.rectangle,
              onTap: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Ad tapped!')));
              },
            ),

            const SizedBox(height: 32),

            const Text(
              'Square Ad (100x100) with 4 Images:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Square ad with 4 images cycling every 3 seconds (built-in)
            AdDisplayWidget(
              imageUrl: '', // Not used when artworkUrls is provided
              artworkUrls: const [
                'https://firebasestorage.googleapis.com/v0/b/your-project/o/ads%2Fsquare1.jpg?alt=media',
                'https://firebasestorage.googleapis.com/v0/b/your-project/o/ads%2Fsquare2.jpg?alt=media',
                'https://firebasestorage.googleapis.com/v0/b/your-project/o/ads%2Fsquare3.jpg?alt=media',
                'https://firebasestorage.googleapis.com/v0/b/your-project/o/ads%2Fsquare4.jpg?alt=media',
              ],
              title: 'Square Ad', // Not displayed in image-only mode
              description:
                  'Square format ad', // Not displayed in image-only mode
              displayType: AdDisplayType.square,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Square ad tapped!')),
                );
              },
            ),

            const SizedBox(height: 32),

            const Text(
              'Features:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Images cycle automatically with smooth fade transitions\n'
              '• Small progress indicators show current image\n'
              '• Fixed 3-second rotation interval for consistency\n'
              '• Uses local placeholder images (no Firebase Storage needed)\n'
              '• Tap-to-action functionality\n'
              '• Gif-like animation experience',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
