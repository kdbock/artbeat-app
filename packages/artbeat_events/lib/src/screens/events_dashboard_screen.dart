import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/artbeat_event.dart';

/// Central events dashboard screen - entry point for events tab
class EventsDashboardScreen extends StatefulWidget {
  const EventsDashboardScreen({super.key});

  @override
  State<EventsDashboardScreen> createState() => _EventsDashboardScreenState();
}

class _EventsDashboardScreenState extends State<EventsDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<ArtbeatEvent> _events = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final now = DateTime.now();
      final query = await _firestore
          .collection('events')
          .where('isPublic', isEqualTo: true)
          .where('dateTime', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('dateTime')
          .limit(10)
          .get();
      final events = query.docs.map(ArtbeatEvent.fromFirestore).toList();
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load events: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 4,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight + 4),
          child: ArtbeatGradientBackground(
            addShadow: true,
            child: EnhancedUniversalHeader(
              title: 'Events',
              showLogo: false,
              showDeveloperTools: true,
              onSearchPressed: () {},
              onProfilePressed: () {},
              onMenuPressed: () => Scaffold.of(context).openDrawer(),
              backgroundColor: Colors.transparent,
              foregroundColor: ArtbeatColors.textPrimary,
              elevation: 0,
            ),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ArtbeatColors.backgroundPrimary,
                ArtbeatColors.backgroundSecondary,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : _error != null
                  ? Text(_error!)
                  : ListView(
                      children: _events
                          .map(
                            (e) => ListTile(
                              title: Text(e.title),
                              subtitle: Text(e.location),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
