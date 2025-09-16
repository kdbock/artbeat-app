import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;

class SponsorTierSelectionDialog extends StatefulWidget {
  final String artistId;
  final String artistName;
  final VoidCallback onSponsorshipCreated;

  const SponsorTierSelectionDialog({
    super.key,
    required this.artistId,
    required this.artistName,
    required this.onSponsorshipCreated,
  });

  @override
  State<SponsorTierSelectionDialog> createState() =>
      _SponsorTierSelectionDialogState();
}

class _SponsorTierSelectionDialogState
    extends State<SponsorTierSelectionDialog> {
  final core.SponsorshipService _sponsorshipService = core.SponsorshipService();
  final core.EnhancedPaymentService _paymentService =
      core.EnhancedPaymentService();

  core.SponsorshipTier? _selectedTier;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header (fixed at top)
            Padding(padding: const EdgeInsets.all(24), child: _buildHeader()),
            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTierSelection(),
                    const SizedBox(height: 24),
                    if (_selectedTier != null) ...[
                      _buildSelectedTierInfo(),
                      const SizedBox(height: 24),
                    ],
                    if (_errorMessage != null) ...[
                      _buildErrorMessage(),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
            // Actions (fixed at bottom)
            Padding(padding: const EdgeInsets.all(24), child: _buildActions()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.handshake, color: Colors.purple[600], size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Sponsor ${widget.artistName}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Choose a sponsorship tier to support this artist with monthly recurring payments.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildTierSelection() {
    final tiers = _sponsorshipService.getAvailableTiers();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Sponsorship Tier',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...tiers.map((tier) => _buildTierCard(tier)),
      ],
    );
  }

  Widget _buildTierCard(core.SponsorshipTier tier) {
    final isSelected = _selectedTier == tier;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTier = tier;
          _errorMessage = null;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? tier.color.withValues(alpha: 0.1)
              : Colors.grey[50],
          border: Border.all(
            color: isSelected ? tier.color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? tier.color : Colors.grey[400]!,
                  width: 2,
                ),
                color: isSelected ? tier.color : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        tier.displayName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? tier.color : null,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        '\$${tier.monthlyPrice.toStringAsFixed(0)}/month',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? tier.color : Colors.grey[700],
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tier.description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: tier.defaultBenefits
                        .map(
                          (benefit) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: tier.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              benefit.name,
                              style: TextStyle(
                                fontSize: 10,
                                color: tier.color,
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
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedTierInfo() {
    if (_selectedTier == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Sponsorship Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Monthly payment: \$${_selectedTier!.monthlyPrice.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 12),
          ),
          const Text(
            '• Automatic billing on the same date each month',
            style: TextStyle(fontSize: 12),
          ),
          const Text(
            '• Cancel or change tier anytime',
            style: TextStyle(fontSize: 12),
          ),
          const Text(
            '• Benefits activate immediately',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red[700], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading || _selectedTier == null
                ? null
                : _createSponsorship,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Start Sponsorship'),
          ),
        ),
      ],
    );
  }

  Future<void> _createSponsorship() async {
    if (_selectedTier == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get payment methods with risk assessment using enhanced service
      final paymentMethods = await _paymentService.getPaymentMethodsWithRisk();

      // Find the default payment method
      final defaultPaymentMethod = paymentMethods
          .where((method) => method.isDefault)
          .firstOrNull;

      if (defaultPaymentMethod == null) {
        throw Exception(
          'No payment method found. Please add a payment method first.',
        );
      }

      // Create sponsorship using enhanced payment service
      await _sponsorshipService.createSponsorship(
        artistId: widget.artistId,
        tier: _selectedTier!,
        paymentMethodId: defaultPaymentMethod.id,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onSponsorshipCreated();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully started ${_selectedTier!.displayName} sponsorship for ${widget.artistName}!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

// Extension to add colors to sponsorship tiers
extension SponsorshipTierColors on core.SponsorshipTier {
  Color get color {
    switch (this) {
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
}
