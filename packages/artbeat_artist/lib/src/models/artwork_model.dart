// Create the missing artwork_model.dart file.
class ArtworkModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String medium;
  final List<String> styles;
  final double? price;
  final bool isForSale;
  final String? dimensions;
  final int? yearCreated;
  final String artistProfileId;
  final String userId;

  ArtworkModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.medium,
    required this.styles,
    this.price,
    required this.isForSale,
    this.dimensions,
    this.yearCreated,
    required this.artistProfileId,
    required this.userId,
  });

  factory ArtworkModel.fromMap(Map<String, dynamic> map) {
    return ArtworkModel(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      imageUrl: map['imageUrl'],
      medium: map['medium'],
      styles: List<String>.from(map['styles'] ?? []),
      price: map['price'],
      isForSale: map['isForSale'],
      dimensions: map['dimensions'],
      yearCreated: map['yearCreated'],
      artistProfileId: map['artistProfileId'],
      userId: map['userId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'medium': medium,
      'styles': styles,
      'price': price,
      'isForSale': isForSale,
      'dimensions': dimensions,
      'yearCreated': yearCreated,
      'artistProfileId': artistProfileId,
      'userId': userId,
    };
  }

  String get getId => id;
  String get getImageUrl => imageUrl;
  bool get getIsForSale => isForSale;
  double? get getPrice => price;
  String get getTitle => title;
  String get getMedium => medium;
}
