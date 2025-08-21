import 'package:flutter/material.dart';
import 'package:artbeat_ads/artbeat_ads.dart';

/// Test screen to show our simple rotating ads
class AdTestScreen extends StatelessWidget {
  const AdTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rotating Ad Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Simple Rotating Ad',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 32),
              AdDisplayWidget(),
              SizedBox(height: 32),
              Text(
                'This ad rotates through 4 different colored placeholders every 3 seconds',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
