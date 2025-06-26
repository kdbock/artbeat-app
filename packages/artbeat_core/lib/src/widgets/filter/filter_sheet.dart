import 'package:flutter/material.dart';
import '../../models/filter_types.dart';
import 'filter_chips.dart';
import 'date_range_filter.dart';
import 'sort_filter.dart';

class FilterSheet extends StatefulWidget {
  final FilterParameters initialFilters;
  final void Function(FilterParameters) onFiltersChanged;
  final List<String>? availableLocations;
  final List<String>? availableTags;
  final bool showArtistTypes;
  final bool showArtMediums;
  final bool showDateRange;

  const FilterSheet({
    super.key,
    required this.initialFilters,
    required this.onFiltersChanged,
    this.availableLocations,
    this.availableTags,
    this.showArtistTypes = false,
    this.showArtMediums = false,
    this.showDateRange = false,
  });

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late FilterParameters _currentFilters;

  @override
  void initState() {
    super.initState();
    _currentFilters = widget.initialFilters;
  }

  void _updateFilters(FilterParameters newFilters) {
    setState(() {
      _currentFilters = newFilters;
    });
    widget.onFiltersChanged(newFilters);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _updateFilters(const FilterParameters());
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Sort options
                    SortFilter(
                      currentSort: _currentFilters.sortBy,
                      ascending: _currentFilters.ascending,
                      onSortChanged: (sort, ascending) {
                        _updateFilters(
                          _currentFilters.copyWith(
                            sortBy: sort,
                            ascending: ascending,
                          ),
                        );
                      },
                    ),
                    const Divider(height: 32),

                    // Artist Types
                    if (widget.showArtistTypes) ...[
                      const Text(
                        'Artist Types',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilterChips<ArtistType>(
                        options: ArtistType.values,
                        selected: _currentFilters.artistTypes ?? [],
                        getLabel: (type) => type.displayName,
                        onSelectionChanged: (types) {
                          _updateFilters(
                            _currentFilters.copyWith(artistTypes: types),
                          );
                        },
                      ),
                      const Divider(height: 32),
                    ],

                    // Art Mediums
                    if (widget.showArtMediums) ...[
                      const Text(
                        'Art Mediums',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilterChips<ArtMedium>(
                        options: ArtMedium.values,
                        selected: _currentFilters.artMediums ?? [],
                        getLabel: (medium) => medium.displayName,
                        onSelectionChanged: (mediums) {
                          _updateFilters(
                            _currentFilters.copyWith(artMediums: mediums),
                          );
                        },
                      ),
                      const Divider(height: 32),
                    ],

                    // Locations
                    if (widget.availableLocations != null) ...[
                      const Text(
                        'Locations',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilterChips<String>(
                        options: widget.availableLocations!,
                        selected: _currentFilters.locations ?? [],
                        getLabel: (location) => location,
                        onSelectionChanged: (locations) {
                          _updateFilters(
                            _currentFilters.copyWith(locations: locations),
                          );
                        },
                      ),
                      const Divider(height: 32),
                    ],

                    // Tags
                    if (widget.availableTags != null) ...[
                      const Text(
                        'Tags',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilterChips<String>(
                        options: widget.availableTags!,
                        selected: _currentFilters.tags ?? [],
                        getLabel: (tag) => tag,
                        onSelectionChanged: (tags) {
                          _updateFilters(_currentFilters.copyWith(tags: tags));
                        },
                      ),
                      const Divider(height: 32),
                    ],

                    // Date Range
                    if (widget.showDateRange)
                      DateRangeFilter(
                        startDate: _currentFilters.startDate,
                        endDate: _currentFilters.endDate,
                        onDateRangeChanged: (start, end) {
                          _updateFilters(
                            _currentFilters.copyWith(
                              startDate: start,
                              endDate: end,
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
