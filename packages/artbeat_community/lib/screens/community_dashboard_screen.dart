import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'feed/unified_community_feed.dart';
import 'feed/trending_content_screen.dart';
import 'portfolios/portfolios_screen.dart';
import 'studios/studios_screen.dart';

class CommunityDashboardScreen extends StatefulWidget {
  const CommunityDashboardScreen({super.key});

  @override
  State<CommunityDashboardScreen> createState() =>
      _CommunityDashboardScreenState();
}

class _CommunityDashboardScreenState extends State<CommunityDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return core.MainLayout(
      currentIndex: 2, // Community index
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: const core.UniversalHeader(
          title: 'Community Critique',
          showLogo: false,
          showDeveloperTools: true,
          elevation: 0,
        ),
        body: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Feed', icon: Icon(Icons.feed)),
                Tab(text: 'Trending', icon: Icon(Icons.trending_up)),
                Tab(text: 'Portfolios', icon: Icon(Icons.folder_special)),
                Tab(text: 'Studios', icon: Icon(Icons.business)),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  UnifiedCommunityFeed(),
                  TrendingContentScreen(),
                  PortfoliosScreen(),
                  StudiosScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
