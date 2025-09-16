import 'package:artbeat_core/artbeat_core.dart';
import 'package:flutter/material.dart';

/// Test screen to demonstrate SecureNetworkImage functionality
class TestSecureImageScreen extends StatelessWidget {
  const TestSecureImageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Example Firebase Storage URLs that might cause 403 errors
    const testUrls = [
      'https://firebasestorage.googleapis.com/v0/b/wordnerd-artbeat.firebasestorage.app/o/artwork_images%2FEdH8MvWk4Ja6eoSZM59QtOaxEK43%2Fnew%2F1750961590495_EdH8MvWk4Ja6eoSZM59QtOaxEK43?alt=media&token=d9e1ed0b-e106-44e3-a9d4-5da43d0ff045',
      'https://firebasestorage.googleapis.com/v0/b/wordnerd-artbeat.firebasestorage.app/o/test-image.jpg?alt=media&token=invalid-token',
      'https://picsum.photos/300/200', // This should work fine
    ];

    return Scaffold(
      appBar: const EnhancedUniversalHeader(
        title: 'Secure Image Test',
        showBackButton: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Testing SecureNetworkImage with Firebase Storage URLs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'The images below should handle 403 errors gracefully with retry functionality:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: testUrls.length,
                itemBuilder: (context, index) => Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Test Image ${index + 1}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'URL: ${testUrls[index].length > 60 ? '${testUrls[index].substring(0, 60)}...' : testUrls[index]}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SecureNetworkImage(
                                imageUrl: testUrls[index],
                                errorWidget: Container(
                                  color: Colors.grey[200],
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        size: 48,
                                        color: Colors.red,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Failed to load image',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Check debug console for details',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                placeholder: Container(
                                  color: Colors.grey[100],
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(),
                                        SizedBox(height: 8),
                                        Text(
                                          'Loading...',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Debug Information:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Check the debug console for SecureNetworkImage logs\n'
                    '• 403 errors should trigger automatic token refresh\n'
                    '• Failed images should show retry buttons\n'
                    '• Tap retry buttons to test token refresh functionality',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
