import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import '../services/capture_service.dart';
import 'capture_detail_screen.dart';

/// Wrapper screen that loads a capture by ID and shows the detail screen
class CaptureDetailWrapperScreen extends StatefulWidget {
  final String captureId;

  const CaptureDetailWrapperScreen({Key? key, required this.captureId})
    : super(key: key);

  @override
  State<CaptureDetailWrapperScreen> createState() =>
      _CaptureDetailWrapperScreenState();
}

class _CaptureDetailWrapperScreenState
    extends State<CaptureDetailWrapperScreen> {
  final CaptureService _captureService = CaptureService();
  core.CaptureModel? _capture;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCapture();
  }

  Future<void> _loadCapture() async {
    try {
      final capture = await _captureService.getCaptureById(widget.captureId);
      if (mounted) {
        setState(() {
          _capture = capture;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: core.EnhancedUniversalHeader(
          title: 'Loading...',
          showLogo: false,
          showBackButton: true,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: const core.EnhancedUniversalHeader(
          title: 'Error',
          showLogo: false,
          showBackButton: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading capture',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    if (_capture == null) {
      return Scaffold(
        appBar: const core.EnhancedUniversalHeader(
          title: 'Not Found',
          showLogo: false,
          showBackButton: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Capture not found',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'The capture you\'re looking for doesn\'t exist or has been removed.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return CaptureDetailScreen(capture: _capture!);
  }
}
