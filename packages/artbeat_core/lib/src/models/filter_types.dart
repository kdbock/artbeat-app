
/// Represents sorting options for search results
enum SortOption {
  relevance('Relevance'),
  newestFirst('Newest First'),
  oldestFirst('Oldest First'),
  mostPopular('Most Popular'),
  leastPopular('Least Popular');

  final String displayName;
  const SortOption(this.displayName);
}

/// List of available artist types
enum ArtistType {
  painter,
  sculptor,
  photographer,
  illustrator,
  graphicDesigner,
  printmaker,
  ceramicist,
  muralist,
  installationArtist,
  performanceArtist,
  tattooArtist,
  animator,
  digitalArtist,
  collageArtist,
  mixedMediaArtist,
  streetArtist,
  graffitiArtist,
  fiberArtist,
  textileArtist,
  glassArtist,
  metalworker,
  woodworker,
  calligrapher,
  videoArtist,
  conceptualArtist,
  soundArtist,
  bookArtist,
  papercraftArtist,
  bodyArtist,
  enamelArtist,
  resinArtist,
  threeDimensionalArtist,
  visualArtist,
  chalkArtist,
  lightArtist,
  landscapeArtist,
  portraitArtist,
  comicArtist,
  storyboardArtist,
  caricatureArtist,
  miniatureArtist,
  fashionIllustrator,
  architecturalArtist;

  String get displayName => name
      .replaceAllMapped(
        RegExp(r'[A-Z]'),
        (match) => ' ${match.group(0)!.toLowerCase()}',
      )
      .capitalize();
}

/// List of available art mediums
enum ArtMedium {
  oil,
  acrylic,
  watercolor,
  gouache,
  ink,
  charcoal,
  graphite,
  coloredPencil,
  pastel,
  marker,
  collage,
  mixedMedia,
  digitalPainting,
  photography,
  sculpture,
  ceramic,
  glass,
  metalwork,
  woodwork,
  textile,
  fiberArt,
  printmaking,
  lithography,
  screenPrinting,
  etching,
  monotype,
  installationArt,
  performanceArt,
  videoArt,
  animation,
  assemblage,
  mosaic,
  foundObject,
  threeDPrinting,
  tattoo,
  bodyArt,
  calligraphy,
  graffiti,
  streetArt,
  paperCutting,
  origami,
  bookArts,
  enamel,
  resinArt,
  sandArt,
  lightArt,
  soundArt;

  String get displayName => name
      .replaceAllMapped(
        RegExp(r'[A-Z]'),
        (match) => ' ${match.group(0)!.toLowerCase()}',
      )
      .capitalize();
}

/// Filter parameters for artwork and artists
class FilterParameters {
  final String? searchQuery;
  final List<ArtistType>? artistTypes;
  final List<ArtMedium>? artMediums;
  final List<String>? locations;
  final List<String>? tags;
  final DateTime? startDate;
  final DateTime? endDate;
  final SortOption sortBy;
  final bool ascending;

  const FilterParameters({
    this.searchQuery,
    this.artistTypes,
    this.artMediums,
    this.locations,
    this.tags,
    this.startDate,
    this.endDate,
    this.sortBy = SortOption.relevance,
    this.ascending = true,
  });

  FilterParameters copyWith({
    String? searchQuery,
    List<ArtistType>? artistTypes,
    List<ArtMedium>? artMediums,
    List<String>? locations,
    List<String>? tags,
    DateTime? startDate,
    DateTime? endDate,
    SortOption? sortBy,
    bool? ascending,
  }) {
    return FilterParameters(
      searchQuery: searchQuery ?? this.searchQuery,
      artistTypes: artistTypes ?? this.artistTypes,
      artMediums: artMediums ?? this.artMediums,
      locations: locations ?? this.locations,
      tags: tags ?? this.tags,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'searchQuery': searchQuery,
      'artistTypes': artistTypes?.map((t) => t.name).toList(),
      'artMediums': artMediums?.map((m) => m.name).toList(),
      'locations': locations,
      'tags': tags,
      'startDate': startDate?.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
      'sortBy': sortBy.name,
      'ascending': ascending,
    };
  }

  factory FilterParameters.fromMap(Map<String, dynamic> map) {
    return FilterParameters(
      searchQuery: map['searchQuery'] as String?,
      artistTypes: (map['artistTypes'] as List<String>?)
          ?.map((t) => ArtistType.values.firstWhere((e) => e.name == t))
          .toList(),
      artMediums: (map['artMediums'] as List<String>?)
          ?.map((m) => ArtMedium.values.firstWhere((e) => e.name == m))
          .toList(),
      locations: (map['locations'] as List<String>?)?.toList(),
      tags: (map['tags'] as List<String>?)?.toList(),
      startDate: map['startDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['startDate'] as int)
          : null,
      endDate: map['endDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endDate'] as int)
          : null,
      sortBy: SortOption.values.firstWhere(
        (e) => e.name == (map['sortBy'] as String),
        orElse: () => SortOption.relevance,
      ),
      ascending: map['ascending'] as bool? ?? true,
    );
  }
}

/// Extension to help with string capitalization
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
