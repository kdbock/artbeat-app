import 'package:flutter/material.dart';
// Removed unused import for in_app_purchase_manager.dart
import '../../services/in_app_purchase_setup.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../theme/artbeat_colors.dart';
import '../../widgets/gift_selection_widget.dart';

class GiftsScreen extends StatefulWidget {
  final bool showAppBar;
  const GiftsScreen({Key? key, this.showAppBar = true}) : super(key: key);

  @override
  State<GiftsScreen> createState() => _GiftsScreenState();
}

class _GiftsScreenState extends State<GiftsScreen> {
  // Removed unused field _purchaseManager
  final UserService _userService = UserService();

  List<UserModel> _artists = [];
  UserModel? _selectedArtist;
  bool _isLoadingArtists = true;
  // Removed unused field _isPurchaseInitialized
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initializePurchases();
    _loadArtists();
  }

  Future<void> _initializePurchases() async {
    final setup = InAppPurchaseSetup();
    await setup.initialize();
    // Removed assignment to _isPurchaseInitialized
    // You may add any other logic here if needed
  }

  Future<void> _loadArtists() async {
    try {
      final artistsData = await _userService.getUsersByRole('artist');
      final artists = artistsData
          .map(
            (data) => UserModel(
              id: data['uid'] as String? ?? '',
              email: data['email'] as String? ?? '',
              username: data['username'] as String? ?? '',
              fullName:
                  data['fullName'] as String? ??
                  data['displayName'] as String? ??
                  '',
              createdAt: DateTime.now(),
              profileImageUrl: data['profileImageUrl'] as String? ?? '',
            ),
          )
          .toList();

      if (mounted) {
        setState(() {
          _artists = artists;
          _isLoadingArtists = false;
        });
      }
    } catch (e, _) {
      if (mounted) {
        setState(() {
          _isLoadingArtists = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading artists: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<UserModel> _getFilteredArtists() {
    if (_searchQuery.isEmpty) return _artists;
    return _artists
        .where(
          (artist) =>
              artist.fullName.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              artist.username.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
        )
        .toList();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gift Credits',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Send credits to artists and collectors',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          _buildArtistSelector(),
          const SizedBox(height: 24),
          ..._buildGiftPackages(),
          const SizedBox(height: 32),
        ],
      ),
    );
    if (widget.showAppBar) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Send Credits'),
          backgroundColor: ArtbeatColors.primary,
          foregroundColor: Colors.white,
        ),
        body: content,
      );
    } else {
      return content;
    }
  }

  Widget _buildArtistSelector() {
    final filteredArtists = _getFilteredArtists();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Artist',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Search artists...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoadingArtists)
          const SizedBox(
            height: 50,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (filteredArtists.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                _searchQuery.isEmpty
                    ? 'No artists found'
                    : 'No artists match your search',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filteredArtists.length,
              itemBuilder: (context, index) {
                final artist = filteredArtists[index];
                final isSelected = _selectedArtist?.id == artist.id;
                return ListTile(
                  onTap: () {
                    setState(() {
                      _selectedArtist = artist;
                      _searchQuery = '';
                    });
                  },
                  selected: isSelected,
                  selectedTileColor: ArtbeatColors.primary.withValues(
                    alpha: 0.1,
                  ),
                  leading: CircleAvatar(
                    backgroundImage: artist.profileImageUrl.isNotEmpty
                        ? NetworkImage(artist.profileImageUrl)
                        : null,
                    child: artist.profileImageUrl.isEmpty
                        ? Text(
                            artist.fullName.isNotEmpty
                                ? artist.fullName[0]
                                : '?',
                          )
                        : null,
                  ),
                  title: Text(artist.fullName),
                  subtitle: Text('@${artist.username}'),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle,
                          color: ArtbeatColors.primary,
                        )
                      : null,
                );
              },
            ),
          ),
        if (_selectedArtist != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ArtbeatColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ArtbeatColors.primary),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: ArtbeatColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sending to ${_selectedArtist!.fullName}',
                      style: const TextStyle(
                        color: ArtbeatColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildGiftPackages() {
    final gifts = [
      {
        'productId': r'artbeat_gift_small',
        'credits': 50,
        'price': r' 24.99',
        'icon': Icons.card_giftcard,
        'name': 'Supporter Gift',
      },
      {
        'productId': r'artbeat_gift_medium',
        'credits': 100,
        'price': r' 9.99',
        'icon': Icons.card_giftcard,
        'name': 'Fan Gift',
      },
      {
        'productId': r'artbeat_gift_large',
        'credits': 250,
        'price': r' 24.99',
        'icon': Icons.card_giftcard,
        'name': 'Patron Gift',
      },
      {
        'productId': r'artbeat_gift_premium',
        'credits': 500,
        'price': r' 49.99',
        'icon': Icons.card_giftcard,
        'name': 'Benefactor Gift',
        'isPopular': true,
      },
    ];

    return gifts.map((gift) {
      final isPopular = gift['isPopular'] as bool? ?? false;
      return Column(
        children: [
          Card(
            elevation: isPopular ? 8 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isPopular
                  ? const BorderSide(color: ArtbeatColors.primary, width: 2)
                  : BorderSide.none,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                gift['icon'] as IconData,
                                color: ArtbeatColors.primary,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${gift['credits']} Credits',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    gift['price'] as String,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: ArtbeatColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (isPopular)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: ArtbeatColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Best Value',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedArtist == null
                          ? null
                          : () {
                              showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                ),
                                builder: (context) => GiftSelectionWidget(
                                  recipientId: _selectedArtist!.id,
                                  recipientName: _selectedArtist!.fullName,
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPopular
                            ? ArtbeatColors.primary
                            : Colors.grey[300],
                        foregroundColor: isPopular
                            ? Colors.white
                            : Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Send Gift'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      );
    }).toList();
  }
}
