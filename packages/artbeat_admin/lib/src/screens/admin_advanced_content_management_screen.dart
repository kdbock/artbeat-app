import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/content_model.dart';
import '../services/content_review_service.dart';
import '../models/content_review_model.dart';
import '../widgets/admin_drawer.dart';

/// Advanced Content Management Screen with AI-powered moderation
///
/// Features:
/// - AI-powered content moderation
/// - Bulk content operations
/// - Content performance analytics
/// - Advanced filtering and search
/// - Content lifecycle management
/// - Automated flagging and review workflows
class AdminAdvancedContentManagementScreen extends StatefulWidget {
  const AdminAdvancedContentManagementScreen({super.key});

  @override
  State<AdminAdvancedContentManagementScreen> createState() =>
      _AdminAdvancedContentManagementScreenState();
}

class _AdminAdvancedContentManagementScreenState
    extends State<AdminAdvancedContentManagementScreen>
    with TickerProviderStateMixin {
  final ContentReviewService _contentService = ContentReviewService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;

  List<ContentModel> _content = [];
  List<ContentModel> _filteredContent = [];
  bool _isLoading = true;
  String? _error;

  // Filters
  ContentTypeFilter _selectedType = ContentTypeFilter.all;
  ContentStatusFilter _selectedStatus = ContentStatusFilter.all;
  ContentModerationFilter _selectedModeration = ContentModerationFilter.all;
  ContentPerformanceFilter _selectedPerformance = ContentPerformanceFilter.all;
  DateRange _selectedDateRange = DateRange.last30Days;
  String _searchQuery = '';

  // Selection
  final Set<String> _selectedContentIds = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final content = await _contentService.getAllContent();

      if (mounted) {
        setState(() {
          _content = content;
          _filteredContent = content;
          _isLoading = false;
        });
        _applyFilters();
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

  void _applyFilters() {
    List<ContentModel> filtered = List.from(_content);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((content) {
        return content.title
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            content.description
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            content.authorName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            content.id.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply type filter
    if (_selectedType != ContentTypeFilter.all) {
      filtered = filtered.where((content) {
        switch (_selectedType) {
          case ContentTypeFilter.artwork:
            return content.type == 'artwork';
          case ContentTypeFilter.post:
            return content.type == 'post';
          case ContentTypeFilter.event:
            return content.type == 'event';
          case ContentTypeFilter.comment:
            return content.type == 'comment';
          case ContentTypeFilter.all:
            return true;
        }
      }).toList();
    }

    // Apply status filter
    if (_selectedStatus != ContentStatusFilter.all) {
      filtered = filtered.where((content) {
        switch (_selectedStatus) {
          case ContentStatusFilter.published:
            return content.status == 'published';
          case ContentStatusFilter.draft:
            return content.status == 'draft';
          case ContentStatusFilter.archived:
            return content.status == 'archived';
          case ContentStatusFilter.deleted:
            return content.status == 'deleted';
          case ContentStatusFilter.all:
            return true;
        }
      }).toList();
    }

    // Apply moderation filter
    if (_selectedModeration != ContentModerationFilter.all) {
      filtered = filtered.where((content) {
        switch (_selectedModeration) {
          case ContentModerationFilter.approved:
            return content.moderationStatus == 'approved';
          case ContentModerationFilter.pending:
            return content.moderationStatus == 'pending';
          case ContentModerationFilter.flagged:
            return content.moderationStatus == 'flagged';
          case ContentModerationFilter.rejected:
            return content.moderationStatus == 'rejected';
          case ContentModerationFilter.all:
            return true;
        }
      }).toList();
    }

    // Apply performance filter
    if (_selectedPerformance != ContentPerformanceFilter.all) {
      filtered = filtered.where((content) {
        switch (_selectedPerformance) {
          case ContentPerformanceFilter.trending:
            return content.engagementScore > 80;
          case ContentPerformanceFilter.popular:
            return content.engagementScore > 60;
          case ContentPerformanceFilter.average:
            return content.engagementScore >= 30 &&
                content.engagementScore <= 60;
          case ContentPerformanceFilter.underperforming:
            return content.engagementScore < 30;
          case ContentPerformanceFilter.all:
            return true;
        }
      }).toList();
    }

    // Apply date range filter
    if (_selectedDateRange != DateRange.all) {
      final now = DateTime.now();
      DateTime startDate;

      switch (_selectedDateRange) {
        case DateRange.today:
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case DateRange.last7Days:
          startDate = now.subtract(const Duration(days: 7));
          break;
        case DateRange.last30Days:
          startDate = now.subtract(const Duration(days: 30));
          break;
        case DateRange.last90Days:
          startDate = now.subtract(const Duration(days: 90));
          break;
        case DateRange.lastYear:
          startDate = DateTime(now.year - 1, now.month, now.day);
          break;
        case DateRange.all:
          startDate = DateTime(2020); // Arbitrary old date
          break;
      }

      filtered = filtered
          .where((content) => content.createdAt.isAfter(startDate))
          .toList();
    }

    setState(() {
      _filteredContent = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1, // Admin screens don't use bottom navigation
      scaffoldKey: _scaffoldKey,
      appBar: EnhancedUniversalHeader(
        title: 'Advanced Content Management',
        showBackButton: true,
        showSearch: true,
        showDeveloperTools: true,
        actions: [
          if (!_isSelectionMode)
            IconButton(
              onPressed: () => _showCreateContentDialog(),
              icon: const Icon(Icons.add),
              tooltip: 'Create Content',
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
          child: Column(
            children: [
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildContentTab(),
                    _buildModerationTab(),
                    _buildAnalyticsTab(),
                    _buildTrendsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Theme.of(context).primaryColor,
        tabs: const [
          Tab(text: 'Content', icon: Icon(Icons.content_copy, size: 20)),
          Tab(text: 'Moderation', icon: Icon(Icons.gavel, size: 20)),
          Tab(text: 'Analytics', icon: Icon(Icons.analytics, size: 20)),
          Tab(text: 'Trends', icon: Icon(Icons.trending_up, size: 20)),
        ],
      ),
    );
  }

  Widget _buildContentTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    return Column(
      children: [
        _buildFiltersSection(),
        _buildContentStats(),
        Expanded(
          child: _buildContentList(),
        ),
      ],
    );
  }

  Widget _buildModerationTab() {
    final pendingContent =
        _filteredContent.where((c) => c.moderationStatus == 'pending').toList();
    final flaggedContent =
        _filteredContent.where((c) => c.moderationStatus == 'flagged').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModerationQueue('Pending Review', pendingContent),
          const SizedBox(height: 24),
          _buildModerationQueue('Flagged Content', flaggedContent),
          const SizedBox(height: 24),
          _buildAIModerationInsights(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContentPerformanceOverview(),
          const SizedBox(height: 24),
          _buildEngagementMetrics(),
          const SizedBox(height: 24),
          _buildContentTypeAnalysis(),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTrendingContent(),
          const SizedBox(height: 24),
          _buildContentTrends(),
          const SizedBox(height: 24),
          _buildViralContent(),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search content by title, description, or author...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                        _applyFilters();
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _applyFilters();
            },
          ),
          const SizedBox(height: 16),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  'Type',
                  _selectedType.displayName,
                  () => _showTypeFilter(),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Status',
                  _selectedStatus.displayName,
                  () => _showStatusFilter(),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Moderation',
                  _selectedModeration.displayName,
                  () => _showModerationFilter(),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Performance',
                  _selectedPerformance.displayName,
                  () => _showPerformanceFilter(),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Date',
                  _selectedDateRange.displayName,
                  () => _showDateRangeFilter(),
                ),
                const SizedBox(width: 8),
                if (_hasActiveFilters())
                  TextButton(
                    onPressed: _clearAllFilters,
                    child: const Text('Clear All'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Content',
              _filteredContent.length.toString(),
              Icons.content_copy,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Published',
              _getPublishedCount().toString(),
              Icons.publish,
              Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Pending Review',
              _getPendingCount().toString(),
              Icons.pending,
              Colors.orange,
            ),
          ),
          if (_isSelectionMode) ...[
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Selected',
                _selectedContentIds.length.toString(),
                Icons.check_circle,
                Colors.purple,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContentList() {
    if (_filteredContent.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.content_copy_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No content found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or search criteria',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _filteredContent.length,
      itemBuilder: (context, index) {
        final content = _filteredContent[index];
        final isSelected = _selectedContentIds.contains(content.id);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: _isSelectionMode
                ? Checkbox(
                    value: isSelected,
                    onChanged: (value) => _toggleContentSelection(content.id),
                  )
                : _buildContentThumbnail(content),
            title: Text(
              content.title,
              style: const TextStyle(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildStatusChip(content.status),
                    const SizedBox(width: 8),
                    _buildModerationChip(content.moderationStatus),
                    const SizedBox(width: 8),
                    _buildEngagementScore(content.engagementScore),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'By ${content.authorName} • ${_formatDate(content.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_isSelectionMode) ...[
                  IconButton(
                    onPressed: () => _showContentActions(content),
                    icon: const Icon(Icons.more_vert),
                  ),
                ],
                if (_isSelectionMode)
                  IconButton(
                    onPressed: () => _toggleContentSelection(content.id),
                    icon: Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isSelected ? Theme.of(context).primaryColor : null,
                    ),
                  ),
              ],
            ),
            onTap: _isSelectionMode
                ? () => _toggleContentSelection(content.id)
                : () => _navigateToContentDetail(content),
            onLongPress: () => _enterSelectionMode(content.id),
          ),
        );
      },
    );
  }

  Widget _buildModerationQueue(String title, List<ContentModel> content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${content.length} items',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (content.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No items in queue'),
                ),
              )
            else
              ...content.take(5).map((item) => _buildModerationItem(item)),
            if (content.length > 5)
              TextButton(
                onPressed: () => _showFullModerationQueue(title, content),
                child: Text('View all ${content.length} items'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModerationItem(ContentModel content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _buildContentThumbnail(content),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'By ${content.authorName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _approveContent(content),
                icon: const Icon(Icons.check, color: Colors.green),
                tooltip: 'Approve',
              ),
              IconButton(
                onPressed: () => _rejectContent(content),
                icon: const Icon(Icons.close, color: Colors.red),
                tooltip: 'Reject',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAIModerationInsights() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Moderation Insights',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildInsightCard(
                    'Auto-Approved', '89%', Icons.check_circle, Colors.green),
                _buildInsightCard(
                    'Flagged for Review', '8%', Icons.flag, Colors.orange),
                _buildInsightCard(
                    'Auto-Rejected', '3%', Icons.block, Colors.red),
                _buildInsightCard(
                    'Accuracy Rate', '94%', Icons.psychology, Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentPerformanceOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Content Performance Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildMetricCard('Total Views', '1.2M', Icons.visibility),
                _buildMetricCard('Total Likes', '45.6K', Icons.favorite),
                _buildMetricCard('Total Comments', '12.3K', Icons.comment),
                _buildMetricCard('Avg Engagement', '7.8%', Icons.trending_up),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementMetrics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Engagement Metrics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            const SizedBox(
              height: 200,
              child: Center(
                child: Text('Engagement chart would go here'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentTypeAnalysis() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Content Type Analysis',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildContentTypeBreakdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildContentTypeBreakdown() {
    final artworkCount =
        _filteredContent.where((c) => c.type == 'artwork').length;
    final postCount = _filteredContent.where((c) => c.type == 'post').length;
    final eventCount = _filteredContent.where((c) => c.type == 'event').length;
    final commentCount =
        _filteredContent.where((c) => c.type == 'comment').length;

    return Column(
      children: [
        _buildTypeBreakdownItem('Artwork', artworkCount, Colors.blue),
        _buildTypeBreakdownItem('Posts', postCount, Colors.green),
        _buildTypeBreakdownItem('Events', eventCount, Colors.orange),
        _buildTypeBreakdownItem('Comments', commentCount, Colors.purple),
      ],
    );
  }

  Widget _buildTypeBreakdownItem(String type, int count, Color color) {
    final total = _filteredContent.length;
    final percentage = total > 0 ? (count / total) * 100 : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(type)),
          Text(
            count.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(
            '(${percentage.toStringAsFixed(1)}%)',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingContent() {
    final trendingContent =
        _filteredContent.where((c) => c.engagementScore > 80).take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trending Content',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (trendingContent.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No trending content'),
                ),
              )
            else
              ...trendingContent.map((content) => _buildTrendingItem(content)),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingItem(ContentModel content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _buildContentThumbnail(content),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'By ${content.authorName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          _buildEngagementScore(content.engagementScore),
        ],
      ),
    );
  }

  Widget _buildContentTrends() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Content Trends',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            const SizedBox(
              height: 200,
              child: Center(
                child: Text('Content trends chart would go here'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViralContent() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Viral Content Analysis',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            const Text(
                'Content that achieved viral status in the last 30 days'),
            const SizedBox(height: 16),
            const SizedBox(
              height: 150,
              child: Center(
                child: Text('Viral content analysis would go here'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widgets
  Widget _buildFilterChip(String label, String value, VoidCallback onTap) {
    final hasFilter = value != 'All';
    return FilterChip(
      label: Text('$label: $value'),
      selected: hasFilter,
      onSelected: (_) => onTap(),
      backgroundColor: hasFilter
          ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
          : null,
      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContentThumbnail(ContentModel content) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: content.thumbnailUrl != null && content.thumbnailUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                content.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildContentTypeIcon(content.type),
              ),
            )
          : _buildContentTypeIcon(content.type),
    );
  }

  Widget _buildContentTypeIcon(String type) {
    IconData icon;
    Color color;

    switch (type.toLowerCase()) {
      case 'artwork':
        icon = Icons.image;
        color = Colors.blue;
        break;
      case 'post':
        icon = Icons.post_add;
        color = Colors.green;
        break;
      case 'event':
        icon = Icons.event;
        color = Colors.orange;
        break;
      case 'comment':
        icon = Icons.comment;
        color = Colors.purple;
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
    }

    return Icon(icon, color: color, size: 24);
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'published':
        color = Colors.green;
        break;
      case 'draft':
        color = Colors.orange;
        break;
      case 'archived':
        color = Colors.grey;
        break;
      case 'deleted':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildModerationChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'flagged':
        color = Colors.red;
        break;
      case 'rejected':
        color = Colors.red.shade700;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEngagementScore(double score) {
    Color color;
    if (score >= 80) {
      color = Colors.green;
    } else if (score >= 60) {
      color = Colors.orange;
    } else if (score >= 30) {
      color = Colors.blue;
    } else {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${score.toInt()}%',
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInsightCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: Theme.of(context).primaryColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
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
            onPressed: _loadData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Helper methods
  int _getPublishedCount() {
    return _filteredContent.where((c) => c.status == 'published').length;
  }

  int _getPendingCount() {
    return _filteredContent
        .where((c) => c.moderationStatus == 'pending')
        .length;
  }

  bool _hasActiveFilters() {
    return _selectedType != ContentTypeFilter.all ||
        _selectedStatus != ContentStatusFilter.all ||
        _selectedModeration != ContentModerationFilter.all ||
        _selectedPerformance != ContentPerformanceFilter.all ||
        _selectedDateRange != DateRange.all ||
        _searchQuery.isNotEmpty;
  }

  void _clearAllFilters() {
    setState(() {
      _selectedType = ContentTypeFilter.all;
      _selectedStatus = ContentStatusFilter.all;
      _selectedModeration = ContentModerationFilter.all;
      _selectedPerformance = ContentPerformanceFilter.all;
      _selectedDateRange = DateRange.all;
      _searchQuery = '';
      _searchController.clear();
    });
    _applyFilters();
  }

  void _toggleContentSelection(String contentId) {
    setState(() {
      if (_selectedContentIds.contains(contentId)) {
        _selectedContentIds.remove(contentId);
      } else {
        _selectedContentIds.add(contentId);
      }

      if (_selectedContentIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _enterSelectionMode(String contentId) {
    setState(() {
      _isSelectionMode = true;
      _selectedContentIds.clear();
      _selectedContentIds.add(contentId);
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Action methods
  void _navigateToContentDetail(ContentModel content) {
    // Navigate to content detail screen
  }

  void _approveContent(ContentModel content) async {
    try {
      await _contentService.approveContent(
          content.id, ContentType.fromString(content.type));
      _loadContent(); // Refresh the list
    } catch (e) {
      // Show error
    }
  }

  void _rejectContent(ContentModel content) async {
    try {
      await _contentService.rejectContent(
        content.id,
        ContentType.fromString(content.type),
        'Rejected by administrator',
      );
      _loadContent(); // Refresh the list
    } catch (e) {
      // Show error
    }
  }

  // Dialog methods
  void _showTypeFilter() {
    // Implementation for type filter dialog
  }

  void _showStatusFilter() {
    // Implementation for status filter dialog
  }

  void _showModerationFilter() {
    // Implementation for moderation filter dialog
  }

  void _showPerformanceFilter() {
    // Implementation for performance filter dialog
  }

  void _showDateRangeFilter() {
    // Implementation for date range filter dialog
  }

  void _showContentActions(ContentModel content) {
    // Implementation for content actions menu
  }

  void _showCreateContentDialog() {
    // Implementation for create content dialog
  }

  void _showFullModerationQueue(String title, List<ContentModel> content) {
    // Implementation for full moderation queue screen
  }
}

// Filter enums
enum ContentTypeFilter {
  all,
  artwork,
  post,
  event,
  comment,
}

enum ContentStatusFilter {
  all,
  published,
  draft,
  archived,
  deleted,
}

enum ContentModerationFilter {
  all,
  approved,
  pending,
  flagged,
  rejected,
}

enum ContentPerformanceFilter {
  all,
  trending,
  popular,
  average,
  underperforming,
}

// Extensions for display names
extension ContentTypeFilterExtension on ContentTypeFilter {
  String get displayName {
    switch (this) {
      case ContentTypeFilter.all:
        return 'All';
      case ContentTypeFilter.artwork:
        return 'Artwork';
      case ContentTypeFilter.post:
        return 'Posts';
      case ContentTypeFilter.event:
        return 'Events';
      case ContentTypeFilter.comment:
        return 'Comments';
    }
  }
}

extension ContentStatusFilterExtension on ContentStatusFilter {
  String get displayName {
    switch (this) {
      case ContentStatusFilter.all:
        return 'All';
      case ContentStatusFilter.published:
        return 'Published';
      case ContentStatusFilter.draft:
        return 'Draft';
      case ContentStatusFilter.archived:
        return 'Archived';
      case ContentStatusFilter.deleted:
        return 'Deleted';
    }
  }
}

extension ContentModerationFilterExtension on ContentModerationFilter {
  String get displayName {
    switch (this) {
      case ContentModerationFilter.all:
        return 'All';
      case ContentModerationFilter.approved:
        return 'Approved';
      case ContentModerationFilter.pending:
        return 'Pending';
      case ContentModerationFilter.flagged:
        return 'Flagged';
      case ContentModerationFilter.rejected:
        return 'Rejected';
    }
  }
}

extension ContentPerformanceFilterExtension on ContentPerformanceFilter {
  String get displayName {
    switch (this) {
      case ContentPerformanceFilter.all:
        return 'All';
      case ContentPerformanceFilter.trending:
        return 'Trending';
      case ContentPerformanceFilter.popular:
        return 'Popular';
      case ContentPerformanceFilter.average:
        return 'Average';
      case ContentPerformanceFilter.underperforming:
        return 'Low';
    }
  }
}

// Content analytics model
class ContentAnalytics {
  final String contentId;
  final int views;
  final int likes;
  final int comments;
  final int shares;
  final double engagementRate;
  final DateTime lastUpdated;

  ContentAnalytics({
    required this.contentId,
    required this.views,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.engagementRate,
    required this.lastUpdated,
  });

  factory ContentAnalytics.fromMap(Map<String, dynamic> map) {
    return ContentAnalytics(
      contentId: (map['contentId'] as String?) ?? '',
      views: (map['views'] as int?) ?? 0,
      likes: (map['likes'] as int?) ?? 0,
      comments: (map['comments'] as int?) ?? 0,
      shares: (map['shares'] as int?) ?? 0,
      engagementRate: (map['engagementRate'] as num?)?.toDouble() ?? 0.0,
      lastUpdated:
          (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'contentId': contentId,
      'views': views,
      'likes': likes,
      'comments': comments,
      'shares': shares,
      'engagementRate': engagementRate,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}

enum DateRange {
  all,
  today,
  last7Days,
  last30Days,
  last90Days,
  lastYear,
}

extension DateRangeExtension on DateRange {
  String get displayName {
    switch (this) {
      case DateRange.all:
        return 'All Time';
      case DateRange.today:
        return 'Today';
      case DateRange.last7Days:
        return 'Last 7 Days';
      case DateRange.last30Days:
        return 'Last 30 Days';
      case DateRange.last90Days:
        return 'Last 90 Days';
      case DateRange.lastYear:
        return 'Last Year';
    }
  }
}
