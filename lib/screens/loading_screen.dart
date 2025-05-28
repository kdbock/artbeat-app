import 'dart:async'; // Import for Timer
import 'package:flutter/material.dart';

class LoadingScreen extends StatefulWidget {
  // Changed to StatefulWidget
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      // Navigate after 2 seconds
      if (mounted) {
        // Check if the widget is still in the tree
        Navigator.pushReplacementNamed(context, '/splash');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
