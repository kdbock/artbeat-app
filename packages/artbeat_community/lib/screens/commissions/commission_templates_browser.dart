import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../../models/commission_template_model.dart';
import '../../services/commission_template_service.dart';
import '../../theme/community_colors.dart';
import 'package:artbeat_core/artbeat_core.dart' hide NumberFormat;

class CommissionTemplatesBrowser extends StatefulWidget {
  final String? artistId;
  final void Function(CommissionTemplate)? onTemplateSelected;

  const CommissionTemplatesBrowser({
    Key? key,
    this.artistId,
    this.onTemplateSelected,
  }) : super(key: key);

  @override
  State<CommissionTemplatesBrowser> createState() =>
      _CommissionTemplatesBrowserState();
}

class _CommissionTemplatesBrowserState extends State<CommissionTemplatesBrowser>
    with SingleTickerProviderStateMixin {
  late CommissionTemplateService _templateService;
  late TabController _tabController;
  List<CommissionTemplate> _templates = [];
  List<CommissionTemplate> _filteredTemplates = [];
  bool _isLoading = true;
  String _selectedCategory = '';
  String _searchQuery = '';

  final List<String> _categories = [
    'portrait',
    'landscape',
    'character',
    'digital',
    'commercial',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _templateService = CommissionTemplateService();
    _tabController = TabController(length: 2, vsync: this);
    _loadTemplates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    try {
      final templates = await _templateService.getPublicTemplates();
      setState(() {
        _templates = templates;
        _filteredTemplates = templates;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load templates: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterTemplates() {
    var filtered = _templates;

    if (_selectedCategory.isNotEmpty) {
      filtered = filtered
          .where((t) => t.category == _selectedCategory)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (t) =>
                t.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                t.description.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    setState(() => _filteredTemplates = filtered);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 48 + 48 + 4),
        child: Container(
          decoration: const BoxDecoration(
            gradient: CommunityColors.communityGradient,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              AppBar(
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.collections_bookmark,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Commission Templates',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Browse template artworks and styles',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                  tabs: const [
                    Tab(text: 'Browse'),
                    Tab(text: 'Featured'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: CommunityColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildBrowseTab(), _buildFeaturedTab()],
            ),
    );
  }

  Widget _buildBrowseTab() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (value) {
              _searchQuery = value;
              _filterTemplates();
            },
            decoration: InputDecoration(
              hintText: 'Search templates...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
        ),

        // Category Filter
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildCategoryChip('All', ''),
              ..._categories.map(
                (cat) => _buildCategoryChip(cat.toUpperCase(), cat),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Templates List
        if (_filteredTemplates.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No templates found',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredTemplates.length,
              itemBuilder: (context, index) {
                final template = _filteredTemplates[index];
                return _buildTemplateCard(template);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFeaturedTab() {
    return FutureBuilder<List<CommissionTemplate>>(
      future: _templateService.getFeaturedTemplates(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_outline, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No featured templates',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            return _buildTemplateCard(snapshot.data![index]);
          },
        );
      },
    );
  }

  Widget _buildTemplateCard(CommissionTemplate template) {
    final formatter = intl.NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if (widget.onTemplateSelected != null) {
            widget.onTemplateSelected!(template);
            Navigator.pop(context);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (template.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        template.imageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.palette),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          template.description,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              formatter.format(template.basePrice),
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${template.estimatedDays} days',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (template.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Wrap(
                    spacing: 4,
                    children: template.tags
                        .take(3)
                        .map(
                          (tag) => Chip(
                            label: Text(
                              tag,
                              style: const TextStyle(fontSize: 10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(),
                  ),
                ),
              if (template.avgRating > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        template.avgRating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${template.useCount} used)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, String category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedCategory = category);
          _filterTemplates();
        },
      ),
    );
  }
}
