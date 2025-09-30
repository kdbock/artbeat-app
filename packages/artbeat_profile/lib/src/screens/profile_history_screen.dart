import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart';

class ProfileHistoryScreen extends StatefulWidget {
  const ProfileHistoryScreen({super.key});

  @override
  State<ProfileHistoryScreen> createState() => _ProfileHistoryScreenState();
}

class _ProfileHistoryScreenState extends State<ProfileHistoryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  List<Map<String, dynamic>> _viewHistory = [];
  List<Map<String, dynamic>> _interactionHistory = [];
  List<Map<String, dynamic>> _connectionHistory = [];
  List<Map<String, dynamic>> _searchHistory = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final user = Provider.of<UserService>(context, listen: false).currentUser;
      if (user != null) {
        final [
          viewData,
          interactionData,
          connectionData,
          searchData,
        ] = await Future.wait([
          _getViewHistory(user.uid),
          _getInteractionHistory(user.uid),
          _getConnectionHistory(user.uid),
          _getSearchHistory(user.uid),
        ]);

        setState(() {
          _viewHistory = viewData;
          _interactionHistory = interactionData;
          _connectionHistory = connectionData;
          _searchHistory = searchData;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading history: $e')));
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getViewHistory(String userId) async {
    // In a real implementation, fetch from Firestore user's view history
    return [
      {
        'id': '1',
        'type': 'profile_view',
        'targetId': 'user2',
        'targetName': 'Jane Artist',
        'targetAvatar': null,
        'timestamp': DateTime.now().subtract(const Duration(minutes: 15)),
        'metadata': {'duration': 45}, // seconds
      },
      {
        'id': '2',
        'type': 'artwork_view',
        'targetId': 'artwork123',
        'targetName': 'Digital Portrait',
        'targetImage': 'https://example.com/artwork.jpg',
        'artistName': 'Creative Studio',
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
        'metadata': {'duration': 120},
      },
      {
        'id': '3',
        'type': 'gallery_visit',
        'targetId': 'gallery456',
        'targetName': 'Modern Art Gallery',
        'targetImage': null,
        'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
        'metadata': {'artworks_viewed': 8},
      },
    ];
  }

  Future<List<Map<String, dynamic>>> _getInteractionHistory(
    String userId,
  ) async {
    // In a real implementation, fetch from Firestore user's interactions
    return [
      {
        'id': '1',
        'type': 'like',
        'targetId': 'post123',
        'targetType': 'artwork',
        'targetTitle': 'Sunset Painting',
        'artistName': 'Nature Artist',
        'artistId': 'user3',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 30)),
      },
      {
        'id': '2',
        'type': 'comment',
        'targetId': 'post456',
        'targetType': 'artwork',
        'targetTitle': 'Abstract Sculpture',
        'artistName': 'Modern Creator',
        'artistId': 'user4',
        'content': 'Absolutely stunning work!',
        'timestamp': DateTime.now().subtract(const Duration(hours: 1)),
      },
      {
        'id': '3',
        'type': 'share',
        'targetId': 'post789',
        'targetType': 'artwork',
        'targetTitle': 'Digital Illustration',
        'artistName': 'Digital Artist',
        'artistId': 'user5',
        'timestamp': DateTime.now().subtract(const Duration(hours: 3)),
      },
      {
        'id': '4',
        'type': 'save',
        'targetId': 'artwork999',
        'targetType': 'artwork',
        'targetTitle': 'Watercolor Landscape',
        'artistName': 'Traditional Artist',
        'artistId': 'user6',
        'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      },
    ];
  }

  Future<List<Map<String, dynamic>>> _getConnectionHistory(
    String userId,
  ) async {
    // In a real implementation, fetch from Firestore user's connection activity
    return [
      {
        'id': '1',
        'type': 'follow',
        'targetId': 'user7',
        'targetName': 'Emerging Artist',
        'targetAvatar': null,
        'timestamp': DateTime.now().subtract(const Duration(hours: 4)),
      },
      {
        'id': '2',
        'type': 'connection_request',
        'targetId': 'user8',
        'targetName': 'Gallery Owner',
        'targetAvatar': null,
        'status': 'pending',
        'timestamp': DateTime.now().subtract(const Duration(days: 2)),
      },
      {
        'id': '3',
        'type': 'connection_accepted',
        'targetId': 'user9',
        'targetName': 'Art Collector',
        'targetAvatar': null,
        'timestamp': DateTime.now().subtract(const Duration(days: 3)),
      },
    ];
  }

  Future<List<Map<String, dynamic>>> _getSearchHistory(String userId) async {
    // In a real implementation, fetch from Firestore user's search history
    return [
      {
        'id': '1',
        'query': 'abstract art',
        'type': 'artwork_search',
        'resultsCount': 24,
        'timestamp': DateTime.now().subtract(const Duration(minutes: 45)),
      },
      {
        'id': '2',
        'query': 'digital painting tutorials',
        'type': 'content_search',
        'resultsCount': 12,
        'timestamp': DateTime.now().subtract(const Duration(hours: 6)),
      },
      {
        'id': '3',
        'query': 'Jane Artist',
        'type': 'profile_search',
        'resultsCount': 3,
        'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      },
      {
        'id': '4',
        'query': 'oil painting',
        'type': 'artwork_search',
        'resultsCount': 45,
        'timestamp': DateTime.now().subtract(const Duration(days: 2)),
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity History'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Views', icon: Icon(Icons.visibility)),
            Tab(text: 'Interactions', icon: Icon(Icons.favorite)),
            Tab(text: 'Connections', icon: Icon(Icons.people)),
            Tab(text: 'Searches', icon: Icon(Icons.search)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, size: 20),
                    SizedBox(width: 8),
                    Text('Clear All History'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_search',
                child: Row(
                  children: [
                    Icon(Icons.search_off, size: 20),
                    SizedBox(width: 8),
                    Text('Clear Search History'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, size: 20),
                    SizedBox(width: 8),
                    Text('Export History'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadHistory),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildViewHistoryTab(),
                _buildInteractionHistoryTab(),
                _buildConnectionHistoryTab(),
                _buildSearchHistoryTab(),
              ],
            ),
    );
  }

  Widget _buildViewHistoryTab() {
    if (_viewHistory.isEmpty) {
      return _buildEmptyState(
        'No View History',
        'Your viewing activity will appear here.',
        Icons.visibility,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _viewHistory.length,
        itemBuilder: (context, index) {
          final item = _viewHistory[index];
          return _buildViewHistoryCard(item);
        },
      ),
    );
  }

  Widget _buildInteractionHistoryTab() {
    if (_interactionHistory.isEmpty) {
      return _buildEmptyState(
        'No Interaction History',
        'Your likes, comments, and shares will appear here.',
        Icons.favorite,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _interactionHistory.length,
        itemBuilder: (context, index) {
          final item = _interactionHistory[index];
          return _buildInteractionHistoryCard(item);
        },
      ),
    );
  }

  Widget _buildConnectionHistoryTab() {
    if (_connectionHistory.isEmpty) {
      return _buildEmptyState(
        'No Connection History',
        'Your follow and connection activity will appear here.',
        Icons.people,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _connectionHistory.length,
        itemBuilder: (context, index) {
          final item = _connectionHistory[index];
          return _buildConnectionHistoryCard(item);
        },
      ),
    );
  }

  Widget _buildSearchHistoryTab() {
    if (_searchHistory.isEmpty) {
      return _buildEmptyState(
        'No Search History',
        'Your search queries will appear here.',
        Icons.search,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _searchHistory.length,
        itemBuilder: (context, index) {
          final item = _searchHistory[index];
          return _buildSearchHistoryCard(item);
        },
      ),
    );
  }

  Widget _buildViewHistoryCard(Map<String, dynamic> item) {
    final timestamp = item['timestamp'] as DateTime;
    final type = item['type'] as String;

    IconData icon;
    Color iconColor;
    String subtitle = '';

    switch (type) {
      case 'profile_view':
        icon = Icons.person;
        iconColor = Colors.blue;
        subtitle =
            'Profile • ${_formatDuration((item['metadata']?['duration'] as int?) ?? 0)}';
        break;
      case 'artwork_view':
        icon = Icons.image;
        iconColor = Colors.purple;
        subtitle =
            'Artwork • ${_formatDuration((item['metadata']?['duration'] as int?) ?? 0)}';
        break;
      case 'gallery_visit':
        icon = Icons.museum;
        iconColor = Colors.orange;
        subtitle =
            'Gallery • ${item['metadata']?['artworks_viewed'] ?? 0} artworks';
        break;
      default:
        icon = Icons.visibility;
        iconColor = Colors.grey;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color.fromRGBO(
            (iconColor.r * 255).round(),
            (iconColor.g * 255).round(),
            (iconColor.b * 255).round(),
            0.1,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          item['targetName']?.toString() ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            const SizedBox(height: 2),
            Text(
              _formatTimestamp(timestamp),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: () =>
              _removeHistoryItem(_viewHistory, item['id']?.toString()),
        ),
        onTap: () => _handleViewHistoryTap(item),
      ),
    );
  }

  Widget _buildInteractionHistoryCard(Map<String, dynamic> item) {
    final timestamp = item['timestamp'] as DateTime;
    final type = item['type'] as String;

    IconData icon;
    Color iconColor;
    String actionText;

    switch (type) {
      case 'like':
        icon = Icons.favorite;
        iconColor = Colors.red;
        actionText = 'Liked';
        break;
      case 'comment':
        icon = Icons.comment;
        iconColor = Colors.blue;
        actionText = 'Commented on';
        break;
      case 'share':
        icon = Icons.share;
        iconColor = Colors.green;
        actionText = 'Shared';
        break;
      case 'save':
        icon = Icons.bookmark;
        iconColor = Colors.orange;
        actionText = 'Saved';
        break;
      default:
        icon = Icons.favorite_border;
        iconColor = Colors.grey;
        actionText = 'Interacted with';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color.fromRGBO(
            (iconColor.r * 255).round(),
            (iconColor.g * 255).round(),
            (iconColor.b * 255).round(),
            0.1,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium,
            children: [
              TextSpan(text: '$actionText '),
              TextSpan(
                text: item['targetTitle']?.toString() ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('by ${item['artistName'] ?? 'Unknown Artist'}'),
            if (item['content'] != null)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item['content'].toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(timestamp),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: () =>
              _removeHistoryItem(_interactionHistory, item['id']?.toString()),
        ),
        onTap: () => _handleInteractionHistoryTap(item),
      ),
    );
  }

  Widget _buildConnectionHistoryCard(Map<String, dynamic> item) {
    final timestamp = item['timestamp'] as DateTime;
    final type = item['type'] as String;

    IconData icon;
    Color iconColor;
    String actionText;
    Widget? statusWidget;

    switch (type) {
      case 'follow':
        icon = Icons.person_add;
        iconColor = Colors.blue;
        actionText = 'Followed';
        break;
      case 'connection_request':
        icon = Icons.connect_without_contact;
        iconColor = Colors.orange;
        actionText = 'Sent connection request to';
        if (item['status'] == 'pending') {
          statusWidget = Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 152, 0, 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Pending',
              style: TextStyle(
                color: Colors.orange[700],
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }
        break;
      case 'connection_accepted':
        icon = Icons.handshake;
        iconColor = Colors.green;
        actionText = 'Connected with';
        break;
      default:
        icon = Icons.people;
        iconColor = Colors.grey;
        actionText = 'Connected with';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color.fromRGBO(
            (iconColor.r * 255).round(),
            (iconColor.g * 255).round(),
            (iconColor.b * 255).round(),
            0.1,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium,
            children: [
              TextSpan(text: '$actionText '),
              TextSpan(
                text: item['targetName']?.toString() ?? 'Unknown User',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (statusWidget != null) ...[
              statusWidget,
              const SizedBox(height: 4),
            ],
            Text(
              _formatTimestamp(timestamp),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: () =>
              _removeHistoryItem(_connectionHistory, item['id']?.toString()),
        ),
        onTap: () => _handleConnectionHistoryTap(item),
      ),
    );
  }

  Widget _buildSearchHistoryCard(Map<String, dynamic> item) {
    final timestamp = item['timestamp'] as DateTime;
    final query = item['query'] as String;
    final type = item['type'] as String;
    final resultsCount = item['resultsCount'] as int;

    IconData icon;
    Color iconColor;

    switch (type) {
      case 'artwork_search':
        icon = Icons.image_search;
        iconColor = Colors.purple;
        break;
      case 'profile_search':
        icon = Icons.person_search;
        iconColor = Colors.blue;
        break;
      case 'content_search':
        icon = Icons.article;
        iconColor = Colors.green;
        break;
      default:
        icon = Icons.search;
        iconColor = Colors.grey;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: iconColor, size: 24),
        title: Text(query, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Row(
          children: [
            Text(
              '$resultsCount result${resultsCount == 1 ? '' : 's'}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const Text(' • '),
            Text(
              _formatTimestamp(timestamp),
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: () => _repeatSearch(query, type),
              tooltip: 'Search again',
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () =>
                  _removeHistoryItem(_searchHistory, item['id']?.toString()),
            ),
          ],
        ),
        onTap: () => _repeatSearch(query, type),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadHistory,
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      return remainingSeconds > 0
          ? '${minutes}m ${remainingSeconds}s'
          : '${minutes}m';
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'clear_all':
        _showClearAllDialog();
        break;
      case 'clear_search':
        _clearSearchHistory();
        break;
      case 'export':
        _exportHistory();
        break;
    }
  }

  void _showClearAllDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All History'),
        content: const Text(
          'This action cannot be undone. Are you sure you want to clear all your activity history?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllHistory();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _clearAllHistory() {
    setState(() {
      _viewHistory.clear();
      _interactionHistory.clear();
      _connectionHistory.clear();
      _searchHistory.clear();
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('All history cleared')));
  }

  void _clearSearchHistory() {
    setState(() {
      _searchHistory.clear();
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Search history cleared')));
  }

  void _exportHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export functionality coming soon')),
    );
  }

  void _removeHistoryItem(List<Map<String, dynamic>> list, String? itemId) {
    if (itemId != null) {
      setState(() {
        list.removeWhere((item) => item['id'] == itemId);
      });
    }
  }

  void _handleViewHistoryTap(Map<String, dynamic> item) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Opening ${item['targetName']}')));
  }

  void _handleInteractionHistoryTap(Map<String, dynamic> item) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Opening ${item['targetTitle']}')));
  }

  void _handleConnectionHistoryTap(Map<String, dynamic> item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening profile of ${item['targetName']}')),
    );
  }

  void _repeatSearch(String query, String type) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Searching for "$query"')));
  }
}
