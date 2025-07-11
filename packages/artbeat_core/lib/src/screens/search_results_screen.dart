import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

class SearchResultsScreen extends StatelessWidget {
  final String query;
  const SearchResultsScreen({Key? key, required this.query}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const EnhancedUniversalHeader(
        title: 'Search Results',
        showLogo: false,
        showBackButton: true,
      ),
      body: Center(
        child: Text(
          'Search results for "$query"',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
