import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PortfoliosScreen extends StatefulWidget {
  const PortfoliosScreen({super.key});

  @override
  State<PortfoliosScreen> createState() => _PortfoliosScreenState();
}

class _PortfoliosScreenState extends State<PortfoliosScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _portfolios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPortfolios();
  }

  Future<void> _loadPortfolios() async {
    setState(() => _isLoading = true);
    try {
      final querySnapshot = await _firestore
          .collection('artistProfiles')
          .where('isPortfolioPublic', isEqualTo: true)
          .orderBy('username')
          .limit(20)
          .get();

      setState(() {
        _portfolios = querySnapshot.docs
            .map((doc) => {
                  ...doc.data(),
                  'id': doc.id,
                })
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading portfolios: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return CustomScrollView(
      slivers: [
        // Header with search and filter options
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBar(
              hintText: 'Search artists...',
              leading: const Icon(Icons.search),
              onChanged: (value) {
                // TODO: Implement search
              },
            ),
          ),
        ),
        // Portfolio grid
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: _portfolios.isEmpty
              ? const SliverToBoxAdapter(
                  child: Center(
                    child: Text('No portfolios available'),
                  ),
                )
              : SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    mainAxisSpacing: 16.0,
                    crossAxisSpacing: 16.0,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final portfolio = _portfolios[index];
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Portfolio cover image
                            AspectRatio(
                              aspectRatio: 1.0,
                              child: portfolio['coverImageUrl'] != null
                                  ? Image.network(
                                      portfolio['coverImageUrl'],
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.broken_image),
                                      ),
                                    )
                                  : Container(
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.image),
                                    ),
                            ),
                            // Artist info
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    portfolio['username'] ?? 'Artist',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${portfolio['artworkCount'] ?? 0} works',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: _portfolios.length,
                  ),
                ),
        ),
      ],
    );
  }
}
