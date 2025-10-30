import 'package:flutter/material.dart';
import '../models/direct_commission_model.dart';
import '../services/direct_commission_service.dart';

/// Widget to browse artists accepting commissions
class CommissionArtistsBrowser extends StatefulWidget {
  final VoidCallback? onCommissionRequest;

  const CommissionArtistsBrowser({super.key, this.onCommissionRequest});

  @override
  State<CommissionArtistsBrowser> createState() =>
      _CommissionArtistsBrowserState();
}

class _CommissionArtistsBrowserState extends State<CommissionArtistsBrowser> {
  final DirectCommissionService _commissionService = DirectCommissionService();

  bool _isLoading = false;
  List<ArtistCommissionSettings> _artists = [];
  CommissionType? _selectedType;

  @override
  void initState() {
    super.initState();
    _loadCommissionArtists();
  }

  Future<void> _loadCommissionArtists() async {
    setState(() => _isLoading = true);

    try {
      final artists = await _commissionService.getAvailableArtists(
        type: _selectedType,
      );
      if (mounted) {
        setState(() {
          _artists = artists;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading artists: $e')));
      }
    }
  }

  void _handleTypeFilter(CommissionType? type) {
    setState(() => _selectedType = type);
    _loadCommissionArtists();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.art_track,
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Commission Artists',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Browse ${_artists.length} artists accepting commissions',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Type filter
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: 'All Types',
                      selected: _selectedType == null,
                      onSelected: () => _handleTypeFilter(null),
                    ),
                    ...CommissionType.values.map((type) {
                      return _buildFilterChip(
                        label: type.displayName,
                        selected: _selectedType == type,
                        onSelected: () => _handleTypeFilter(type),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Artists list
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_artists.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No artists found',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back soon for more commission artists',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _artists.length,
              itemBuilder: (context, index) {
                final artist = _artists[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildArtistCard(artist),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        backgroundColor: Colors.white,
        selectedColor: Colors.blue.shade100,
        side: BorderSide(
          color: selected ? Colors.blue.shade300 : Colors.grey[300]!,
        ),
      ),
    );
  }

  Widget _buildArtistCard(ArtistCommissionSettings artist) {
    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Artist avatar placeholder
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Icon(Icons.palette, size: 48, color: Colors.blue.shade300),
            ),
          ),
          // Artist info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Artist ID: ${artist.artistId.substring(0, 8)}...',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                if (artist.basePrice > 0)
                  Text(
                    'From \$${artist.basePrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Navigate to artist profile or commission request
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Commission request feature coming soon',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Request',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
