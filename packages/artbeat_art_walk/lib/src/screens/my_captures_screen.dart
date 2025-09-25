import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_capture/artbeat_capture.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show OptimizedImage, MainLayout, ImageUrlValidator, EnhancedUniversalHeader;

import '../widgets/art_walk_drawer.dart';
import '../theme/art_walk_design_system.dart';

/// Screen to display user's captured art
class MyCapturesScreen extends StatefulWidget {
  final CaptureModel? initialCapture;

  const MyCapturesScreen({super.key, this.initialCapture});

  @override
  State<MyCapturesScreen> createState() => _MyCapturesScreenState();
}

class _MyCapturesScreenState extends State<MyCapturesScreen>
    with AutomaticKeepAliveClientMixin {
  final CaptureService _captureService = CaptureService();
  List<CaptureModel> _captures = [];
  List<CaptureModel> _filteredCaptures = [];
  bool _isLoading = true;
  String _selectedStatus = 'All'; // All, Active, Completed, Draft

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadCaptures();
  }

  Future<void> _loadCaptures() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.uid == null) {
        setState(() {
          _captures = [];
          _isLoading = false;
        });
        return;
      }

      final captures = await _captureService.getCapturesForUser(user!.uid);
      // debugPrint('📸 Loaded ${captures.length} captures for user in my_captures_screen');
      if (mounted) {
        setState(() {
          _captures = captures;
          _filteredCaptures = captures;
          _isLoading = false;
        });
        _applyStatusFilter();
      }
    } catch (e) {
      // debugPrint('Error loading captures: $e');
      if (mounted) {
        setState(() {
          _captures = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to load captures. Please try again.'),
            backgroundColor: ArtWalkDesignSystem.accentOrange,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadCaptures,
            ),
          ),
        );
      }
    }
  }

  void _onStatusFilterChanged(String status) {
    setState(() {
      _selectedStatus = status;
    });
    _applyStatusFilter();
  }

  void _applyStatusFilter() {
    List<CaptureModel> filtered = List.from(_captures);

    switch (_selectedStatus) {
      case 'Active':
        // Filter for captures that are actively being worked on (recently created or processing)
        filtered = filtered.where((capture) {
          final createdAt = capture.createdAt;
          final daysSinceCreation = DateTime.now().difference(createdAt).inDays;
          return daysSinceCreation <= 7 || !capture.isProcessed;
        }).toList();
        break;
      case 'Completed':
        // Filter for captures that have complete information and are processed
        filtered = filtered.where((capture) {
          return capture.title?.isNotEmpty == true &&
              capture.artistName?.isNotEmpty == true &&
              capture.description?.isNotEmpty == true &&
              capture.isProcessed;
        }).toList();
        break;
      case 'Draft':
        // Filter for captures that are incomplete/draft
        filtered = filtered.where((capture) {
          return capture.title?.isEmpty == true ||
              capture.artistName?.isEmpty == true ||
              capture.description?.isEmpty == true ||
              !capture.isProcessed;
        }).toList();
        break;
      case 'All':
      default:
        // No status filtering
        break;
    }

    setState(() {
      _filteredCaptures = filtered;
    });
  }

  void _refreshCaptures() async {
    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Refreshing captures...'),
            ],
          ),
          duration: Duration(seconds: 2),
          backgroundColor: ArtWalkDesignSystem.primaryTeal,
        ),
      );
    }

    // Reload captures
    await _loadCaptures();

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 16),
              SizedBox(width: 12),
              Text('Captures updated!'),
            ],
          ),
          duration: Duration(seconds: 2),
          backgroundColor: ArtWalkDesignSystem.accentOrange,
        ),
      );
    }
  }

  void _openCamera() {
    Navigator.pushNamed(context, '/capture');
  }

  Future<void> _editCapture(CaptureModel capture) async {
    // Check if user owns this capture
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.uid != capture.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only edit your own captures.'),
          backgroundColor: ArtWalkDesignSystem.accentOrange,
        ),
      );
      return;
    }

    // Show edit dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditCaptureDialog(capture: capture),
    );

    if (result != null && mounted) {
      // Update the capture
      final success = await _captureService.updateCapture(capture.id, result);
      if (success) {
        // Refresh the captures list
        await _loadCaptures();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Capture updated successfully!'),
            backgroundColor: ArtWalkDesignSystem.primaryTeal,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update capture. Please try again.'),
            backgroundColor: ArtWalkDesignSystem.accentOrange,
          ),
        );
      }
    }
  }

  Future<void> _deleteCapture(CaptureModel capture) async {
    // Check if user owns this capture
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.uid != capture.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only delete your own captures.'),
          backgroundColor: ArtWalkDesignSystem.accentOrange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ArtWalkDesignSystem.cardBackground,
        title: const Text(
          'Delete Capture',
          style: TextStyle(color: ArtWalkDesignSystem.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to delete this capture? This action cannot be undone.',
          style: TextStyle(color: ArtWalkDesignSystem.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: ArtWalkDesignSystem.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: ArtWalkDesignSystem.accentOrange,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Delete the capture
      final success = await _captureService.deleteCapture(capture.id);
      if (success) {
        // Remove from local list immediately for better UX
        setState(() {
          _captures.removeWhere((c) => c.id == capture.id);
          _filteredCaptures.removeWhere((c) => c.id == capture.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Capture deleted successfully!'),
            backgroundColor: ArtWalkDesignSystem.primaryTeal,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete capture. Please try again.'),
            backgroundColor: ArtWalkDesignSystem.accentOrange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return MainLayout(
      currentIndex: -1, // Hide bottom navigation for this screen
      drawer: const ArtWalkDrawer(),
      appBar: const EnhancedUniversalHeader(
        title: 'My Captures',
        showBackButton: true,
        backgroundGradient: ArtWalkDesignSystem.headerGradient,
      ),
      child: ArtWalkDesignSystem.buildScreenContainer(
        child: _isLoading
            ? ArtWalkScreenTemplate.buildLoadingState(
                message: 'Loading your captures...',
              )
            : _captures.isEmpty
            ? ArtWalkScreenTemplate.buildEmptyState(
                title: 'No Captures Yet',
                subtitle: 'Start capturing art to see your collection here.',
                icon: Icons.camera_alt,
                actionText: 'Capture Art',
                onAction: () => Navigator.pushNamed(context, '/capture'),
              )
            : _filteredCaptures.isEmpty
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFilterBar(),
                  ArtWalkScreenTemplate.buildEmptyState(
                    title: 'No Captures Found',
                    subtitle: 'Try adjusting your filter to see more captures.',
                    icon: Icons.filter_list,
                    actionText: 'Show All',
                    onAction: () => _onStatusFilterChanged('All'),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [_buildFilterBar(), _buildCapturesGrid()],
              ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      margin: const EdgeInsets.all(ArtWalkDesignSystem.paddingM),
      padding: const EdgeInsets.symmetric(
        horizontal: ArtWalkDesignSystem.paddingM,
        vertical: ArtWalkDesignSystem.paddingS,
      ),
      decoration: ArtWalkDesignSystem.glassDecoration(),
      child: Row(
        children: [
          // Status Filter Dropdown
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: ArtWalkDesignSystem.cardBackground.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ArtWalkDesignSystem.primaryTeal.withValues(alpha: 0.3),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedStatus,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: ArtWalkDesignSystem.primaryTeal,
                  ),
                  style: const TextStyle(
                    color: ArtWalkDesignSystem.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  dropdownColor: ArtWalkDesignSystem.cardBackground,
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Captures')),
                    DropdownMenuItem(value: 'Active', child: Text('Active')),
                    DropdownMenuItem(
                      value: 'Completed',
                      child: Text('Completed'),
                    ),
                    DropdownMenuItem(value: 'Draft', child: Text('Draft')),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      _onStatusFilterChanged(newValue);
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: ArtWalkDesignSystem.paddingM),
          // Refresh Button
          Container(
            decoration: BoxDecoration(
              color: ArtWalkDesignSystem.primaryTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: ArtWalkDesignSystem.primaryTeal.withValues(alpha: 0.3),
              ),
            ),
            child: IconButton(
              onPressed: _refreshCaptures,
              icon: const Icon(
                Icons.refresh,
                color: ArtWalkDesignSystem.primaryTeal,
                size: 20,
              ),
              tooltip: 'Refresh Captures',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ),
          const SizedBox(width: ArtWalkDesignSystem.paddingS),
          // Camera Button
          Container(
            decoration: BoxDecoration(
              color: ArtWalkDesignSystem.accentOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: ArtWalkDesignSystem.accentOrange.withValues(alpha: 0.3),
              ),
            ),
            child: IconButton(
              onPressed: _openCamera,
              icon: const Icon(
                Icons.camera_alt,
                color: ArtWalkDesignSystem.accentOrange,
                size: 20,
              ),
              tooltip: 'Capture Art',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapturesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(ArtWalkDesignSystem.paddingM),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: ArtWalkDesignSystem.paddingM,
        mainAxisSpacing: ArtWalkDesignSystem.paddingM,
        childAspectRatio: 0.8,
      ),
      itemCount: _filteredCaptures.length,
      itemBuilder: (context, index) {
        final capture = _filteredCaptures[index];
        return CaptureCard(
          capture: capture,
          index: index,
          onTap: () => _showCaptureDetails(capture),
          onEdit: () => _editCapture(capture),
          onDelete: () => _deleteCapture(capture),
        );
      },
    );
  }

  void _showCaptureDetails(CaptureModel capture) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: ArtWalkDesignSystem.glassDecoration(),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(ArtWalkDesignSystem.paddingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(
                      bottom: ArtWalkDesignSystem.paddingL,
                    ),
                    decoration: BoxDecoration(
                      color: ArtWalkDesignSystem.textSecondary.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (ImageUrlValidator.isValidImageUrl(capture.imageUrl))
                  Container(
                    height: 200,
                    width: double.infinity,
                    margin: const EdgeInsets.only(
                      bottom: ArtWalkDesignSystem.paddingM,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        ArtWalkDesignSystem.radiusL,
                      ),
                      image: DecorationImage(
                        image: NetworkImage(capture.imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                Text(
                  capture.title ?? 'Untitled Capture',
                  style: ArtWalkDesignSystem.cardTitleStyle,
                ),
                const SizedBox(height: ArtWalkDesignSystem.paddingS),
                if (capture.artistName?.isNotEmpty == true) ...[
                  Text(
                    'Artist: ${capture.artistName}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: ArtWalkDesignSystem.primaryTeal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: ArtWalkDesignSystem.paddingS),
                ],
                if (capture.description?.isNotEmpty == true) ...[
                  Text(
                    capture.description!,
                    style: ArtWalkDesignSystem.cardSubtitleStyle,
                  ),
                  const SizedBox(height: ArtWalkDesignSystem.paddingM),
                ],
                if (capture.locationName?.isNotEmpty == true)
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: ArtWalkDesignSystem.primaryTeal,
                        size: 20,
                      ),
                      const SizedBox(width: ArtWalkDesignSystem.paddingS),
                      Expanded(
                        child: Text(
                          capture.locationName!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: ArtWalkDesignSystem.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Optimized capture card widget with proper disposal management
class CaptureCard extends StatefulWidget {
  final CaptureModel capture;
  final int index;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CaptureCard({
    super.key,
    required this.capture,
    required this.index,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<CaptureCard> createState() => _CaptureCardState();
}

class _CaptureCardState extends State<CaptureCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Container(
      decoration: ArtWalkDesignSystem.glassDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(ArtWalkDesignSystem.radiusXL),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: ArtWalkDesignSystem.cardBackground,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child:
                          ImageUrlValidator.isValidImageUrl(
                            widget.capture.imageUrl,
                          )
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: RepaintBoundary(
                                child: OptimizedImage(
                                  imageUrl:
                                      widget.capture.thumbnailUrl ??
                                      widget.capture.imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  isThumbnail: true,
                                  placeholder: Container(
                                    color: ArtWalkDesignSystem.cardBackground,
                                    child: const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                ArtWalkDesignSystem.primaryTeal,
                                              ),
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  errorWidget: Container(
                                    color: ArtWalkDesignSystem.cardBackground,
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                      color: ArtWalkDesignSystem.textSecondary,
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              decoration: const BoxDecoration(
                                color: ArtWalkDesignSystem.cardBackground,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                              ),
                              child: const Icon(
                                Icons.image_outlined,
                                color: ArtWalkDesignSystem.textSecondary,
                                size: 40,
                              ),
                            ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.capture.title ?? 'Untitled',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: ArtWalkDesignSystem.textPrimary,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.capture.artistName != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'by ${widget.capture.artistName}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: ArtWalkDesignSystem.textSecondary,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Flexible(
                            child: Row(
                              children: [
                                Icon(
                                  widget.capture.isPublic
                                      ? Icons.public
                                      : Icons.lock,
                                  size: 14,
                                  color: widget.capture.isPublic
                                      ? ArtWalkDesignSystem.primaryTeal
                                      : ArtWalkDesignSystem.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.capture.isPublic
                                      ? 'Public'
                                      : 'Private',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: widget.capture.isPublic
                                            ? ArtWalkDesignSystem.primaryTeal
                                            : ArtWalkDesignSystem.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                                if (!widget.capture.isProcessed) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.hourglass_empty,
                                    size: 14,
                                    color: ArtWalkDesignSystem.accentOrange,
                                  ),
                                  const SizedBox(width: 2),
                                  Flexible(
                                    child: Text(
                                      'Processing',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: ArtWalkDesignSystem
                                                .accentOrange,
                                            fontWeight: FontWeight.w500,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Action buttons overlay
              if (widget.onEdit != null || widget.onDelete != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: ArtWalkDesignSystem.cardBackground.withValues(
                        alpha: 0.8,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.onEdit != null)
                          IconButton(
                            onPressed: widget.onEdit,
                            icon: const Icon(
                              Icons.edit,
                              color: ArtWalkDesignSystem.primaryTeal,
                              size: 18,
                            ),
                            tooltip: 'Edit Capture',
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                        if (widget.onDelete != null)
                          IconButton(
                            onPressed: widget.onDelete,
                            icon: const Icon(
                              Icons.delete,
                              color: ArtWalkDesignSystem.accentOrange,
                              size: 18,
                            ),
                            tooltip: 'Delete Capture',
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog for editing capture details
class EditCaptureDialog extends StatefulWidget {
  final CaptureModel capture;

  const EditCaptureDialog({super.key, required this.capture});

  @override
  State<EditCaptureDialog> createState() => _EditCaptureDialogState();
}

class _EditCaptureDialogState extends State<EditCaptureDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late bool _isPublic;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.capture.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.capture.description ?? '',
    );
    _isPublic = widget.capture.isPublic;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ArtWalkDesignSystem.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ArtWalkDesignSystem.radiusL),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(ArtWalkDesignSystem.paddingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit Capture', style: ArtWalkDesignSystem.cardTitleStyle),
            const SizedBox(height: ArtWalkDesignSystem.paddingL),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: const TextStyle(
                  color: ArtWalkDesignSystem.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ArtWalkDesignSystem.radiusM,
                  ),
                  borderSide: const BorderSide(
                    color: ArtWalkDesignSystem.primaryTeal,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ArtWalkDesignSystem.radiusM,
                  ),
                  borderSide: BorderSide(
                    color: ArtWalkDesignSystem.primaryTeal.withValues(
                      alpha: 0.3,
                    ),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ArtWalkDesignSystem.radiusM,
                  ),
                  borderSide: const BorderSide(
                    color: ArtWalkDesignSystem.primaryTeal,
                  ),
                ),
                filled: true,
                fillColor: ArtWalkDesignSystem.cardBackground,
              ),
              style: const TextStyle(color: ArtWalkDesignSystem.textPrimary),
            ),
            const SizedBox(height: ArtWalkDesignSystem.paddingM),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: const TextStyle(
                  color: ArtWalkDesignSystem.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ArtWalkDesignSystem.radiusM,
                  ),
                  borderSide: const BorderSide(
                    color: ArtWalkDesignSystem.primaryTeal,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ArtWalkDesignSystem.radiusM,
                  ),
                  borderSide: BorderSide(
                    color: ArtWalkDesignSystem.primaryTeal.withValues(
                      alpha: 0.3,
                    ),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ArtWalkDesignSystem.radiusM,
                  ),
                  borderSide: const BorderSide(
                    color: ArtWalkDesignSystem.primaryTeal,
                  ),
                ),
                filled: true,
                fillColor: ArtWalkDesignSystem.cardBackground,
              ),
              style: const TextStyle(color: ArtWalkDesignSystem.textPrimary),
              maxLines: 3,
            ),
            const SizedBox(height: ArtWalkDesignSystem.paddingM),
            Row(
              children: [
                Checkbox(
                  value: _isPublic,
                  onChanged: (value) {
                    setState(() {
                      _isPublic = value ?? false;
                    });
                  },
                  activeColor: ArtWalkDesignSystem.primaryTeal,
                ),
                const SizedBox(width: ArtWalkDesignSystem.paddingS),
                const Text(
                  'Make this capture public',
                  style: TextStyle(
                    color: ArtWalkDesignSystem.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isPublic ? Icons.public : Icons.lock,
                  size: 16,
                  color: _isPublic
                      ? ArtWalkDesignSystem.primaryTeal
                      : ArtWalkDesignSystem.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: ArtWalkDesignSystem.paddingL),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: ArtWalkDesignSystem.textSecondary),
                  ),
                ),
                const SizedBox(width: ArtWalkDesignSystem.paddingM),
                ElevatedButton(
                  onPressed: () {
                    final updates = {
                      'title': _titleController.text.trim(),
                      'description': _descriptionController.text.trim(),
                      'isPublic': _isPublic,
                    };
                    Navigator.of(context).pop(updates);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ArtWalkDesignSystem.primaryTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        ArtWalkDesignSystem.radiusM,
                      ),
                    ),
                  ),
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
