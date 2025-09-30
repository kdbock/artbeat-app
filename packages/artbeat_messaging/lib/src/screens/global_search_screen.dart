import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../models/search_result_model.dart';
import '../models/message_model.dart';
import 'chat_screen.dart';

/// Enhanced global search screen with advanced filtering and media search
///
/// **DEPRECATED**: This screen is being replaced by the new unified search flow.
/// Use core.SearchResultsPage instead.
@Deprecated('Use core.SearchResultsPage instead for unified search experience')
class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ChatService _chatService = ChatService();
  late TabController _tabController;

  List<SearchResultModel> _searchResults = [];
  List<MessageModel> _mediaResults = [];
  bool _isSearching = false;
  String _currentQuery = '';

  // Advanced search filters
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedSenderId;
  MessageType? _selectedMessageType;
  bool _starredOnly = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    if (_searchController.text.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _currentQuery = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _currentQuery = _searchController.text.trim();
    });

    try {
      final results = await _chatService.advancedSearch(
        query: _currentQuery,
        startDate: _startDate,
        endDate: _endDate,
        senderId: _selectedSenderId,
        messageType: _selectedMessageType,
        starredOnly: _starredOnly,
        limit: 100,
      );

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Search error: $e')));
      }
    }
  }

  Future<void> _searchMedia(MessageType mediaType) async {
    setState(() => _isSearching = true);

    try {
      final results = await _chatService.searchMedia(mediaType);
      setState(() {
        _mediaResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Media search error: $e')));
      }
    }
  }

  void _showAdvancedFilters() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AdvancedFiltersSheet(
        startDate: _startDate,
        endDate: _endDate,
        selectedSenderId: _selectedSenderId,
        selectedMessageType: _selectedMessageType,
        starredOnly: _starredOnly,
        onFiltersChanged: (filters) {
          setState(() {
            _startDate = filters['startDate'] as DateTime?;
            _endDate = filters['endDate'] as DateTime?;
            _selectedSenderId = filters['senderId'] as String?;
            _selectedMessageType = filters['messageType'] as MessageType?;
            _starredOnly = (filters['starredOnly'] as bool?) ?? false;
          });
          _performSearch();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Search'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Messages', icon: Icon(Icons.message)),
            Tab(text: 'Media', icon: Icon(Icons.photo)),
            Tab(text: 'Files', icon: Icon(Icons.attach_file)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search messages...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchResults = [];
                                  _currentQuery = '';
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.tune,
                    color: _hasActiveFilters()
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                  ),
                  onPressed: _showAdvancedFilters,
                  tooltip: 'Advanced Filters',
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMessageSearchResults(),
                _buildMediaSearchResults(MessageType.image),
                _buildMediaSearchResults(MessageType.file),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Search across all your conversations',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter keywords to find messages',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No messages found',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            Text(
              'Try different keywords or adjust filters',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return _SearchResultTile(
          result: result,
          query: _currentQuery,
          onTap: () => _navigateToMessage(result),
        );
      },
    );
  }

  Widget _buildMediaSearchResults(MessageType mediaType) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            icon: Icon(
              mediaType == MessageType.image ? Icons.photo : Icons.attach_file,
            ),
            label: Text(
              'Search ${mediaType == MessageType.image ? 'Images' : 'Files'}',
            ),
            onPressed: () => _searchMedia(mediaType),
          ),
        ),
        Expanded(
          child: _isSearching
              ? const Center(child: CircularProgressIndicator())
              : _mediaResults.isEmpty
              ? Center(
                  child: Text(
                    'No ${mediaType == MessageType.image ? 'images' : 'files'} found',
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _mediaResults.length,
                  itemBuilder: (context, index) {
                    final message = _mediaResults[index];
                    return _MediaResultTile(
                      message: message,
                      onTap: () => _navigateToMediaMessage(message),
                    );
                  },
                ),
        ),
      ],
    );
  }

  bool _hasActiveFilters() {
    return _startDate != null ||
        _endDate != null ||
        _selectedSenderId != null ||
        _selectedMessageType != null ||
        _starredOnly;
  }

  void _navigateToMessage(SearchResultModel result) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ChatScreen(
          chat: result.chat,
          // highlightMessageId: result.message.id, // TODO: Implement message highlighting
        ),
      ),
    );
  }

  void _navigateToMediaMessage(MessageModel message) {
    // Navigate to the chat containing this media message
    // Implementation would depend on how you store chat ID in messages
    // For now, we'll show a placeholder
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Navigate to media message')));
  }
}

class _SearchResultTile extends StatelessWidget {
  final SearchResultModel result;
  final String query;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.result,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: result.chat.groupImage != null
            ? NetworkImage(result.chat.groupImage!)
            : null,
        child: result.chat.groupImage == null
            ? Text(
                result.chat.isGroup
                    ? result.chat.groupName?.substring(0, 1) ?? 'G'
                    : 'U',
              )
            : null,
      ),
      title: Text(
        result.chat.isGroup
            ? result.chat.groupName ?? 'Group Chat'
            : 'Direct Message',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _highlightSearchTerm(result.message.content, query),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            _formatTimestamp(result.message.timestamp),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
      trailing: result.message.isStarred
          ? const Icon(Icons.star, color: Colors.amber, size: 20)
          : null,
      onTap: onTap,
    );
  }

  String _highlightSearchTerm(String text, String query) {
    // In a real implementation, you'd use HTML rendering or rich text
    // For now, just return the original text
    return text;
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

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

class _MediaResultTile extends StatelessWidget {
  final MessageModel message;
  final VoidCallback onTap;

  const _MediaResultTile({required this.message, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[200],
        ),
        child: message.type == MessageType.image
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  (message.metadata?['imageUrl'] as String?) ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image),
                ),
              )
            : const Center(child: Icon(Icons.attach_file, size: 48)),
      ),
    );
  }
}

class _AdvancedFiltersSheet extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? selectedSenderId;
  final MessageType? selectedMessageType;
  final bool starredOnly;
  final void Function(Map<String, dynamic>) onFiltersChanged;

  const _AdvancedFiltersSheet({
    this.startDate,
    this.endDate,
    this.selectedSenderId,
    this.selectedMessageType,
    required this.starredOnly,
    required this.onFiltersChanged,
  });

  @override
  State<_AdvancedFiltersSheet> createState() => _AdvancedFiltersSheetState();
}

class _AdvancedFiltersSheetState extends State<_AdvancedFiltersSheet> {
  late DateTime? _startDate;
  late DateTime? _endDate;
  late String? _selectedSenderId;
  late MessageType? _selectedMessageType;
  late bool _starredOnly;

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
    _endDate = widget.endDate;
    _selectedSenderId = widget.selectedSenderId;
    _selectedMessageType = widget.selectedMessageType;
    _starredOnly = widget.starredOnly;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Advanced Search Filters',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),

          // Date Range
          Text('Date Range', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => _selectDate(context, isStartDate: true),
                  child: Text(
                    _startDate != null
                        ? 'From: ${_formatDate(_startDate!)}'
                        : 'Select start date',
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () => _selectDate(context, isStartDate: false),
                  child: Text(
                    _endDate != null
                        ? 'To: ${_formatDate(_endDate!)}'
                        : 'Select end date',
                  ),
                ),
              ),
            ],
          ),

          // Message Type
          const SizedBox(height: 16),
          Text('Message Type', style: Theme.of(context).textTheme.titleMedium),
          DropdownButton<MessageType?>(
            isExpanded: true,
            value: _selectedMessageType,
            onChanged: (value) => setState(() => _selectedMessageType = value),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Types')),
              ...MessageType.values.map(
                (type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.name.toUpperCase()),
                ),
              ),
            ],
          ),

          // Starred Only
          CheckboxListTile(
            title: const Text('Starred messages only'),
            value: _starredOnly,
            onChanged: (value) => setState(() => _starredOnly = value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
          ),

          // Action Buttons
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                    _selectedSenderId = null;
                    _selectedMessageType = null;
                    _starredOnly = false;
                  });
                },
                child: const Text('Clear All'),
              ),
              ElevatedButton(
                onPressed: () {
                  widget.onFiltersChanged({
                    'startDate': _startDate,
                    'endDate': _endDate,
                    'senderId': _selectedSenderId,
                    'messageType': _selectedMessageType,
                    'starredOnly': _starredOnly,
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('Apply Filters'),
              ),
            ],
          ),

          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Future<void> _selectDate(
    BuildContext context, {
    required bool isStartDate,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
