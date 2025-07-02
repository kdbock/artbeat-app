import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SponsorshipScreen extends StatefulWidget {
  const SponsorshipScreen({super.key});

  @override
  State<SponsorshipScreen> createState() => _SponsorshipScreenState();
}

class _SponsorshipScreenState extends State<SponsorshipScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _sponsorships = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSponsorships();
  }

  Future<void> _loadSponsorships() async {
    setState(() => _isLoading = true);
    try {
      final querySnapshot = await _firestore
          .collection('sponsorships')
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _sponsorships = querySnapshot.docs.map((doc) => doc.data()).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading sponsorships: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return CustomScrollView(
      slivers: [
        // Featured sponsorships
        SliverToBoxAdapter(
          child: Container(
            height: 200,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8C52FF), Color(0xFF00BF63)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'Featured Sponsorships',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        // Sponsorship list
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final sponsorship = _sponsorships[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey[200],
                          child: Text(
                            ((sponsorship['sponsorName'] as String?)?[0]) ??
                                'S',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (sponsorship['sponsorName'] as String?) ??
                                    'Unknown Sponsor',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                (sponsorship['title'] as String?) ??
                                    'Untitled Sponsorship',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (sponsorship['description'] != null) ...[
                      const SizedBox(height: 12),
                      Text(sponsorship['description'] as String),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(
                            '\$${sponsorship['budget']?.toString() ?? 'N/A'}',
                          ),
                          backgroundColor: Colors.green[100],
                        ),
                        if (sponsorship['deadline'] != null)
                          Chip(
                            label: Text(
                              (sponsorship['deadline'] as Timestamp)
                                  .toDate()
                                  .toString()
                                  .split(' ')[0],
                            ),
                            backgroundColor: Colors.orange[100],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }, childCount: _sponsorships.length),
        ),
      ],
    );
  }
}
