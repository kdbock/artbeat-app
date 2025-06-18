import 'package:flutter/material.dart';

class GiftRulesScreen extends StatelessWidget {
  const GiftRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gift Guidelines'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gift Guidelines & Regulations',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Gift Tiers',
              [
                'Mini Palette (\$1) - Small token of appreciation',
                'Brush Pack (\$5) - Show greater support',
                'Gallery Frame (\$20) - Significant recognition',
                'Golden Canvas (\$50) - Premium support',
              ],
            ),
            _buildSection(
              'Rules',
              [
                'All gifts are non-refundable',
                'Gifts can only be sent to active artists',
                'Maximum of 10 gifts per day per user',
                'Minimum account age of 7 days to send gifts',
                'Recipients must have completed profile verification',
              ],
            ),
            _buildSection(
              'Revenue Sharing',
              [
                '70% of gift value goes to the artist',
                '25% supports the ARTbeat platform',
                '5% goes to the community fund',
              ],
            ),
            _buildSection(
              'Community Guidelines',
              [
                'No soliciting for gifts',
                'No exchanging gifts for services outside the platform',
                'Respect community guidelines when sending gift messages',
                'Report any suspicious gift activity',
              ],
            ),
            _buildSection(
              'Processing & Security',
              [
                'All transactions are processed securely through Stripe',
                'Gift history is permanently recorded',
                'Suspicious activity is automatically flagged',
                'Multi-factor authentication required for large gifts',
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...points.map((point) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(point, style: const TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 16),
      ],
    );
  }
}
