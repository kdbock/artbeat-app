import 'package:flutter/material.dart';
import '../theme/artbeat_colors.dart';
import '../theme/artbeat_typography.dart';

class FeedbackSystemInfoScreen extends StatelessWidget {
  const FeedbackSystemInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback System'),
        backgroundColor: ArtbeatColors.primaryPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildFeatureCard(
              'User Feedback Form',
              'Industry-standard feedback form with categorization',
              Icons.feedback,
              [
                'Bug reports with screenshots',
                'Feature requests',
                'Usability feedback',
                'Performance issues',
                'Package-specific categorization',
                'Priority levels (Low, Medium, High, Critical)',
              ],
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              'Developer Admin Panel',
              'Comprehensive admin interface for managing feedback',
              Icons.admin_panel_settings,
              [
                'View all feedback with filtering',
                'Statistics and analytics',
                'Respond to user feedback',
                'Update feedback status',
                'Bulk management actions',
                'Export capabilities',
              ],
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              'Easy Access',
              'Multiple ways to access the feedback system',
              Icons.accessibility,
              [
                'Main drawer: Settings > Send Feedback',
                'Developer menu: Feedback System section',
                'Direct navigation from any screen',
                'Quick action buttons in problem areas',
              ],
            ),
            const SizedBox(height: 24),
            _buildTechnicalDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.feedback,
                  size: 32,
                  color: ArtbeatColors.primaryPurple,
                ),
                const SizedBox(width: 12),
                Text(
                  'ARTbeat Feedback System',
                  style: ArtbeatTypography.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ArtbeatColors.primaryPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'A comprehensive feedback collection and management system designed to improve ARTbeat through user insights and bug reports.',
              style: ArtbeatTypography.textTheme.bodyLarge?.copyWith(
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    String title,
    String description,
    IconData icon,
    List<String> features,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: ArtbeatColors.primaryPurple),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: ArtbeatTypography.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: ArtbeatTypography.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: ArtbeatColors.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: ArtbeatTypography.textTheme.bodySmall,
                      ),
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

  Widget _buildTechnicalDetails() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.code, color: ArtbeatColors.primaryPurple),
                const SizedBox(width: 12),
                Text(
                  'Technical Implementation',
                  style: ArtbeatTypography.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Backend', 'Firebase Firestore & Storage'),
            _buildDetailRow('Authentication', 'Firebase Auth integration'),
            _buildDetailRow('File Upload', 'Image picker with compression'),
            _buildDetailRow(
              'Device Info',
              'Automatic device & app version capture',
            ),
            _buildDetailRow(
              'Package Tracking',
              'Module-specific categorization',
            ),
            _buildDetailRow(
              'Admin Interface',
              'Real-time updates with filters',
            ),
            _buildDetailRow('Data Structure', 'Scalable and searchable'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
