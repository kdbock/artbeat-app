import 'package:flutter/material.dart';

class ExampleSplashScreen extends StatelessWidget {
  const ExampleSplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Replace with your app logo or branding
            Icon(Icons.brush,
                size: 100, color: Theme.of(context).colorScheme.onPrimary),
            const SizedBox(height: 20),
            Text(
              'ARTbeat Core Splash Screen',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
