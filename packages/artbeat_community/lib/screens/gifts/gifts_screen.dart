import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../../widgets/gift_card_widget.dart';
import 'gift_rules_screen.dart';

class GiftsScreen extends StatefulWidget {
  const GiftsScreen({super.key});

  @override
  State<GiftsScreen> createState() => _GiftsScreenState();
}

class _GiftsScreenState extends State<GiftsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  List<GiftModel> _gifts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGifts();
  }

  Future<void> _loadGifts() async {
    setState(() => _isLoading = true);
    try {
      final querySnapshot = await _firestore
          .collection('gifts')
          .limit(20)
          .get();
      final gifts = querySnapshot.docs
          .map((doc) => GiftModel.fromFirestore(doc))
          .toList();
      setState(() {
        _gifts = gifts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading gifts: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MainLayout(
        currentIndex: -1, // Not a main navigation screen
        scaffoldKey: _scaffoldKey,
        appBar: const EnhancedUniversalHeader(
          title: 'Gifts',
          showBackButton: true,
          showSearch: false,
          showDeveloperTools: true,
        ),
        drawer: const ArtbeatDrawer(),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return MainLayout(
      currentIndex: -1, // Not a main navigation screen
      scaffoldKey: _scaffoldKey,
      appBar: const EnhancedUniversalHeader(
        title: 'Gifts',
        showBackButton: true,
        showSearch: false,
        showDeveloperTools: true,
      ),
      drawer: const ArtbeatDrawer(),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => const GiftRulesScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Gift Guidelines'),
                ),
                const SizedBox(height: 16),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: _gifts.isEmpty
                ? SliverToBoxAdapter(
                    child: Center(
                      child: Text(
                        'No gifts yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  )
                : SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16.0,
                          crossAxisSpacing: 16.0,
                          childAspectRatio: 1.0,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => GiftCardWidget(gift: _gifts[index]),
                      childCount: _gifts.length,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
