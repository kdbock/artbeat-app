import 'package:artbeat_core/artbeat_core.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// About ARTbeat screen displaying app information, version, and credits
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  PackageInfo? _packageInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _packageInfo = packageInfo;
        _isLoading = false;
      });
    } on Exception catch (e) {
      AppLogger.error('Error loading package info: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),

            // App Logo and Name
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ArtbeatColors.primaryPurple,
                    ArtbeatColors.primaryGreen,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: ArtbeatColors.primaryPurple.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.palette, size: 60, color: Colors.white),
            ),

            const SizedBox(height: 24),

            const Text(
              'ARTbeat',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: ArtbeatColors.primaryPurple,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Version ${_packageInfo?.version ?? 'Unknown'} (${_packageInfo?.buildNumber ?? 'Unknown'})',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),

            const SizedBox(height: 32),

            // App Description
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About ARTbeat',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: ArtbeatColors.primaryPurple,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ARTbeat is a comprehensive platform designed for artists, galleries, and art enthusiasts. '
                    'Discover, create, and share art while connecting with a vibrant community of creators.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Features Section
            _buildFeatureSection(),

            const SizedBox(height: 24),

            // Technical Information
            _buildTechnicalInfo(),

            const SizedBox(height: 24),

            // Credits and Legal
            _buildCreditsSection(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureSection() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 0.1),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Key Features',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ArtbeatColors.primaryPurple,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureItem(
          Icons.camera_alt,
          'Art Capture',
          'Capture and share your artwork with the community',
        ),
        _buildFeatureItem(
          Icons.palette,
          'Artist Profiles',
          'Create and manage your professional artist profile',
        ),
        _buildFeatureItem(
          Icons.map,
          'Art Walks',
          'Discover local art through guided walking tours',
        ),
        _buildFeatureItem(
          Icons.people,
          'Community',
          'Connect with artists and art lovers worldwide',
        ),
        _buildFeatureItem(
          Icons.event,
          'Events',
          'Find and participate in art events and exhibitions',
        ),
        _buildFeatureItem(
          Icons.star,
          'Rewards',
          'Earn XP and unlock achievements for your activities',
        ),
      ],
    ),
  );

  Widget _buildFeatureItem(IconData icon, String title, String description) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: ArtbeatColors.primaryPurple, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildTechnicalInfo() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Technical Information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ArtbeatColors.primaryPurple,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoRow('App Name', _packageInfo?.appName ?? 'ARTbeat'),
        _buildInfoRow('Package Name', _packageInfo?.packageName ?? 'Unknown'),
        _buildInfoRow('Version', _packageInfo?.version ?? 'Unknown'),
        _buildInfoRow('Build Number', _packageInfo?.buildNumber ?? 'Unknown'),
        _buildInfoRow('Built with', 'Flutter & Firebase'),
      ],
    ),
  );

  Widget _buildInfoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
        ),
      ],
    ),
  );

  Widget _buildCreditsSection() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 0.1),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Credits & Legal',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ArtbeatColors.primaryPurple,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '© 2024 ARTbeat. All rights reserved.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        Text(
          'ARTbeat is built with love for the art community. We believe in empowering artists '
          'and connecting art enthusiasts through technology.',
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            TextButton(
              onPressed: () {
                // Navigate to privacy policy
                Navigator.pushNamed(context, '/settings/privacy');
              },
              child: const Text('Privacy Policy'),
            ),
            const Text(' • '),
            TextButton(
              onPressed: () {
                // Navigate to terms of service
                // TODO(dev): Create terms of service screen
              },
              child: const Text('Terms of Service'),
            ),
          ],
        ),
      ],
    ),
  );
}
