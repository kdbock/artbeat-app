import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;

class MySponsorshipsScreen extends StatefulWidget {
  const MySponsorshipsScreen({super.key});

  @override
  State<MySponsorshipsScreen> createState() => _MySponsorshipsScreenState();
}

class _MySponsorshipsScreenState extends State<MySponsorshipsScreen> {
  final core.SponsorshipService _sponsorshipService = core.SponsorshipService();

  List<core.SponsorshipModel> _sponsorships = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSponsorships();
  }

  Future<void> _loadSponsorships() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sponsorships = await _sponsorshipService.getUserSponsorships();
      setState(() {
        _sponsorships = sponsorships;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorView();
    }

    if (_sponsorships.isEmpty) {
      return _buildEmptyView();
    }

    return RefreshIndicator(
      onRefresh: _loadSponsorships,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sponsorships.length,
        itemBuilder: (context, index) {
          final sponsorship = _sponsorships[index];
          return _buildSponsorshipCard(sponsorship);
        },
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Failed to load sponsorships',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSponsorships,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.handshake_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'No Active Sponsorships',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'You haven\'t sponsored any artists yet. Start supporting your favorite artists with monthly sponsorships!',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Switch to the discover artists tab
                DefaultTabController.of(context).animateTo(0);
              },
              icon: const Icon(Icons.explore),
              label: const Text('Discover Artists'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSponsorshipCard(core.SponsorshipModel sponsorship) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  child: Text(
                    sponsorship.artistName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sponsorship.artistName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildTierBadge(sponsorship.tier),
                          const SizedBox(width: 8),
                          _buildStatusBadge(sponsorship.status),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) =>
                      _handleSponsorshipAction(value, sponsorship),
                  itemBuilder: (context) => [
                    if (sponsorship.isActive) ...[
                      const PopupMenuItem(
                        value: 'pause',
                        child: Row(
                          children: [
                            Icon(Icons.pause),
                            SizedBox(width: 8),
                            Text('Pause'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'change_tier',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Change Tier'),
                          ],
                        ),
                      ),
                    ],
                    if (sponsorship.isPaused)
                      const PopupMenuItem(
                        value: 'resume',
                        child: Row(
                          children: [
                            Icon(Icons.play_arrow),
                            SizedBox(width: 8),
                            Text('Resume'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'cancel',
                      child: Row(
                        children: [
                          Icon(Icons.cancel, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Cancel', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly Amount',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        Text(
                          '\$${sponsorship.monthlyAmount.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next Billing',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        Text(
                          _formatDate(sponsorship.nextBillingDate),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Since',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        Text(
                          _formatDate(sponsorship.createdAt),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Benefits:',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: sponsorship.benefits
                  .map(
                    (benefit) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getTierColor(
                          sponsorship.tier,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        benefit.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: _getTierColor(sponsorship.tier),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierBadge(core.SponsorshipTier tier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getTierColor(tier),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        tier.displayName,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(core.SponsorshipStatus status) {
    Color color;
    switch (status) {
      case core.SponsorshipStatus.active:
        color = Colors.green;
        break;
      case core.SponsorshipStatus.paused:
        color = Colors.orange;
        break;
      case core.SponsorshipStatus.cancelled:
        color = Colors.red;
        break;
      case core.SponsorshipStatus.pending:
        color = Colors.blue;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getTierColor(core.SponsorshipTier tier) {
    switch (tier) {
      case core.SponsorshipTier.bronze:
        return Colors.orange;
      case core.SponsorshipTier.silver:
        return Colors.grey;
      case core.SponsorshipTier.gold:
        return Colors.amber;
      case core.SponsorshipTier.platinum:
        return Colors.purple;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleSponsorshipAction(
    String action,
    core.SponsorshipModel sponsorship,
  ) {
    switch (action) {
      case 'pause':
        _pauseSponsorship(sponsorship);
        break;
      case 'resume':
        _resumeSponsorship(sponsorship);
        break;
      case 'change_tier':
        _changeTier(sponsorship);
        break;
      case 'cancel':
        _confirmCancelSponsorship(sponsorship);
        break;
    }
  }

  Future<void> _pauseSponsorship(core.SponsorshipModel sponsorship) async {
    try {
      await _sponsorshipService.pauseSponsorship(sponsorship.id);
      _loadSponsorships();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paused sponsorship for ${sponsorship.artistName}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pause sponsorship: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resumeSponsorship(core.SponsorshipModel sponsorship) async {
    try {
      await _sponsorshipService.resumeSponsorship(sponsorship.id);
      _loadSponsorships();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Resumed sponsorship for ${sponsorship.artistName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resume sponsorship: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _changeTier(core.SponsorshipModel sponsorship) {
    showDialog<core.SponsorshipTier>(
      context: context,
      builder: (context) => TierChangeDialog(
        currentTier: sponsorship.tier,
        artistName: sponsorship.artistName,
      ),
    ).then((newTier) {
      if (newTier != null && newTier != sponsorship.tier) {
        _submitTierChange(sponsorship, newTier);
      }
    });
  }

  Future<void> _submitTierChange(
    core.SponsorshipModel sponsorship,
    core.SponsorshipTier newTier,
  ) async {
    try {
      // Update the sponsorship tier
      await _sponsorshipService.updateSponsorshipTier(
        sponsorshipId: sponsorship.id,
        newTier: newTier,
      );

      // Refresh the sponsorships list
      await _loadSponsorships();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully changed sponsorship to ${newTier.displayName} tier',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to change tier: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmCancelSponsorship(core.SponsorshipModel sponsorship) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Sponsorship'),
        content: Text(
          'Are you sure you want to cancel your sponsorship for ${sponsorship.artistName}? This will stop all future payments and remove your sponsor benefits.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Sponsorship'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelSponsorship(sponsorship);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Sponsorship'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelSponsorship(core.SponsorshipModel sponsorship) async {
    try {
      await _sponsorshipService.cancelSponsorship(sponsorship.id);
      _loadSponsorships();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cancelled sponsorship for ${sponsorship.artistName}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel sponsorship: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Dialog for changing sponsorship tier
class TierChangeDialog extends StatefulWidget {
  final core.SponsorshipTier currentTier;
  final String artistName;

  const TierChangeDialog({
    super.key,
    required this.currentTier,
    required this.artistName,
  });

  @override
  State<TierChangeDialog> createState() => _TierChangeDialogState();
}

class _TierChangeDialogState extends State<TierChangeDialog> {
  core.SponsorshipTier? _selectedTier;

  @override
  void initState() {
    super.initState();
    _selectedTier = widget.currentTier;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Change Sponsorship Tier for ${widget.artistName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current tier: ${widget.currentTier.displayName}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Select new tier:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ...core.SponsorshipTier.values.map((tier) {
            final isSelected = _selectedTier == tier;
            final isCurrent = tier == widget.currentTier;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _selectedTier = tier;
                  });
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  side: BorderSide(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tier.displayName,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            '\$${tier.monthlyPrice}/month',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (isCurrent)
                            Text(
                              '(Current)',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed:
              _selectedTier != null && _selectedTier != widget.currentTier
              ? () => Navigator.of(context).pop(_selectedTier)
              : null,
          child: const Text('Change Tier'),
        ),
      ],
    );
  }
}
