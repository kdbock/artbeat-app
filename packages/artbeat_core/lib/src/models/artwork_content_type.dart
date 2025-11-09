enum ArtworkContentType {
  visual('visual'),
  written('written'),
  audio('audio'),
  comic('comic');

  const ArtworkContentType(this.value);
  final String value;

  static ArtworkContentType fromString(String value) {
    return ArtworkContentType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ArtworkContentType.visual,
    );
  }

  String get displayName {
    switch (this) {
      case ArtworkContentType.visual:
        return 'Visual Art';
      case ArtworkContentType.written:
        return 'Written Work';
      case ArtworkContentType.audio:
        return 'Audio';
      case ArtworkContentType.comic:
        return 'Comic';
    }
  }

  String get description {
    switch (this) {
      case ArtworkContentType.visual:
        return 'Paintings, photos, digital art, sculptures';
      case ArtworkContentType.written:
        return 'Stories, poetry, essays, scripts';
      case ArtworkContentType.audio:
        return 'Podcasts, audiobooks, spoken word';
      case ArtworkContentType.comic:
        return 'Graphic novels, webtoons, comic strips';
    }
  }
}
