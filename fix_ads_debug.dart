import 'package:flutter/material.dart';
import 'packages/artbeat_ads/lib/src/services/ad_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Fix Admin Ads')),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              print('🔧 Starting ad fix...');
              final adService = AdService();
              await adService.fixAdImageUrls();
              print('✅ Ad fix completed!');
            },
            child: Text('Fix Admin Ads'),
          ),
        ),
      ),
    );
  }
}
