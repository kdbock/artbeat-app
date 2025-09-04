import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/coupon_dialogs.dart';

/// Admin Coupon Management Screen
///
/// Features:
/// - View existing coupons
/// - Create new coupons
/// - Edit coupon details
/// - Delete coupons
/// - Track coupon usage
/// - Real-time statistics
class AdminCouponManagementScreen extends StatefulWidget {
  const AdminCouponManagementScreen({super.key});

  @override
  State<AdminCouponManagementScreen> createState() =>
      _AdminCouponManagementScreenState();
}

class _AdminCouponManagementScreenState
    extends State<AdminCouponManagementScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final CouponService _couponService = CouponService();

  List<CouponModel> _coupons = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get all coupons created by the current admin user
      final coupons = await _couponService.getMyCoupons().first;

      if (mounted) {
        setState(() {
          _coupons = coupons;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1, // Admin screens don't use bottom navigation
      scaffoldKey: _scaffoldKey,
      appBar: EnhancedUniversalHeader(
        title: 'Coupon Management',
        showBackButton: true,
        showSearch: true,
        showDeveloperTools: true,
        actions: [
          IconButton(
            onPressed: _showCreateCouponDialog,
            icon: const Icon(Icons.add),
            tooltip: 'Create Coupon',
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildErrorWidget()
                  : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadCoupons,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildCouponStats(),
            const SizedBox(height: 24),
            _buildCouponsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Coupon Management',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create and manage discount coupons for your users',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponStats() {
    final activeCoupons =
        _coupons.where((c) => c.status == CouponStatus.active).length;
    final expiredCoupons =
        _coupons.where((c) => c.status == CouponStatus.expired).length;
    final totalUsage = _coupons.fold<int>(0, (sum, c) => sum + c.currentUses);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard('Total Coupons', _coupons.length.toString(),
            Icons.local_offer, Colors.blue),
        _buildStatCard('Active Coupons', activeCoupons.toString(),
            Icons.check_circle, Colors.green),
        _buildStatCard('Expired Coupons', expiredCoupons.toString(),
            Icons.cancel, Colors.red),
        _buildStatCard('Total Usage', totalUsage.toString(), Icons.trending_up,
            Colors.orange),
      ],
    );
  }

  Widget _buildCouponsList() {
    if (_coupons.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Coupons',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _showCreateCouponDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Coupon'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.local_offer_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No coupons created yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Create your first coupon to get started',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Coupons',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showCreateCouponDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Coupon'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _coupons.length,
              itemBuilder: (context, index) {
                final coupon = _coupons[index];
                return _buildCouponCard(coupon);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponCard(CouponModel coupon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCouponTypeColor(coupon.type),
          child: Icon(
            _getCouponTypeIcon(coupon.type),
            color: Colors.white,
          ),
        ),
        title: Text(
          coupon.title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Code: ${coupon.code}'),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildStatusChip(coupon.status),
                const SizedBox(width: 8),
                Text(
                  'Uses: ${coupon.currentUses}${coupon.maxUses != null ? '/${coupon.maxUses}' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleCouponAction(coupon, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Text('Edit'),
            ),
            const PopupMenuItem(
              value: 'toggle',
              child: Text('Toggle Status'),
            ),
            const PopupMenuItem(
              value: 'stats',
              child: Text('View Stats'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete'),
            ),
          ],
        ),
        onTap: () => _showCouponDetails(coupon),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(CouponStatus status) {
    Color color;
    String text;

    switch (status) {
      case CouponStatus.active:
        color = Colors.green;
        text = 'Active';
        break;
      case CouponStatus.inactive:
        color = Colors.orange;
        text = 'Inactive';
        break;
      case CouponStatus.expired:
        color = Colors.red;
        text = 'Expired';
        break;
      case CouponStatus.exhausted:
        color = Colors.grey;
        text = 'Exhausted';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading coupons',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadCoupons,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showCreateCouponDialog() {
    showDialog<bool>(
      context: context,
      builder: (context) => const CreateCouponDialog(),
    ).then((result) {
      if (result == true) {
        _loadCoupons();
      }
    });
  }

  void _showCouponDetails(CouponModel coupon) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(coupon.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Code: ${coupon.code}'),
              const SizedBox(height: 8),
              Text('Description: ${coupon.description}'),
              const SizedBox(height: 8),
              Text('Type: ${_getCouponTypeDisplayName(coupon.type)}'),
              const SizedBox(height: 8),
              Text('Status: ${_getStatusDisplayName(coupon.status)}'),
              const SizedBox(height: 8),
              Text(
                  'Uses: ${coupon.currentUses}${coupon.maxUses != null ? '/${coupon.maxUses}' : ''}'),
              if (coupon.expiresAt != null) ...[
                const SizedBox(height: 8),
                Text('Expires: ${_formatDate(coupon.expiresAt!)}'),
              ],
              const SizedBox(height: 8),
              Text('Created: ${_formatDate(coupon.createdAt)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleCouponAction(CouponModel coupon, String action) {
    switch (action) {
      case 'edit':
        _showEditCouponDialog(coupon);
        break;
      case 'toggle':
        _toggleCouponStatus(coupon);
        break;
      case 'stats':
        _showCouponStats(coupon);
        break;
      case 'delete':
        _showDeleteConfirmation(coupon);
        break;
    }
  }

  void _showEditCouponDialog(CouponModel coupon) {
    showDialog<bool>(
      context: context,
      builder: (context) => EditCouponDialog(coupon: coupon),
    ).then((result) {
      if (result == true) {
        _loadCoupons();
      }
    });
  }

  void _toggleCouponStatus(CouponModel coupon) async {
    try {
      final newStatus = coupon.status == CouponStatus.active
          ? CouponStatus.inactive
          : CouponStatus.active;

      await _couponService.updateCouponStatus(coupon.id, newStatus);
      _loadCoupons();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Coupon ${newStatus == CouponStatus.active ? 'activated' : 'deactivated'}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update coupon: $e')),
        );
      }
    }
  }

  void _showCouponStats(CouponModel coupon) async {
    try {
      final stats = await _couponService.getCouponStats(coupon.id);

      if (mounted) {
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Stats for ${coupon.title}'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Total Uses: ${stats['totalUses']}'),
                  if (stats['remainingUses'] != null) ...[
                    const SizedBox(height: 8),
                    Text('Remaining Uses: ${stats['remainingUses']}'),
                  ],
                  const SizedBox(height: 8),
                  Text(
                      'Total Revenue: \$${stats['totalRevenue'].toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  Text('Subscriptions: ${stats['subscriptionCount']}'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load stats: $e')),
        );
      }
    }
  }

  void _showDeleteConfirmation(CouponModel coupon) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Coupon'),
        content: Text(
          'Are you sure you want to delete "${coupon.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _couponService.deleteCoupon(coupon.id);
                Navigator.of(context).pop();
                _loadCoupons();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Coupon deleted successfully')),
                  );
                }
              } catch (e) {
                Navigator.of(context).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete coupon: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _getCouponTypeColor(CouponType type) {
    switch (type) {
      case CouponType.fullAccess:
        return Colors.purple;
      case CouponType.percentageDiscount:
        return Colors.blue;
      case CouponType.fixedDiscount:
        return Colors.green;
      case CouponType.freeTrial:
        return Colors.orange;
    }
  }

  IconData _getCouponTypeIcon(CouponType type) {
    switch (type) {
      case CouponType.fullAccess:
        return Icons.vpn_key;
      case CouponType.percentageDiscount:
        return Icons.percent;
      case CouponType.fixedDiscount:
        return Icons.attach_money;
      case CouponType.freeTrial:
        return Icons.access_time;
    }
  }

  String _getCouponTypeDisplayName(CouponType type) {
    switch (type) {
      case CouponType.fullAccess:
        return 'Full Access';
      case CouponType.percentageDiscount:
        return 'Percentage Discount';
      case CouponType.fixedDiscount:
        return 'Fixed Discount';
      case CouponType.freeTrial:
        return 'Free Trial';
    }
  }

  String _getStatusDisplayName(CouponStatus status) {
    switch (status) {
      case CouponStatus.active:
        return 'Active';
      case CouponStatus.inactive:
        return 'Inactive';
      case CouponStatus.expired:
        return 'Expired';
      case CouponStatus.exhausted:
        return 'Exhausted';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
