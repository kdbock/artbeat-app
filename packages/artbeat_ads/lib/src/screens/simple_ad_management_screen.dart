import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import '../models/ad_model.dart';
import '../models/ad_status.dart';
import '../models/ad_size.dart';
import '../models/ad_location.dart';
import '../models/ad_zone.dart';
import '../models/ad_duration.dart';
import '../models/ad_type.dart';
import '../models/image_fit.dart';
import '../services/simple_ad_service.dart';
import '../widgets/simple_ad_display_widget.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Simplified admin screen for managing ads
class SimpleAdManagementScreen extends StatefulWidget {
  const SimpleAdManagementScreen({super.key});

  @override
  State<SimpleAdManagementScreen> createState() =>
      _SimpleAdManagementScreenState();
}

class _SimpleAdManagementScreenState extends State<SimpleAdManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late SimpleAdService _adService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _adService = SimpleAdService();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar header
        Container(
          color: Theme.of(context).primaryColor,
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: 'Pending'),
              Tab(text: 'All Ads'),
              Tab(text: 'Statistics'),
            ],
          ),
        ),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPendingAdsTab(),
              _buildAllAdsTab(),
              _buildStatisticsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPendingAdsTab() {
    return StreamBuilder<List<AdModel>>(
      stream: _adService.getPendingAds(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final ads = snapshot.data ?? [];

        if (ads.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text('No pending ads to review'),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Bulk actions header
            if (ads.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border(
                    bottom: BorderSide(color: Colors.orange.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.pending_actions, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Text(
                      '${ads.length} pending ads awaiting review',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (ads.length > 1)
                      ElevatedButton.icon(
                        onPressed: () => _bulkApproveAds(ads),
                        icon: const Icon(Icons.done_all, size: 16),
                        label: const Text('Approve All'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
              ),
            // Ads list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: ads.length,
                itemBuilder: (context, index) {
                  final ad = ads[index];
                  return _buildPendingAdCard(ad);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAllAdsTab() {
    return StreamBuilder<List<AdModel>>(
      stream: _adService.getAllAds(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final ads = snapshot.data ?? [];

        if (ads.isEmpty) {
          return const Center(child: Text('No ads found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ads.length,
          itemBuilder: (context, index) {
            final ad = ads[index];
            return _buildAdCard(ad);
          },
        );
      },
    );
  }

  Widget _buildStatisticsTab() {
    return FutureBuilder<Map<String, int>>(
      future: _adService.getAdsStatistics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final stats = snapshot.data ?? {};

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ad Statistics',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildStatCard('Total Ads', stats['total'] ?? 0, Colors.blue),
              _buildStatCard(
                'Pending Review',
                stats['pending'] ?? 0,
                Colors.orange,
              ),
              _buildStatCard('Approved', stats['approved'] ?? 0, Colors.green),
              _buildStatCard('Rejected', stats['rejected'] ?? 0, Colors.red),
              _buildStatCard('Expired', stats['expired'] ?? 0, Colors.grey),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPendingAdCard(AdModel ad) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Ad preview
                SizedBox(
                  width: 80,
                  height: 60,
                  child: SimpleAdDisplayWidget(
                    ad: ad,
                    location: AdLocation.fluidDashboard,
                  ),
                ),
                const SizedBox(width: 16),
                // Ad details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ad.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        ad.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _buildAdDetailsText(ad),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        _buildDurationText(ad),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    // Delay execution to allow popup menu to close properly
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      switch (value) {
                        case 'edit':
                          _editAd(ad);
                          break;
                        case 'duplicate':
                          _duplicateAd(ad);
                          break;
                      }
                    });
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 16),
                          SizedBox(width: 8),
                          Text('Duplicate'),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: const Icon(Icons.more_vert),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _rejectAd(ad),
                  child: const Text(
                    'Reject',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _approveAd(ad),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Approve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdCard(AdModel ad) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Ad preview
                SizedBox(
                  width: 80,
                  height: 60,
                  child: SimpleAdDisplayWidget(
                    ad: ad,
                    location: AdLocation.fluidDashboard,
                  ),
                ),
                const SizedBox(width: 16),
                // Ad details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ad.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildStatusChip(ad.status),
                        ],
                      ),
                      Text(
                        ad.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _buildAdDetailsText(ad),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        _buildDurationText(ad),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        _buildDateRangeText(ad),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    // Delay execution to allow popup menu to close properly
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      switch (value) {
                        case 'edit':
                          _editAd(ad);
                          break;
                        case 'duplicate':
                          _duplicateAd(ad);
                          break;
                      }
                    });
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 16),
                          SizedBox(width: 8),
                          Text('Duplicate'),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: const Icon(Icons.more_vert),
                  ),
                ),
                const SizedBox(width: 8),
                if (ad.status == AdStatus.approved)
                  TextButton(
                    onPressed: () => _pauseAd(ad),
                    child: const Text('Pause'),
                  ),
                if (ad.status == AdStatus.paused)
                  TextButton(
                    onPressed: () => _resumeAd(ad),
                    child: const Text('Resume'),
                  ),
                TextButton(
                  onPressed: () => _deleteAd(ad),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(width: 4, height: 40, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  Text(
                    value.toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
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

  Widget _buildStatusChip(AdStatus status) {
    Color color;
    String text;

    switch (status) {
      case AdStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case AdStatus.approved:
        color = Colors.green;
        text = 'Approved';
        break;
      case AdStatus.rejected:
        color = Colors.red;
        text = 'Rejected';
        break;
      case AdStatus.running:
        color = Colors.blue;
        text = 'Running';
        break;
      case AdStatus.paused:
        color = Colors.grey;
        text = 'Paused';
        break;
      case AdStatus.expired:
        color = Colors.grey.shade600;
        text = 'Expired';
        break;
      case AdStatus.draft:
        color = Colors.grey.shade400;
        text = 'Draft';
        break;
      case AdStatus.active:
        color = Colors.blue.shade700;
        text = 'Active';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _approveAd(AdModel ad) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _adService.approveAd(ad.id, user.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ad approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving ad: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectAd(AdModel ad) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _adService.rejectAd(ad.id, user.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ad rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting ad: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pauseAd(AdModel ad) async {
    try {
      await _adService.updateAdStatus(ad.id, AdStatus.paused);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ad paused')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error pausing ad: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resumeAd(AdModel ad) async {
    try {
      await _adService.updateAdStatus(ad.id, AdStatus.approved);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ad resumed')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resuming ad: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAd(AdModel ad) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Ad'),
        content: const Text(
          'Are you sure you want to delete this ad? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adService.deleteAd(ad.id);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Ad deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting ad: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _buildAdDetailsText(AdModel ad) {
    try {
      final typeName = ad.type.name;
      final sizeDisplay = ad.size.displayName;

      // Show zone if available, otherwise show legacy location
      final placementDisplay = ad.zone != null
          ? '${ad.zone!.icon} ${ad.zone!.displayName}'
          : ad.location.displayName;

      return '$typeName • $sizeDisplay • $placementDisplay';
    } catch (e) {
      // Fallback if any property access fails
      return 'Ad Details • ${ad.id.substring(0, 8)}...';
    }
  }

  String _buildDurationText(AdModel ad) {
    try {
      final days = ad.duration.days;

      // Calculate price: zone + size if zone available, otherwise use ad's pricePerDay getter
      final pricePerDay =
          ad.pricePerDay; // Uses the getter which handles zone + size
      final totalPrice = pricePerDay * days;

      return 'Duration: $days days (\$${totalPrice.toStringAsFixed(2)})';
    } catch (e) {
      // Fallback if any calculation fails
      return 'Duration: N/A';
    }
  }

  String _buildDateRangeText(AdModel ad) {
    try {
      final startDate = _formatDate(ad.startDate);
      final endDate = _formatDate(ad.endDate);
      return 'Dates: $startDate - $endDate';
    } catch (e) {
      // Fallback if date formatting fails
      return 'Dates: N/A';
    }
  }

  Future<void> _duplicateAd(AdModel ad) async {
    try {
      await _adService.duplicateAd(ad.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ad duplicated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error duplicating ad: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editAd(AdModel ad) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AdEditDialog(ad: ad),
    );
  }

  Future<void> _bulkApproveAds(List<AdModel> ads) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Approve Ads'),
        content: Text(
          'Are you sure you want to approve all ${ads.length} pending ads?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      int successCount = 0;
      int failureCount = 0;

      for (final ad in ads) {
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await _adService.approveAd(ad.id, user.uid);
            successCount++;
          }
        } catch (e) {
          failureCount++;
          AppLogger.error('Error approving ad ${ad.id}: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              successCount > 0
                  ? 'Successfully approved $successCount ads${failureCount > 0 ? ", $failureCount failed" : ""}'
                  : 'Failed to approve ads',
            ),
            backgroundColor: successCount > 0 ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}

/// Comprehensive ad editing dialog
class AdEditDialog extends StatefulWidget {
  final AdModel ad;

  const AdEditDialog({super.key, required this.ad});

  @override
  State<AdEditDialog> createState() => _AdEditDialogState();
}

class _AdEditDialogState extends State<AdEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _destinationUrlController = TextEditingController();
  final _ctaTextController = TextEditingController();

  late AdSize _selectedSize;
  AdZone? _selectedZone;
  late int _selectedDays;
  late AdType _selectedType;
  late AdStatus _selectedStatus;
  late ImageFit _selectedImageFit;
  late DateTime _selectedStartDate;

  bool _isLoading = false;
  final SimpleAdService _adService = SimpleAdService();
  final ImagePicker _imagePicker = ImagePicker();

  // Image editing state
  File? _selectedMainImage;
  final List<File> _selectedArtworkImages = [];
  String? _currentMainImageUrl;
  List<String> _currentArtworkUrls = [];

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.ad.title;
    _descriptionController.text = widget.ad.description;
    _destinationUrlController.text = widget.ad.destinationUrl ?? '';
    _ctaTextController.text = widget.ad.ctaText ?? '';
    _selectedSize = widget.ad.size;
    _selectedZone = widget.ad.zone; // Initialize zone from ad
    _selectedDays = widget.ad.duration.days;
    _selectedType = widget.ad.type;
    _selectedStatus = widget.ad.status;
    _selectedImageFit = widget.ad.imageFit;
    _selectedStartDate = widget.ad.startDate;

    // Initialize image state
    _currentMainImageUrl = widget.ad.imageUrl;
    _currentArtworkUrls = widget.ad.artworkUrls.isNotEmpty
        ? widget.ad.artworkUrls
        : [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _destinationUrlController.dispose();
    _ctaTextController.dispose();
    super.dispose();
  }

  // Image editing methods
  Future<void> _pickMainImage() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedMainImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _pickArtworkImage() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedArtworkImages.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<String?> _uploadImage(File imageFile, String path) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      AppLogger.error('Error uploading image: $e');
      return null;
    }
  }

  void _removeArtworkImage(int index) {
    setState(() {
      if (index < _selectedArtworkImages.length) {
        _selectedArtworkImages.removeAt(index);
      } else {
        final currentIndex = index - _selectedArtworkImages.length;
        if (currentIndex < _currentArtworkUrls.length) {
          _currentArtworkUrls.removeAt(currentIndex);
        }
      }
    });
  }

  Color _getStatusColor(AdStatus status) {
    switch (status) {
      case AdStatus.pending:
        return Colors.orange;
      case AdStatus.approved:
        return Colors.green;
      case AdStatus.rejected:
        return Colors.red;
      case AdStatus.running:
        return Colors.blue;
      case AdStatus.paused:
        return Colors.grey;
      case AdStatus.expired:
        return Colors.black54;
      case AdStatus.draft:
        return Colors.grey.shade400;
      case AdStatus.active:
        return Colors.blue.shade700;
    }
  }

  Future<void> _updateAd() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload new images if selected
      String? newMainImageUrl = _currentMainImageUrl;
      final List<String> newArtworkUrls = List.from(_currentArtworkUrls);

      // Upload main image if changed
      if (_selectedMainImage != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final path =
              'ad_images/${user.uid}/${widget.ad.id}/main_${DateTime.now().millisecondsSinceEpoch}.jpg';
          newMainImageUrl = await _uploadImage(_selectedMainImage!, path);
        }
      }

      // Upload new artwork images
      for (final imageFile in _selectedArtworkImages) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final path =
              'ad_images/${user.uid}/${widget.ad.id}/artwork_${DateTime.now().millisecondsSinceEpoch}_${_selectedArtworkImages.indexOf(imageFile)}.jpg';
          final uploadedUrl = await _uploadImage(imageFile, path);
          if (uploadedUrl != null) {
            newArtworkUrls.add(uploadedUrl);
          }
        }
      }

      // Calculate new end date based on updated duration
      // Create updated ad model
      // Create duration object based on selected days
      AdDuration duration;
      switch (_selectedDays) {
        case 1:
          duration = AdDuration.oneDay;
          break;
        case 3:
          duration = AdDuration.threeDays;
          break;
        case 7:
          duration = AdDuration.oneWeek;
          break;
        case 14:
          duration = AdDuration.twoWeeks;
          break;
        case 30:
          duration = AdDuration.oneMonth;
          break;
        default:
          duration = AdDuration.custom;
          break;
      }

      final updatedAd = AdModel(
        id: widget.ad.id,
        ownerId: widget.ad.ownerId,
        type: _selectedType, // Updated type
        size: _selectedSize,
        imageUrl:
            newMainImageUrl ??
            widget.ad.imageUrl, // Use new image or keep original
        artworkUrls: newArtworkUrls, // Use updated artwork URLs
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: widget
            .ad
            .location, // Keep original location for backward compatibility
        zone: _selectedZone, // Updated zone
        duration: duration,
        startDate: _selectedStartDate, // Updated start date
        endDate: _selectedStartDate.add(
          Duration(days: _selectedDays),
        ), // Recalculate end date
        status: _selectedStatus, // Updated status
        approvalId: widget.ad.approvalId,
        destinationUrl: _destinationUrlController.text.trim().isEmpty
            ? null
            : _destinationUrlController.text.trim(),
        ctaText: _ctaTextController.text.trim().isEmpty
            ? null
            : _ctaTextController.text.trim(),
        imageFit: _selectedImageFit, // Updated image fit
      );

      // Create data map for update
      final updateData = {
        'title': updatedAd.title,
        'description': updatedAd.description,
        'type': updatedAd.type.index, // Store as integer index
        'size': updatedAd.size.index, // Store as integer index
        if (updatedAd.zone != null)
          'zone': updatedAd.zone!.index, // Store zone as integer index
        'duration': updatedAd.duration.toMap(),
        'startDate': Timestamp.fromDate(
          updatedAd.startDate,
        ), // Add start date update
        'endDate': Timestamp.fromDate(updatedAd.endDate),
        'status': updatedAd.status.index, // Store as integer index
        'imageFit':
            updatedAd.imageFit.index, // Store image fit as integer index
        if (updatedAd.destinationUrl != null)
          'destinationUrl': updatedAd.destinationUrl,
        if (updatedAd.ctaText != null) 'ctaText': updatedAd.ctaText,
        if (newMainImageUrl != null) 'imageUrl': newMainImageUrl,
        'artworkUrls': newArtworkUrls,
      };

      await _adService.updateAd(widget.ad.id, updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ad updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating ad: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.95,
          minHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Edit Ad',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Action buttons in header - compact layout
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _updateAd,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue,
                              ),
                            ),
                          )
                        : const Text('Update', style: TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Content - Make this take remaining space and scroll
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Ad Preview
                      const Text(
                        'Current Ad Preview',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SimpleAdDisplayWidget(
                          ad: widget.ad,
                          location: AdLocation.fluidDashboard,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Basic Information
                      const Text(
                        'Basic Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Ad Title *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description *',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Destination URL
                      TextFormField(
                        controller: _destinationUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Destination URL (optional)',
                          hintText: 'https://example.com',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 12),

                      // CTA Text
                      TextFormField(
                        controller: _ctaTextController,
                        decoration: const InputDecoration(
                          labelText: 'Call-to-Action Text (optional)',
                          hintText: 'Shop Now, Learn More, etc.',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Section Divider
                      const Divider(thickness: 1, height: 32),
                      const SizedBox(height: 8),

                      // Ad Type Selection
                      const Text('Ad Type'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<AdType>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: AdType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(
                              type.name,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedType = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Start Date Selection
                      const Text('Start Date'),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: _selectedStartDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              _selectedStartDate = pickedDate;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            '${_selectedStartDate.month}/${_selectedStartDate.day}/${_selectedStartDate.year}',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Status Selection (Admin only)
                      const Text('Status'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<AdStatus>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: AdStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(
                              status.name.toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(status).withOpacity(0.9),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedStatus = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 24),

                      // Section Divider
                      const Divider(thickness: 1, height: 32),
                      const SizedBox(height: 8),

                      // Image Management Section
                      const Text(
                        'Image Management',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Main Ad Image
                      const Text(
                        'Main Ad Image',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _selectedMainImage != null
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _selectedMainImage!,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _selectedMainImage = null;
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                      ),
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : _currentMainImageUrl != null
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      _currentMainImageUrl!,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return const Center(
                                              child: Icon(
                                                Icons.broken_image,
                                                size: 48,
                                                color: Colors.grey,
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _currentMainImageUrl = null;
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                      ),
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : InkWell(
                                onTap: _pickMainImage,
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate,
                                        size: 48,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Tap to select main image',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // Artwork Images
                      const Text(
                        'Additional Artwork Images (Optional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Display current artwork images
                      if (_selectedArtworkImages.isNotEmpty ||
                          _currentArtworkUrls.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            // Selected new images
                            ..._selectedArtworkImages.asMap().entries.map((
                              entry,
                            ) {
                              final index = entry.key;
                              final imageFile = entry.value;
                              return Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        imageFile,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: IconButton(
                                        onPressed: () =>
                                            _removeArtworkImage(index),
                                        icon: const Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.black54,
                                          padding: const EdgeInsets.all(4),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            // Current images
                            ..._currentArtworkUrls.asMap().entries.map((entry) {
                              final index =
                                  entry.key + _selectedArtworkImages.length;
                              final imageUrl = entry.value;
                              return Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        imageUrl,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return const Center(
                                                child: Icon(
                                                  Icons.broken_image,
                                                  size: 24,
                                                  color: Colors.grey,
                                                ),
                                              );
                                            },
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: IconButton(
                                        onPressed: () =>
                                            _removeArtworkImage(index),
                                        icon: const Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.black54,
                                          padding: const EdgeInsets.all(4),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),

                      // Add artwork image button
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _pickArtworkImage,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Add Artwork Image'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Section Divider
                      const Divider(thickness: 1, height: 32),
                      const SizedBox(height: 8),

                      // Ad Configuration
                      const Text(
                        'Ad Configuration',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Zone Selection
                      const Text('Display Zone'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<AdZone>(
                        value: _selectedZone,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: AdZone.values.map((zone) {
                          return DropdownMenuItem(
                            value: zone,
                            child: Row(
                              mainAxisSize: MainAxisSize
                                  .min, // Fixed unbounded width constraint issue
                              children: [
                                Icon(
                                  zone.iconData,
                                  size: 20,
                                  color: Colors.black54,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    zone.displayName,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Text(
                                  '\$${zone.pricePerDay.toStringAsFixed(0)}/day',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedZone = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Size Selection
                      const Text('Ad Size'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<AdSize>(
                        value: _selectedSize,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: AdSize.values.map((size) {
                          return DropdownMenuItem(
                            value: size,
                            child: Text(
                              '${size.displayName} (+\$${size.pricePerDay.toStringAsFixed(0)}/day)',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedSize = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Image Fit Selection
                      const Text('Image Display Mode'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<ImageFit>(
                        value: _selectedImageFit,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: ImageFit.values.map((fit) {
                          return DropdownMenuItem(
                            value: fit,
                            child: Text(
                              fit.displayName,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedImageFit = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Duration
                      const Text('Duration (days)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: _selectedDays.toString(),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter duration';
                          }
                          final days = int.tryParse(value);
                          if (days == null || days < 1) {
                            return 'Please enter a valid number of days';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          final days = int.tryParse(value);
                          if (days != null && days > 0) {
                            setState(() {
                              _selectedDays = days;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 32),

                      // Section Divider
                      const Divider(thickness: 2, height: 40),
                      const SizedBox(height: 16),

                      // Cost Summary
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Updated Cost Summary',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Type: ${_selectedType.name}'),
                            if (_selectedZone != null)
                              Text('Zone: ${_selectedZone!.displayName}'),
                            Text('Size: ${_selectedSize.displayName}'),
                            Text(
                              'Start Date: ${_selectedStartDate.month}/${_selectedStartDate.day}/${_selectedStartDate.year}',
                            ),
                            Text('Duration: $_selectedDays days'),
                            Text(
                              'Status: ${_selectedStatus.name.toUpperCase()}',
                            ),
                            const Divider(),
                            if (_selectedZone != null) ...[
                              Text(
                                'Zone: \$${_selectedZone!.pricePerDay.toStringAsFixed(0)}/day',
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                'Size: +\$${_selectedSize.pricePerDay.toStringAsFixed(0)}/day',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Total: \$${((_selectedZone!.pricePerDay + _selectedSize.pricePerDay) * _selectedDays).toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ] else
                              Text(
                                'Total: \$${(_selectedSize.pricePerDay * _selectedDays).toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
