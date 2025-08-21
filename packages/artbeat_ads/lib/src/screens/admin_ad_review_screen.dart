import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ad_model.dart';
import '../models/ad_status.dart' as model;
import '../models/ad_display_type.dart';
import '../services/ad_service.dart';
import '../widgets/ad_status_widget.dart';
import '../widgets/ad_display_widget.dart';
import '../widgets/ads_header.dart';
import '../widgets/ads_drawer.dart';

class AdminAdReviewScreen extends StatefulWidget {
  const AdminAdReviewScreen({super.key});

  @override
  State<AdminAdReviewScreen> createState() => _AdminAdReviewScreenState();
}

class _AdminAdReviewScreenState extends State<AdminAdReviewScreen> {
  final AdService _service = AdService();
  late Stream<List<AdModel>> _adsStream;
  String? _adminId;

  @override
  void initState() {
    super.initState();
    _adminId = FirebaseAuth.instance.currentUser?.uid;
    if (_adminId != null) {
      _adsStream = _service.getAdsByOwner(_adminId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AdsHeader(title: 'Admin Ad Review', showBackButton: true),
      drawer: const AdsDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE3F2FD),
              Color(0xFFF8FBFF),
              Color(0xFFE1F5FE),
              Color(0xFFBBDEFB),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: _adminId == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 48, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'Authentication Required',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      Text('Please log in to view your ads.'),
                    ],
                  ),
                )
              : StreamBuilder<List<AdModel>>(
                  stream: _adsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final ads = snapshot.data ?? [];
                    if (ads.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.campaign, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No ads yet', style: TextStyle(fontSize: 18)),
                            SizedBox(height: 8),
                            Text('Create an ad to promote your platform!'),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: ads.length,
                      itemBuilder: (context, i) {
                        final ad = ads[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AdDisplayWidget(
                                  imageUrl: ad.imageUrl,
                                  artworkUrls: ad.artworkUrls,
                                  title: ad.title,
                                  description: ad.description,
                                  displayType: ad.type.name == 'square'
                                      ? AdDisplayType.square
                                      : AdDisplayType.rectangle,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    AdStatusWidget(
                                      status: model
                                          .AdStatus
                                          .values[ad.status.index],
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      ad.status.name.toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                if (ad.status == model.AdStatus.rejected &&
                                    ad.approvalId != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Reason: ${ad.approvalId}',
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Text('Duration: ${ad.duration.days} days'),
                                Text('Location: ${ad.location.name}'),
                                Text(
                                  'Price per day: \$${ad.pricePerDay.toStringAsFixed(2)}',
                                ),
                                Text('Start: ${ad.startDate.toLocal()}'),
                                Text('End: ${ad.endDate.toLocal()}'),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }
}
