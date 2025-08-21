import 'package:flutter/material.dart';

class TestImageScreen extends StatelessWidget {
  const TestImageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Images')),
      body: Column(
        children: [
          const Text('Testing via.placeholder.com URLs:'),
          const SizedBox(height: 20),
          Container(
            width: 300,
            height: 200,
            child: Image.network(
              'https://via.placeholder.com/300x200/FF6B6B/FFFFFF?text=Image+1',
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) {
                print('Error loading image: $error');
                return Container(
                  color: Colors.red,
                  child: const Center(
                    child: Text(
                      'Failed to load',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 300,
            height: 200,
            child: Image.network(
              'https://via.placeholder.com/300x200/4ECDC4/FFFFFF?text=Image+2',
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) {
                print('Error loading image: $error');
                return Container(
                  color: Colors.red,
                  child: const Center(
                    child: Text(
                      'Failed to load',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
