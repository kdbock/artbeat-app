import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_capture/artbeat_capture.dart';

/// Screen that displays the current user's art captures
class MyCapturesScreen extends StatefulWidget {
  const MyCapturesScreen({super.key});

  @override
  State<MyCapturesScreen> createState() => _MyCapturesScreenState();
}

class _MyCapturesScreenState extends State<MyCapturesScreen> {
  final CaptureService _captureService = CaptureService();
  List<CaptureModel> _myCaptures = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMyCaptures();
  }

  Future<void> _loadMyCaptures() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final captures = await _captureService.getCapturesForUser(user.uid);
        if (mounted) {
          setState(() {
            _myCaptures = captures;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'User not authenticated';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load captures: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return core.MainLayout(
      currentIndex: 2, // Capture tab - same as other capture screens
      drawer: const CaptureDrawer(),
      appBar: core.EnhancedUniversalHeader(
        title: 'My Captures',
        showLogo: false,
        showBackButton: false,
        showSearch: true,
        onSearchPressed: (query) {
          // TODO: Implement search functionality for user's captures
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Search coming soon!')));
        },
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMyCaptures,
            tooltip: 'Refresh captures',
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () {
              Navigator.pushNamed(context, '/capture/camera');
            },
            tooltip: 'Take new capture',
          ),
        ],
        backgroundGradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
          colors: [core.ArtbeatColors.primaryPurple, Colors.pink],
        ),
        foregroundColor: Colors.white,
      ),
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  core.ArtbeatColors.primaryPurple,
                ),
              ),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadMyCaptures,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _myCaptures.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No captures yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Start capturing art to see your collection here',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/capture/camera');
                    },
                    icon: const Icon(Icons.camera),
                    label: const Text('Take Photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: core.ArtbeatColors.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadMyCaptures,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _myCaptures.length,
                itemBuilder: (context, index) {
                  final capture = _myCaptures[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      leading: SizedBox(
                        width: 60,
                        height: 60,
                        child: core.SecureNetworkImage(
                          imageUrl: capture.imageUrl,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(8),
                          errorWidget: Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        capture.title ?? 'Untitled',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (capture.locationName != null)
                            Text(
                              capture.locationName!,
                              style: const TextStyle(fontSize: 12),
                            ),
                          Text(
                            'Status: ${capture.status.value}',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  capture.status == core.CaptureStatus.approved
                                  ? Colors.green
                                  : capture.status == core.CaptureStatus.pending
                                  ? Colors.orange
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      trailing: Icon(
                        capture.status == core.CaptureStatus.approved
                            ? Icons.check_circle
                            : capture.status == core.CaptureStatus.pending
                            ? Icons.pending
                            : Icons.error,
                        color: capture.status == core.CaptureStatus.approved
                            ? Colors.green
                            : capture.status == core.CaptureStatus.pending
                            ? Colors.orange
                            : Colors.red,
                      ),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/capture/detail',
                          arguments: {'captureId': capture.id},
                        );
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}
