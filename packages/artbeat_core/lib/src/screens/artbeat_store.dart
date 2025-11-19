import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_ads/artbeat_ads.dart';

// Import the existing screens
import 'package:artbeat_core/src/screens/gifts/gifts_screen.dart';
import 'package:artbeat_ads/src/screens/my_ads_screen.dart';
import 'package:artbeat_core/src/screens/subscriptions/subscriptions_screen.dart';

class ArtbeatStoreScreen extends StatelessWidget {
  const ArtbeatStoreScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: const [
          TabBar(
            tabs: [
              Tab(text: 'Gifts', icon: Icon(Icons.card_giftcard)),
              Tab(text: 'Ads', icon: Icon(Icons.ads_click)),
              Tab(text: 'Subscriptions', icon: Icon(Icons.subscriptions)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                GiftsScreen(showAppBar: false),
                MyAdsScreen(showAppBar: false),
                SubscriptionsScreen(showAppBar: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
