import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_capture/artbeat_capture.dart';

/// Screen to display user's captured art
class MyCapturesScreen extends StatefulWidget {
  final CaptureModel? initialCapture;

  const MyCapturesScreen({super.key, this.initialCapture});

  @override
  State<MyCapturesScreen> createState() => _MyCapturesScreenState();
}

class _MyCapturesScreenState extends State<MyCapturesScreen> {
  final CaptureService _captureService = CaptureService();
  List<CaptureModel> _captures = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCaptures();
  }

  Future<void> _loadCaptures() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.uid == null) {
        setState(() {
          _captures = [];
          _isLoading = false;
        });
        return;
      }

      final captures = await _captureService.getCapturesForUser(user!.uid);
      debugPrint(
        '📸 Loaded ${captures.length} captures for user in my_captures_screen',
      );
      if (mounted) {
        setState(() {
          _captures = captures;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading captures: $e');
      if (mounted) {
        setState(() {
          _captures = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to load captures. Please try again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadCaptures,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Captures'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadCaptures();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _captures.isEmpty
          ? _buildEmptyState()
          : _buildCapturesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Captures Yet',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Start capturing art around you to see them here!',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed('/capture/camera').then((_) {
                  // Refresh captures when returning from camera
                  _loadCaptures();
                });
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Capture Art'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapturesList() {
    return RefreshIndicator(
      onRefresh: _loadCaptures,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: _captures.length,
        itemBuilder: (context, index) {
          final capture = _captures[index];
          return _buildCaptureCard(capture);
        },
      ),
    );
  }

  Widget _buildCaptureCard(CaptureModel capture) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showCaptureDetail(capture),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey[200]),
                child: capture.imageUrl.isNotEmpty
                    ? Image.network(
                        capture.thumbnailUrl ?? capture.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                              size: 40,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.image,
                          color: Colors.grey,
                          size: 40,
                        ),
                      ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      capture.title ?? 'Untitled',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (capture.artistName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'by ${capture.artistName}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          capture.isPublic ? Icons.public : Icons.lock,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          capture.isPublic ? 'Public' : 'Private',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (!capture.isProcessed) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.hourglass_empty,
                            size: 12,
                            color: Colors.orange[600],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Processing',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCaptureDetail(CaptureModel capture) {
    // Navigate to capture detail screen instead of modal
    Navigator.of(
      context,
    ).pushNamed('/capture/detail', arguments: capture.id).then((_) {
      // Refresh captures when returning from detail
      _loadCaptures();
    });
  }
}
