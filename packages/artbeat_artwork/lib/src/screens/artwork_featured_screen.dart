import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart' show MainLayout, AppLogger;
import '../models/artwork_model.dart';
import '../services/artwork_pagination_service.dart';
import '../widgets/artwork_grid_widget.dart';
import '../widgets/artwork_header.dart';

/// Screen for displaying featured artwork
class ArtworkFeaturedScreen extends StatefulWidget {
  const ArtworkFeaturedScreen({super.key});

  @override
  State<ArtworkFeaturedScreen> createState() => _ArtworkFeaturedScreenState();
}

class _ArtworkFeaturedScreenState extends State<ArtworkFeaturedScreen> {
  final ArtworkPaginationService _paginationService =
      ArtworkPaginationService();
  final ScrollController _scrollController = ScrollController();

  List<ArtworkModel> _featuredArtworks = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitialArtworks();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialArtworks() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final state = await _paginationService.loadFeaturedArtworks();

      if (mounted) {
        setState(() {
          _featuredArtworks = state.items;
          _lastDocument = state.lastDocument;
          _hasMore = state.hasMore;
          _isLoading = false;
        });

        AppLogger.info('Loaded ${_featuredArtworks.length} featured artworks');
      }
    } catch (e) {
      AppLogger.error('Error loading featured artworks: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreArtworks() async {
    if (_isLoadingMore || !_hasMore) return;

    try {
      setState(() {
        _isLoadingMore = true;
      });

      final state = await _paginationService.loadFeaturedArtworks(
        lastDocument: _lastDocument,
      );

      if (mounted) {
        setState(() {
          _featuredArtworks.addAll(state.items);
          _lastDocument = state.lastDocument;
          _hasMore = state.hasMore;
          _isLoadingMore = false;
        });

        AppLogger.info('Loaded ${state.items.length} more featured artworks');
      }
    } catch (e) {
      AppLogger.error('Error loading more artworks: $e');
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _loadMoreArtworks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 0,
      appBar: ArtworkHeader(
        title: 'artwork_featured_title'.tr(),
        showBackButton: true,
        showSearch: true,
        onBackPressed: () => Navigator.of(context).pop(),
        onSearchPressed: () => Navigator.pushNamed(context, '/search'),
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'artwork_discover_error'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'error_unknown'.tr(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInitialArtworks,
              child: Text('artwork_retry_button'.tr()),
            ),
          ],
        ),
      );
    }

    if (_featuredArtworks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image_not_supported_outlined,
                size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'artwork_featured_no_results'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ArtworkGridWidget(
            artworks: _featuredArtworks,
            onRefresh: _loadInitialArtworks,
            scrollController: _scrollController,
          ),
        ),
        // Loading indicator for pagination
        if (_isLoadingMore)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}
