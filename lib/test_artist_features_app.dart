import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Test app to verify all artist features work properly
class ArtistFeatureTestApp extends StatefulWidget {
  const ArtistFeatureTestApp({Key? key}) : super(key: key);

  @override
  State<ArtistFeatureTestApp> createState() => _ArtistFeatureTestAppState();
}

class _ArtistFeatureTestAppState extends State<ArtistFeatureTestApp> {
  final ArtistFeatureTestingService _testingService =
      ArtistFeatureTestingService();
  Map<String, TestResult> _testResults = {};
  bool _isRunningTests = false;
  String? _selectedTier;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Artist Features Test'),
        backgroundColor: ArtbeatColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Test Controls
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🎯 Test Controls',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tier Selection
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTier,
                      decoration: const InputDecoration(
                        labelText: 'Select Subscription Tier',
                        border: OutlineInputBorder(),
                      ),
                      items: SubscriptionTier.values.map((tier) {
                        return DropdownMenuItem(
                          value: tier.name,
                          child: Text(
                            '${tier.displayName} - \$${tier.monthlyPrice}/month',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedTier = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Test Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _selectedTier == null || _isRunningTests
                                ? null
                                : _runAllTests,
                            icon: _isRunningTests
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.play_arrow),
                            label: Text(
                              _isRunningTests ? 'Testing...' : 'Run All Tests',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ArtbeatColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _testResults.isEmpty
                              ? null
                              : _clearResults,
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[600],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test Results
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '📊 Test Results',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (_testResults.isNotEmpty) _buildSummaryChip(),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _testResults.isEmpty
                            ? _buildEmptyState()
                            : _buildTestResults(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryChip() {
    final passed = _testResults.values.where((r) => r.passed).length;
    final total = _testResults.length;
    final successRate = total > 0
        ? (passed / total * 100).toStringAsFixed(1)
        : '0.0';

    return Chip(
      label: Text('$passed/$total ($successRate%)'),
      backgroundColor: passed == total ? Colors.green[100] : Colors.orange[100],
      avatar: Icon(
        passed == total ? Icons.check_circle : Icons.warning,
        color: passed == total ? Colors.green : Colors.orange,
        size: 20,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.science_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No tests run yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a subscription tier and run tests to verify artist features',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTestResults() {
    return ListView.builder(
      itemCount: _testResults.length,
      itemBuilder: (context, index) {
        final entry = _testResults.entries.elementAt(index);
        final feature = entry.key;
        final result = entry.value;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              result.passed ? Icons.check_circle : Icons.error,
              color: result.passed ? Colors.green : Colors.red,
            ),
            title: Text(
              _formatFeatureName(feature),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(result.message),
            trailing: Text(
              result.passed ? 'PASS' : 'FAIL',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: result.passed ? Colors.green : Colors.red,
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatFeatureName(String feature) {
    return feature
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Future<void> _runAllTests() async {
    if (_selectedTier == null) return;

    setState(() {
      _isRunningTests = true;
      _testResults.clear();
    });

    try {
      final tier = SubscriptionTier.values.firstWhere(
        (t) => t.name == _selectedTier,
      );

      // Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError('No authenticated user. Please sign in to run tests.');
        return;
      }

      // Run all tests for the selected tier
      final results = await _testingService.testAllFeaturesForTier(tier);

      setState(() {
        _testResults = results;
      });

      // Show summary dialog
      _showTestSummary();
    } catch (e) {
      _showError('Test execution failed: $e');
    } finally {
      setState(() {
        _isRunningTests = false;
      });
    }
  }

  void _clearResults() {
    setState(() {
      _testResults.clear();
    });
  }

  void _showTestSummary() {
    final passed = _testResults.values.where((r) => r.passed).length;
    final total = _testResults.length;
    final successRate = total > 0
        ? (passed / total * 100).toStringAsFixed(1)
        : '0.0';

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          passed == total ? '🎉 All Tests Passed!' : '⚠️ Some Tests Failed',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Test Summary for ${_selectedTier?.toUpperCase()} tier:'),
            const SizedBox(height: 8),
            Text('• Passed: $passed'),
            Text('• Failed: ${total - passed}'),
            Text('• Success Rate: $successRate%'),
            const SizedBox(height: 16),
            if (total - passed > 0) ...[
              const Text(
                'Failed tests may indicate features that need attention:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ..._testResults.entries
                  .where((e) => !e.value.passed)
                  .map((e) => Text('• ${_formatFeatureName(e.key)}')),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          if (total - passed > 0)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showDetailedReport();
              },
              child: const Text('View Report'),
            ),
        ],
      ),
    );
  }

  void _showDetailedReport() {
    final report = _testingService.generateTestReport();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📋 Detailed Test Report'),
        content: SingleChildScrollView(
          child: Text(report, style: const TextStyle(fontFamily: 'monospace')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}

/// Quick test function that can be called from anywhere
Future<void> runQuickFeatureTest({String? userId}) async {
  try {
    final testingService = ArtistFeatureTestingService();

    // Test Free tier as default
    final results = await testingService.testAllFeaturesForTier(
      SubscriptionTier.free,
      userId: userId,
    );

    print('\n🧪 QUICK ARTIST FEATURES TEST');
    print('=' * 40);

    results.forEach((feature, result) {
      final status = result.passed ? '✅' : '❌';
      print('$status $feature: ${result.message}');
    });

    final passed = results.values.where((r) => r.passed).length;
    final total = results.length;
    print('=' * 40);
    print('RESULT: $passed/$total tests passed');
  } catch (e) {
    print('❌ Quick test failed: $e');
  }
}
