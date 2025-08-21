import 'package:flutter/material.dart';
import '../models/ad_location.dart';
import '../models/ad_display_type.dart';
import '../services/ad_cleanup_service.dart';
import '../services/ad_diagnostic_service.dart';
import 'dashboard_ad_placement_widget.dart';
import 'ad_display_widget.dart';

/// Simple test widget to verify ad functionality
class AdTestWidget extends StatefulWidget {
  const AdTestWidget({super.key});

  @override
  State<AdTestWidget> createState() => _AdTestWidgetState();
}

class _AdTestWidgetState extends State<AdTestWidget> {
  bool _isRunningTest = false;
  String _testStatus = 'Ready to test';

  Future<void> _runFullTest() async {
    setState(() {
      _isRunningTest = true;
      _testStatus = 'Running full diagnostic and setup...';
    });

    try {
      // Step 1: Run diagnostic
      await AdDiagnosticService.runFullDiagnostic();

      setState(() {
        _testStatus = 'Diagnostic complete. Running quick fixes...';
      });

      // Step 2: Run quick fixes
      await AdDiagnosticService.quickFix();

      setState(() {
        _testStatus = 'Quick fixes complete. Creating fresh test ads...';
      });

      // Step 3: Create fresh test ads
      await AdCleanupService.resetAdsForTesting();

      setState(() {
        _testStatus = 'Test complete! Ads should now be visible.';
      });

      // Wait a moment then refresh the page
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _testStatus = 'Ready to test';
        });
      }
    } catch (e) {
      setState(() {
        _testStatus = 'Test failed: $e';
      });
    } finally {
      setState(() {
        _isRunningTest = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ad System Test'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Test controls
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Ad System Test Controls',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _testStatus,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isRunningTest ? null : _runFullTest,
                      child: _isRunningTest
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Running Test...'),
                              ],
                            )
                          : const Text('Run Full Test & Setup'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Test ad displays for different locations
            Text(
              'Ad Displays by Location',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            // Dashboard ads
            _buildAdLocationTest(
              'Dashboard Ads',
              AdLocation.dashboard,
              Colors.blue,
            ),

            const SizedBox(height: 16),

            // Art Walk Dashboard ads
            _buildAdLocationTest(
              'Art Walk Dashboard Ads',
              AdLocation.artWalkDashboard,
              Colors.green,
            ),

            const SizedBox(height: 16),

            // Events Dashboard ads
            _buildAdLocationTest(
              'Events Dashboard Ads',
              AdLocation.eventsDashboard,
              Colors.orange,
            ),

            const SizedBox(height: 16),

            // Community Dashboard ads
            _buildAdLocationTest(
              'Community Dashboard Ads',
              AdLocation.communityDashboard,
              Colors.purple,
            ),

            const SizedBox(height: 32),

            // Instructions
            Card(
              color: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instructions:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Tap "Run Full Test & Setup" to diagnose and fix ad issues',
                    ),
                    const Text('2. Wait for the test to complete'),
                    const Text(
                      '3. Check if ads appear in each location section below',
                    ),
                    const Text(
                      '4. If ads still don\'t appear, check the debug console for error messages',
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

  Widget _buildAdLocationTest(String title, AdLocation location, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: DashboardAdPlacementWidget(
                  location: location,
                  analyticsLocation: 'test_${location.name}',
                  displayType: AdDisplayType.rectangle,
                  height: 180,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
