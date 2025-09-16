import 'package:flutter/material.dart';
import 'camera_capture_screen.dart';
import 'camera_only_screen.dart';
import '../services/capture_terms_service.dart';

/// Smart capture screen that decides whether to show terms or go directly to camera
/// based on whether the user has previously accepted capture terms
class SmartCaptureScreen extends StatefulWidget {
  const SmartCaptureScreen({Key? key}) : super(key: key);

  @override
  State<SmartCaptureScreen> createState() => _SmartCaptureScreenState();
}

class _SmartCaptureScreenState extends State<SmartCaptureScreen> {
  @override
  void initState() {
    super.initState();
    _checkTermsAcceptance();
  }

  Future<void> _checkTermsAcceptance() async {
    final hasAcceptedTerms = await CaptureTermsService.hasAcceptedTerms();

    if (mounted) {
      if (hasAcceptedTerms) {
        // User has already accepted terms, go directly to camera
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (context) => const CameraCaptureScreen(),
          ),
        );
      } else {
        // User hasn't accepted terms, show the full capture screen with terms
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (context) => const BasicCaptureScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }
}
