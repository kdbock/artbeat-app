import 'package:flutter/material.dart';
import '../../models/direct_commission_model.dart';
import '../../services/direct_commission_service.dart';
import 'package:artbeat_core/artbeat_core.dart';

class CommissionGalleryScreen extends StatefulWidget {
  final String? artistId;

  const CommissionGalleryScreen({Key? key, this.artistId}) : super(key: key);

  @override
  State<CommissionGalleryScreen> createState() =>
      _CommissionGalleryScreenState();
}

class _CommissionGalleryScreenState extends State<CommissionGalleryScreen> {
  late DirectCommissionService _commissionService;
  List<DirectCommissionModel> _commissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _commissionService = DirectCommissionService();
    _loadCommissions();
  }

  Future<void> _loadCommissions() async {
    try {
      if (widget.artistId != null) {
        final commissions = await _commissionService.getCommissionsByUser(
          widget.artistId!,
        );
        final completed = commissions
            .where(
              (c) =>
                  c.status == CommissionStatus.completed ||
                  c.status == CommissionStatus.delivered,
            )
            .toList();
        setState(() {
          _commissions = completed;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('Failed to load commissions: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Commission Gallery'), elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _commissions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No completed commissions yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: _commissions.length,
              itemBuilder: (context, index) {
                final commission = _commissions[index];
                return _buildCommissionCard(context, commission);
              },
            ),
    );
  }

  Widget _buildCommissionCard(
    BuildContext context,
    DirectCommissionModel commission,
  ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Navigate to detail screen
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder for image
            Expanded(
              child: Container(
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.palette, size: 40, color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    commission.title,
                    style: Theme.of(context).textTheme.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    commission.type.displayName,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${commission.totalPrice.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(Icons.check_circle, size: 16, color: Colors.green),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
