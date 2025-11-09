import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show EnhancedUniversalHeader, MainLayout;
import 'package:easy_localization/easy_localization.dart';

class ProfilePictureViewerScreen extends StatefulWidget {
  final String imageUrl;

  const ProfilePictureViewerScreen({super.key, required this.imageUrl});

  @override
  State<ProfilePictureViewerScreen> createState() =>
      _ProfilePictureViewerScreenState();
}

class _ProfilePictureViewerScreenState
    extends State<ProfilePictureViewerScreen> {
  // For zoom functionality
  final TransformationController _transformationController =
      TransformationController();
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();

    // Set preferred orientation to portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Reset orientation to portrait only when leaving
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: _isFullScreen
            ? null
            : EnhancedUniversalHeader(
                title: 'profile_picture_title'.tr(),
                showLogo: false,
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () {
                      // Implement share functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Share functionality would be implemented here',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
        body: GestureDetector(
          onTap: () {
            setState(() {
              _isFullScreen = !_isFullScreen;
            });
          },
          child: Center(
            child: Hero(
              tag: 'profile_photo',
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.5,
                maxScale: 4.0,
                child: widget.imageUrl.isNotEmpty
                    ? Image.network(
                        widget.imageUrl,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.error,
                                  color: Colors.white,
                                  size: 48,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Could not load image',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 100,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
