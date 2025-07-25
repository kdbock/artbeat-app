import 'package:flutter/material.dart';
import '../models/content_review_model.dart';
import '../services/content_review_service.dart';
import '../widgets/admin_header.dart';
import '../widgets/admin_drawer.dart';

/// Admin Content Review Screen
///
/// Allows administrators to review and moderate user-generated content
/// including artworks, posts, comments, and user profiles.
class AdminContentReviewScreen extends StatefulWidget {
  const AdminContentReviewScreen({super.key});

  @override
  State<AdminContentReviewScreen> createState() =>
      _AdminContentReviewScreenState();
}

class _AdminContentReviewScreenState extends State<AdminContentReviewScreen> {
  final ContentReviewService _contentReviewService = ContentReviewService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  List<ContentReviewModel> _pendingReviews = [];
  bool _isLoading = true;
  String? _error;
  ContentType _selectedFilter = ContentType.all;

  @override
  void initState() {
    super.initState();
    _loadPendingReviews();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingReviews() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final reviews = await _contentReviewService.getPendingReviews(
        contentType:
            _selectedFilter == ContentType.all ? null : _selectedFilter,
      );

      if (mounted) {
        setState(() {
          _pendingReviews = reviews;
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

  Future<void> _approveContent(
      String contentId, ContentType contentType) async {
    try {
      await _contentReviewService.approveContent(contentId, contentType);
      await _loadPendingReviews();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Content approved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve content: $e')),
        );
      }
    }
  }

  Future<void> _rejectContent(
      String contentId, ContentType contentType, String reason) async {
    try {
      await _contentReviewService.rejectContent(contentId, contentType, reason);
      await _loadPendingReviews();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Content rejected successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject content: $e')),
        );
      }
    }
  }

  void _showRejectDialog(String contentId, ContentType contentType) {
    final TextEditingController reasonController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Content'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter rejection reason...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isNotEmpty) {
                Navigator.of(context).pop();
                _rejectContent(contentId, contentType, reason);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: const AdminDrawer(),
      appBar: AdminHeader(
        title: 'Content Review',
        showBackButton: true,
        showSearch: true,
        showChat: true,
        showDeveloper: true,
        onBackPressed: () => Navigator.pop(context),
        onMenuPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
        onSearchPressed: () => Navigator.pushNamed(context, '/search'),
        onChatPressed: () => Navigator.pushNamed(context, '/messaging'),
      ),
      body: Container(
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
          child: Column(
            children: [
              _buildFilterBar(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? _buildErrorWidget()
                        : _buildContentList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text('Filter: '),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<ContentType>(
              value: _selectedFilter,
              isExpanded: true,
              items: ContentType.values
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedFilter = value;
                  });
                  _loadPendingReviews();
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: _loadPendingReviews,
            icon: const Icon(Icons.refresh),
          ),
        ],
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
            'Error loading content',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadPendingReviews,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContentList() {
    if (_pendingReviews.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green,
            ),
            SizedBox(height: 16),
            Text(
              'No pending reviews',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              'All content has been reviewed',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _pendingReviews.length,
      itemBuilder: (context, index) {
        final review = _pendingReviews[index];
        return _buildContentCard(review);
      },
    );
  }

  Widget _buildContentCard(ContentReviewModel review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildContentTypeChip(review.contentType),
                const Spacer(),
                Text(
                  _formatDate(review.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              review.title,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              review.description,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 4),
                Text(
                  'By ${review.authorName}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _showRejectDialog(
                    review.contentId,
                    review.contentType,
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _approveContent(
                    review.contentId,
                    review.contentType,
                  ),
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

  Widget _buildContentTypeChip(ContentType type) {
    Color color;
    switch (type) {
      case ContentType.artwork:
        color = Colors.blue;
        break;
      case ContentType.post:
        color = Colors.green;
        break;
      case ContentType.comment:
        color = Colors.orange;
        break;
      case ContentType.profile:
        color = Colors.purple;
        break;
      case ContentType.event:
        color = Colors.red;
        break;
      case ContentType.all:
        color = Colors.grey;
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
        type.displayName,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
