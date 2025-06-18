import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../widgets/dashboard_header.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const ArtbeatAppHeader(),
      body: RefreshIndicator(
        onRefresh: () => _refreshDashboard(context),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withAlpha((0.1 * 255).round()),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16.0),
                  ),
                ),
                child: const DashboardHeader(),
              ),
              // ...existing code...
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshDashboard(BuildContext context) async {
    final userService = Provider.of<UserService>(context, listen: false);
    await userService.refreshUserData();
  }
}
