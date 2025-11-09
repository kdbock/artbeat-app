import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import '../models/collection_model.dart';
import '../services/collection_service.dart';

/// Screen for browsing curated galleries and featured collections
class CuratedGalleryScreen extends StatefulWidget {
  const CuratedGalleryScreen({super.key});

  @override
  State<CuratedGalleryScreen> createState() => _CuratedGalleryScreenState();
}

class _CuratedGalleryScreenState extends State<CuratedGalleryScreen> {
  final CollectionService _collectionService = CollectionService();

  List<CollectionModel> _featuredCollections = [];
  List<CollectionModel> _publicCollections = [];
  bool _isLoading = false;
  String? _error;
  CollectionType? _filterType;

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final futures = [
        _collectionService.getFeaturedCollections(),
        _collectionService.getPublicCollections(
          filterByType: _filterType,
          limit: 50,
        ),
      ];

      final results = await Future.wait(futures);

      if (!mounted) return;

      setState(() {
        _featuredCollections = results[0];
        _publicCollections = results[1];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshCollections() async {
    await _loadCollections();
  }

  void _filterCollections(CollectionType? type) {
    setState(() {
      _filterType = type;
    });
    _loadCollections();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('curated_gallery_title'.tr()),
        backgroundColor: core.ArtbeatColors.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<CollectionType?>(
            icon: const Icon(Icons.filter_list),
            onSelected: _filterCollections,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: null,
                child: Text('curated_gallery_filter_all'.tr()),
              ),
              ...CollectionType.values.map((type) => PopupMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  )),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _refreshCollections,
                  child: _buildContent(),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'curated_gallery_error_loading'.tr(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'curated_gallery_error_unknown'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadCollections,
            child: Text('curated_gallery_retry_button'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_featuredCollections.isEmpty && _publicCollections.isEmpty) {
      return _buildEmptyState();
    }

    return CustomScrollView(
      slivers: [
        if (_featuredCollections.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.amber[600],
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'curated_gallery_featured_section'.tr(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: core.ArtbeatColors.textPrimary,
                        ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _featuredCollections.length,
                itemBuilder: (context, index) {
                  return _buildFeaturedCollectionCard(
                      _featuredCollections[index]);
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.collections,
                  color: core.ArtbeatColors.primaryGreen,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  _filterType != null
                      ? '${_filterType!.displayName} Collections'
                      : 'curated_gallery_all_collections'.tr(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: core.ArtbeatColors.textPrimary,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        if (_publicCollections.isEmpty)
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'curated_gallery_no_collections'.tr(),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _buildPublicCollectionCard(_publicCollections[index]);
                },
                childCount: _publicCollections.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.collections_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'curated_gallery_empty_title'.tr(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'curated_gallery_empty_message'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadCollections,
            style: ElevatedButton.styleFrom(
              backgroundColor: core.ArtbeatColors.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: Text('curated_gallery_refresh_button'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCollectionCard(CollectionModel collection) {
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () => _navigateToCollectionDetail(collection),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover image placeholder
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      core.ArtbeatColors.primaryGreen.withValues(alpha: 0.7),
                      core.ArtbeatColors.primaryGreen.withValues(alpha: 0.3),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    if (collection.coverImageUrl?.isNotEmpty == true)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Image.network(
                          collection.coverImageUrl!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      const Center(
                        child: Icon(
                          Icons.collections,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),

                    // Featured badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber[600],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'curated_gallery_featured_badge'.tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Collection details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        collection.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        collection.type.displayName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: core.ArtbeatColors.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (collection.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Expanded(
                          child: Text(
                            collection.description,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.image,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${collection.artworkIds.length} artworks',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.visibility,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${collection.viewCount}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
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

  Widget _buildPublicCollectionCard(CollectionModel collection) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToCollectionDetail(collection),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image placeholder
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor.withValues(alpha: 0.7),
                      Theme.of(context).primaryColor.withValues(alpha: 0.3),
                    ],
                  ),
                ),
                child: collection.coverImageUrl?.isNotEmpty == true
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Image.network(
                          collection.coverImageUrl!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.collections,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            // Collection details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collection.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      collection.type.displayName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: core.ArtbeatColors.primaryGreen,
                            fontSize: 10,
                          ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.image,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '${collection.artworkIds.length}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 10,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.visibility,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${collection.viewCount}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCollectionDetail(CollectionModel collection) {
    // Increment view count
    _collectionService.incrementViewCount(collection.id);

    // Navigate to collection detail
    Navigator.pushNamed(
      context,
      '/collection/detail',
      arguments: {'collectionId': collection.id, 'collection': collection},
    );
  }
}
