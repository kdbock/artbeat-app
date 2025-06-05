import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/capture_service.dart';
import '../models/capture_model.dart'; // Import the new CaptureModel

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

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _fetchCaptures();
  }

  Future<void> _fetchCaptures() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final captures = await _captureService.getCapturesForUser(_currentUserId);
      setState(() {
        _captures = captures;
      });
    } catch (e) {
      debugPrint('Error fetching captures: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToCameraScreen() {
    Navigator.pushNamed(context, '/capture/camera')
        .then((_) => _fetchCaptures());
  }

  void _navigateToCaptureDetail(String captureId) {
    Navigator.pushNamed(context, '/capture/detail', arguments: captureId)
        .then((_) => _fetchCaptures());
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Captures')),
        body: const Center(
          child: Text('Please log in to view your captures.'),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Captures'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: _navigateToCameraScreen,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _captures.isEmpty
              ? _buildEmptyState()
              : _buildCaptureList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.photo_library_outlined,
              size: 100, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            'No captures yet',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.camera_alt),
            label: const Text('Capture Something'),
            onPressed: _navigateToCameraScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _captures.length,
      itemBuilder: (context, index) {
        final capture = _captures[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            title: Text(capture.title ?? 'Capture ${index + 1}'),
            subtitle: capture.userDisplayName != null
                ? Text('By: ${capture.userDisplayName}')
                : null,
            leading:
                capture.thumbnailUrl != null && capture.thumbnailUrl!.isNotEmpty
                    ? Image.network(capture.thumbnailUrl!,
                        width: 50, height: 50, fit: BoxFit.cover)
                    : const Icon(Icons.image, size: 40),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              _navigateToCaptureDetail(capture.id);
            },
          ),
        );
      },
    );
  }
}
