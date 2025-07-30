import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/artistic_messaging_screen.dart';
import '../providers/presence_provider.dart';
import '../services/presence_service.dart';

class MessagingNavigation extends StatefulWidget {
  final int initialTabIndex;

  const MessagingNavigation({super.key, this.initialTabIndex = 0});

  @override
  State<MessagingNavigation> createState() => _MessagingNavigationState();
}

class _MessagingNavigationState extends State<MessagingNavigation> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Provide PresenceProvider for ArtisticMessagingScreen
    return ChangeNotifierProvider<PresenceProvider>(
      create: (_) => PresenceProvider(PresenceService()),
      child: const ArtisticMessagingScreen(),
    );
  }
}
