import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_capture/artbeat_capture.dart';

class FavoritesScreen extends StatefulWidget {
  final String userId;

  const FavoritesScreen({super.key, required this.userId});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final core.UserService _userService = core.UserService();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  List<core.FavoriteModel> _favorites = [];
  bool _isLoading = true;
  bool _isCurrentUser = false;

  @override
  void initState() {
    super.initState();
    _isCurrentUser = currentUser != null && currentUser!.uid == widget.userId;
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final favorites = await _userService.getUserFavorites();
      if (!mounted) return;

      setState(() {
        _favorites = favorites
            .map((f) => core.FavoriteModel.fromMap(f, f['id'] as String))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading favorites: ${e.toString()}')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Fan of',
          style: TextStyle(
            color: core.ArtbeatColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: core.ArtbeatColors.textPrimary),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              core.ArtbeatColors.primaryPurple.withAlpha(13), // 0.05 opacity
              Colors.white,
              core.ArtbeatColors.primaryGreen.withAlpha(13), // 0.05 opacity
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: core.ArtbeatColors.primaryPurple,
                  ),
                )
              : _favorites.isEmpty
              ? _buildEmptyState()
              : _buildFavoritesList(),
        ),
      ),
      bottomNavigationBar: core.UniversalBottomNav(
        currentIndex: -1, // No specific index for this screen
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/dashboard');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/art-walk/dashboard');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/community/dashboard');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/events/dashboard');
              break;
            case 4:
              // Open capture as modal instead of navigation
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const CaptureScreen(),
                  fullscreenDialog: true,
                ),
              );
              break;
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.front_hand,
            size: 80,
            color: core.ArtbeatColors.accentYellow,
          ),
          const SizedBox(height: 16),
          Text(
            _isCurrentUser
                ? 'You haven\'t become a fan of anyone yet'
                : 'This user isn\'t a fan of anyone yet',
            style: const TextStyle(
              fontSize: 16,
              color: core.ArtbeatColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (_isCurrentUser) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to discover screen or another place to add favorites
                Navigator.pushNamed(context, '/discover');
              },
              icon: const Icon(Icons.search),
              label: const Text('Discover Artists'),
              style: ElevatedButton.styleFrom(
                backgroundColor: core.ArtbeatColors.primaryPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final favorite = _favorites[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
            child: ListTile(
              leading: Hero(
                tag: 'favorite_${favorite.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: favorite.imageUrl.isNotEmpty
                      ? Image.network(
                          favorite.imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, obj, st) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: Icon(
                            _getIconForType(favorite.type),
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                ),
              ),
              title: Text(
                favorite.title.isNotEmpty ? favorite.title : 'Unnamed Favorite',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(favorite.description),
              trailing: _isCurrentUser
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmRemoveFavorite(favorite.id),
                    )
                  : null,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/profile/favorite-detail',
                  arguments: {
                    'favoriteId': favorite.id,
                    'userId': widget.userId,
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'artwork':
        return Icons.palette_outlined;
      case 'artist':
        return Icons.person_outlined;
      case 'gallery':
        return Icons.museum_outlined;
      case 'event':
        return Icons.event_outlined;
      case 'walk':
        return Icons.directions_walk_outlined;
      default:
        return Icons.front_hand; // Fan/applause icon
    }
  }

  Future<void> _confirmRemoveFavorite(String favoriteId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Favorite'),
        content: const Text(
          'Are you sure you want to remove this from your favorites?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('REMOVE'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _userService.removeFromFavorites(favoriteId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from favorites')),
          );
          _loadFavorites(); // Refresh the list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error removing favorite: ${e.toString()}')),
          );
        }
      }
    }
  }
}
