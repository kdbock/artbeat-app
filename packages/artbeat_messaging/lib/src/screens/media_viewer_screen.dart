import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'dart:io';

class MediaViewerScreen extends StatelessWidget {
  final List<String> mediaUrls;
  final int initialIndex;
  final String? senderName;

  const MediaViewerScreen({
    super.key,
    required this.mediaUrls,
    this.initialIndex = 0,
    this.senderName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final PageController pageController = PageController(
      initialPage: initialIndex,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          senderName != null ? 'Shared by $senderName' : 'Media Viewer',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareMedia(mediaUrls[initialIndex]),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadMedia(context, mediaUrls[initialIndex]),
          ),
        ],
      ),
      body: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (BuildContext context, int index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: NetworkImage(mediaUrls[index]),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            heroAttributes: PhotoViewHeroAttributes(tag: mediaUrls[index]),
          );
        },
        itemCount: mediaUrls.length,
        loadingBuilder: (context, ImageChunkEvent? event) => Center(
          child: SizedBox(
            width: 20.0,
            height: 20.0,
            child: CircularProgressIndicator(
              value: event == null
                  ? 0
                  : event.cumulativeBytesLoaded /
                        (event.expectedTotalBytes ?? 1),
              valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
            ),
          ),
        ),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        pageController: pageController,
      ),
    );
  }

  Future<void> _shareMedia(String mediaUrl) async {
    try {
      await SharePlus.instance.share(ShareParams(text: mediaUrl));
    } catch (e) {
      // debugPrint('Error sharing media: $e');
    }
  }

  Future<void> _downloadMedia(BuildContext context, String mediaUrl) async {
    try {
      final response = await http.get(Uri.parse(mediaUrl));
      final documentsDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${documentsDir.path}/media_$timestamp.jpg');
      await file.writeAsBytes(response.bodyBytes);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Media saved to ${file.path}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to download media'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
