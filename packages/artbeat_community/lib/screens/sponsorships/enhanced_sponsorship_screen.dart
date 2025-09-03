import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import '../../theme/community_colors.dart';
import 'sponsor_artist_screen.dart';
import 'my_sponsorships_screen.dart';

class EnhancedSponsorshipScreen extends StatefulWidget {
  const EnhancedSponsorshipScreen({super.key});

  @override
  State<EnhancedSponsorshipScreen> createState() =>
      _EnhancedSponsorshipScreenState();
}

class _EnhancedSponsorshipScreenState extends State<EnhancedSponsorshipScreen>
    with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return core.MainLayout(
      currentIndex: 3, // Community tab
      scaffoldKey: _scaffoldKey,
      appBar: const core.EnhancedUniversalHeader(
        title: 'Artist Sponsorships',
        showBackButton: true,
        showSearch: false,
        showDeveloperTools: true,
        backgroundGradient: CommunityColors.communityGradient,
        titleGradient: LinearGradient(
          colors: [Colors.white, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        foregroundColor: Colors.white,
      ),
      drawer: const core.ArtbeatDrawer(),
      child: Column(
        children: [
          _buildSponsorshipInfo(),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.explore), text: 'Discover Artists'),
              Tab(icon: Icon(Icons.handshake), text: 'My Sponsorships'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [SponsorArtistScreen(), MySponsorshipsScreen()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSponsorshipInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[100]!, Colors.blue[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.handshake, color: Colors.purple[700], size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Support Your Favorite Artists',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Monthly sponsorships help artists focus on creating amazing art. Choose from different tiers and get exclusive benefits!',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),
          _buildTierPreview(),
        ],
      ),
    );
  }

  Widget _buildTierPreview() {
    final tiers = [
      {'name': 'Bronze', 'price': '\$5', 'color': Colors.orange[300]},
      {'name': 'Silver', 'price': '\$15', 'color': Colors.grey[400]},
      {'name': 'Gold', 'price': '\$50', 'color': Colors.amber[400]},
      {'name': 'Platinum', 'price': '\$100', 'color': Colors.purple[300]},
    ];

    return Row(
      children: tiers
          .map(
            (tier) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: tier['color'] as Color?,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      tier['name'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      tier['price'] as String,
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
