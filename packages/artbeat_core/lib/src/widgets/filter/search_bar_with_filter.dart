import 'package:flutter/material.dart';
import '../../models/filter_types.dart';
import 'filter_sheet.dart';

class SearchBarWithFilter extends StatefulWidget
    implements PreferredSizeWidget {
  final String searchHint;
  final void Function(String) onSearchChanged;
  final FilterParameters initialFilters;
  final void Function(FilterParameters) onFiltersChanged;
  final List<String>? availableLocations;
  final List<String>? availableTags;
  final bool showArtistTypes;
  final bool showArtMediums;
  final bool showDateRange;

  const SearchBarWithFilter({
    super.key,
    required this.searchHint,
    required this.onSearchChanged,
    required this.initialFilters,
    required this.onFiltersChanged,
    this.availableLocations,
    this.availableTags,
    this.showArtistTypes = false,
    this.showArtMediums = false,
    this.showDateRange = false,
  });

  @override
  State<SearchBarWithFilter> createState() => _SearchBarWithFilterState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);
}

class _SearchBarWithFilterState extends State<SearchBarWithFilter> {
  late TextEditingController _searchController;
  late FilterParameters _currentFilters;
  bool _hasActiveFilters = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.initialFilters.searchQuery,
    );
    _currentFilters = widget.initialFilters;
    _updateActiveFiltersStatus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateActiveFiltersStatus() {
    setState(() {
      _hasActiveFilters =
          _currentFilters.artistTypes?.isNotEmpty == true ||
          _currentFilters.artMediums?.isNotEmpty == true ||
          _currentFilters.locations?.isNotEmpty == true ||
          _currentFilters.tags?.isNotEmpty == true ||
          _currentFilters.startDate != null ||
          _currentFilters.endDate != null ||
          _currentFilters.sortBy != SortOption.relevance;
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterSheet(
        initialFilters: _currentFilters,
        onFiltersChanged: (filters) {
          setState(() {
            _currentFilters = filters;
            _updateActiveFiltersStatus();
          });
          widget.onFiltersChanged(filters);
        },
        availableLocations: widget.availableLocations,
        availableTags: widget.availableTags,
        showArtistTypes: widget.showArtistTypes,
        showArtMediums: widget.showArtMediums,
        showDateRange: widget.showDateRange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: widget.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          widget.onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: widget.onSearchChanged,
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: _hasActiveFilters
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: _showFilterSheet,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.tune,
                  color: _hasActiveFilters
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
