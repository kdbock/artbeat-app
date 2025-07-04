import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UniversalHeader(
        title: 'Blocked Users',
        showLogo: false,
      ),
      body: const Center(
        child: Text('Blocked Users Screen'),
      ),
    );
  }
}
