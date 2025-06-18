import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;

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
      appBar: AppBar(title: const Text('Favorites')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
              ? _buildEmptyState()
              : _buildFavoritesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _isCurrentUser
                ? 'You haven\'t added any favorites yet'
                : 'This user hasn\'t added any favorites yet',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          if (_isCurrentUser) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to discover screen or another place to add favorites
                Navigator.pushNamed(context, '/discover');
              },
              icon: const Icon(Icons.search),
              label: const Text('Discover Content'),
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
      case 'word':
        return Icons.text_fields;
      case 'quote':
        return Icons.format_quote;
      case 'article':
        return Icons.article;
      case 'book':
        return Icons.book;
      case 'author':
        return Icons.person;
      case 'content':
      default:
        return Icons.favorite;
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
