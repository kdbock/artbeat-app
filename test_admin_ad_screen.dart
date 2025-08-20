import 'package:flutter/material.dart';
import 'package:artbeat_ads/artbeat_ads.dart';

void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Ad Management Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AdminAdManagementScreen(),
    );
  }
}
