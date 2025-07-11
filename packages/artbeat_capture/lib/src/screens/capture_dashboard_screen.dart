import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'capture_screen.dart';

// Capture Dashboard specific colors
class CaptureColors {
  static const Color primaryEmerald = Color(0xFF009688);
  static const Color primaryEmeraldLight = Color(0xFF26A69A);
  static const Color primaryEmeraldDark = Color(0xFF00695C);
  static const Color accentAmber = Color(0xFFFFA000);
  static const Color accentAmberLight = Color(0xFFFFC107);
  static const Color backgroundGradientStart = Color(0xFFE0F2F1);
  static const Color backgroundGradientEnd = Color(0xFFF1F8E9);
  static const Color cardBackground = Color(0xFFFFFFF8);
  static const Color textPrimary = Color(0xFF004D40);
  static const Color textSecondary = Color(0xFF00695C);
}

class CaptureDashboardScreen extends StatefulWidget {
  const CaptureDashboardScreen({Key? key}) : super(key: key);

  @override
  State<CaptureDashboardScreen> createState() => _CaptureDashboardScreenState();
}

class _CaptureDashboardScreenState extends State<CaptureDashboardScreen> {
  bool _hasAcceptedDisclaimer = false;

  void _showDisclaimerDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade700,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text('Safety & Legal Notice'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Before you capture art, please read and agree to the following:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 16),

                // Safety Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.security,
                            color: Colors.red.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Safety Guidelines',
                            style: TextStyle(
                              color: Colors.red.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Always be aware of your surroundings\n'
                        '• Do not trespass on private property\n'
                        '• Stay on public sidewalks and paths\n'
                        '• Be respectful of other people and property\n'
                        '• Use caution when crossing streets or navigating traffic',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Legal Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.gavel,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Legal Guidelines',
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Only capture art in public spaces\n'
                        '• No nudity or inappropriate content\n'
                        '• No derogatory or offensive images\n'
                        '• Respect artist copyrights and permissions\n'
                        '• All captures are subject to moderation',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Art Walk Integration
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ArtbeatColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ArtbeatColors.primaryGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.map,
                            color: ArtbeatColors.primaryGreen,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Art Walk Process',
                            style: TextStyle(
                              color: ArtbeatColors.primaryGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'When you capture art, you\'re contributing to the ARTbeat community! '
                        'Your captures help build Art Walks - curated routes that guide other users to discover '
                        'public art in their area. Each capture is geotagged and can become part of a walking tour '
                        'for other art enthusiasts.',
                        style: TextStyle(
                          color: ArtbeatColors.primaryGreen,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasAcceptedDisclaimer = true;
                });
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ArtbeatColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('I Agree & Understand'),
            ),
          ],
        );
      },
    );
  }

  void _openCaptureScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const CaptureScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 2, // Capture is now index 2
      child: Scaffold(
        appBar: const EnhancedUniversalHeader(
          title: 'Capture Art',
          showLogo: false,
        ),
        drawer: const ArtbeatDrawer(),
        body: Container(
          constraints: const BoxConstraints.expand(),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ArtbeatColors.primaryPurple.withValues(alpha: 0.05),
                Colors.white,
                ArtbeatColors.primaryGreen.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Header Section
                  Column(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              ArtbeatColors.primaryPurple.withValues(
                                alpha: 0.1,
                              ),
                              ArtbeatColors.primaryGreen.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          size: 60,
                          color: ArtbeatColors.primaryPurple,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Capture Dashboard',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: ArtbeatColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Share public art with the ARTbeat community',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: ArtbeatColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Action Cards
                  if (!_hasAcceptedDisclaimer) ...[
                    // Disclaimer Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 48,
                            color: Colors.orange.shade600,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Safety & Legal Agreement',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: ArtbeatColors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Before you can capture art, please read and agree to our safety and legal guidelines. This helps ensure everyone\'s safety and legal compliance.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: ArtbeatColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _showDisclaimerDialog,
                              icon: const Icon(Icons.assignment_turned_in),
                              label: const Text('Read & Agree to Guidelines'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Capture Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  ArtbeatColors.primaryPurple,
                                  ArtbeatColors.primaryGreen,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Ready to Capture!',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: ArtbeatColors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'You\'ve agreed to our guidelines. Now you can capture public art and contribute to the ARTbeat community.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: ArtbeatColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: _openCaptureScreen,
                              icon: const Icon(Icons.camera_alt, size: 24),
                              label: const Text(
                                'Start Capturing',
                                style: TextStyle(fontSize: 18),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ArtbeatColors.primaryGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Reset Agreement Button
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _hasAcceptedDisclaimer = false;
                        });
                      },
                      child: const Text(
                        'Review Guidelines Again',
                        style: TextStyle(
                          color: ArtbeatColors.primaryPurple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Info Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ArtbeatColors.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ArtbeatColors.primaryGreen.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: ArtbeatColors.primaryGreen,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'How It Works',
                              style: TextStyle(
                                color: ArtbeatColors.primaryGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          '1. Review and agree to safety & legal guidelines\n'
                          '2. Use your camera to capture public art\n'
                          '3. Add details about the artwork and artist\n'
                          '4. Share with the ARTbeat community\n'
                          '5. Your captures help build Art Walks for others!',
                          style: TextStyle(
                            color: ArtbeatColors.primaryGreen,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
