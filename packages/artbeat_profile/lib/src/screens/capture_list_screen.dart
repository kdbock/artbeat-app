import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_capture/artbeat_capture.dart';
// If CaptureService is not exported by artbeat_capture.dart, import its file directly:
// import 'package:artbeat_capture/src/services/capture_service.dart';

class CaptureListScreen extends StatefulWidget {
  const CaptureListScreen({super.key});

  @override
  State<CaptureListScreen> createState() => _CaptureListScreenState();
}

class _CaptureListScreenState extends State<CaptureListScreen> {
  final CaptureService _captureService = CaptureService();
  String? _currentUserId;
  bool _isLoading = false;
  List<CaptureModel> _captures = [];
  String? _errorMessage;
  final bool _isRefreshing = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _fetchCaptures();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCaptures() async {
    if (_isRefreshing) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final captures = await _captureService.getCapturesForUser(_currentUserId);
      debugPrint(
        '📸 Loaded ${captures.length} captures for user $_currentUserId',
      );
      setState(() {
        _captures = captures;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load captures. Please try again.';
      });
      debugPrint('Error fetching captures: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToCameraScreen() {
    Navigator.pushNamed(
      context,
      '/capture/camera',
    ).then((_) => _fetchCaptures());
  }

  void _navigateToCaptureDetail(String captureId) {
    Navigator.pushNamed(
      context,
      '/capture/detail',
      arguments: captureId,
    ).then((_) => _fetchCaptures());
  }

  List<CaptureModel> _getFilteredCaptures() {
    if (_searchController.text.isEmpty) {
      return _captures;
    }
    final searchLower = _searchController.text.toLowerCase();
    return _captures.where((capture) {
      return (capture.title?.toLowerCase().contains(searchLower) ?? false) ||
          (capture.description?.toLowerCase().contains(searchLower) ?? false) ||
          (capture.tags?.any(
                (tag) => tag.toLowerCase().contains(searchLower),
              ) ??
              false);
    }).toList();
  }

  Widget _buildCaptureGrid() {
    final filteredCaptures = _getFilteredCaptures();

    if (_isLoading && !_isRefreshing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchCaptures,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (filteredCaptures.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No captures found'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _navigateToCameraScreen,
              icon: const Icon(Icons.photo_camera),
              label: const Text('Add First Capture'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: filteredCaptures.length,
      itemBuilder: (context, index) {
        final capture = filteredCaptures[index];
        return GestureDetector(
          onTap: () => _navigateToCaptureDetail(capture.id),
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  capture.thumbnailUrl ?? capture.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                        size: 40,
                      ),
                    );
                  },
                ),
                // Processing status indicator
                if (!capture.isProcessed)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha(230),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.hourglass_empty,
                            size: 12,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Processing',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Privacy status indicator
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: capture.isPublic
                          ? Colors.green.withAlpha(230)
                          : Colors.grey.withAlpha(230),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      capture.isPublic ? Icons.public : Icons.lock,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Title overlay
                if (capture.title != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withAlpha((255 * 0.7).round()),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Text(
                        capture.title!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Captures'),
        actions: [
          IconButton(
            onPressed: _navigateToCameraScreen,
            icon: const Icon(Icons.photo_camera),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search captures...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchCaptures,
              child: _buildCaptureGrid(),
            ),
          ),
        ],
      ),
    );
  }
}
