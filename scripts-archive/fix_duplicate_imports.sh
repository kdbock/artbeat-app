#!/bin/bash
# filepath: /Users/kristybock/artbeat/scripts/fix_duplicate_imports.sh

# Script to fix duplicate imports in Dart files

echo "Fixing duplicate imports in the codebase..."

# Function to remove duplicate imports
fix_duplicates() {
  # Fix duplicate imports of artbeat_artist/artbeat_artist.dart
  find /Users/kristybock/artbeat/packages -name "*.dart" -type f -exec sed -i '' "s/import 'package:artbeat_artist\/artbeat_artist.dart';\nimport 'package:artbeat_artist\/artbeat_artist.dart';/import 'package:artbeat_artist\/artbeat_artist.dart';/g" {} \;
  find /Users/kristybock/artbeat/packages -name "*.dart" -type f -exec sed -i '' "s/import 'package:artbeat_artist\/artbeat_artist.dart';\nimport 'package:artbeat_artist\/artbeat_artist.dart';\nimport 'package:artbeat_artist\/artbeat_artist.dart';/import 'package:artbeat_artist\/artbeat_artist.dart';/g" {} \;
  
  # Fix duplicate imports of artbeat_artwork/artbeat_artwork.dart
  find /Users/kristybock/artbeat/packages -name "*.dart" -type f -exec sed -i '' "s/import 'package:artbeat_artwork\/artbeat_artwork.dart';\nimport 'package:artbeat_artwork\/artbeat_artwork.dart';/import 'package:artbeat_artwork\/artbeat_artwork.dart';/g" {} \;

  # Fix duplicate imports of artbeat_core/artbeat_core.dart
  find /Users/kristybock/artbeat/packages -name "*.dart" -type f -exec sed -i '' "s/import 'package:artbeat_core\/artbeat_core.dart';\nimport 'package:artbeat_core\/artbeat_core.dart';/import 'package:artbeat_core\/artbeat_core.dart';/g" {} \;
}

# Function to check for any missing models
check_artwork_model() {
  if [ ! -f "/Users/kristybock/artbeat/packages/artbeat_artwork/lib/src/models/artwork_model.dart" ]; then
    # Create the artwork model if missing
    mkdir -p /Users/kristybock/artbeat/packages/artbeat_artwork/lib/src/models
    cat > /Users/kristybock/artbeat/packages/artbeat_artwork/lib/src/models/artwork_model.dart << 'EOL'
// filepath: /Users/kristybock/artbeat/packages/artbeat_artwork/lib/src/models/artwork_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ArtworkModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String imageUrl;
  final double price;
  final String medium;
  final bool isSold;
  final String? dimensions;
  final String? materials;
  final String? location;
  final List<String>? tags;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? viewCount;
  final int? likeCount;
  final bool? isFeatured;
  final bool? isPublic;
  final String? externalLink;
  final double? commissionRate;
  
  ArtworkModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.medium,
    this.isSold = false,
    this.dimensions,
    this.materials,
    this.location,
    this.tags,
    required this.createdAt,
    this.updatedAt,
    this.viewCount,
    this.likeCount,
    this.isFeatured,
    this.isPublic,
    this.externalLink,
    this.commissionRate,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'price': price,
      'medium': medium,
      'isSold': isSold,
      'dimensions': dimensions,
      'materials': materials,
      'location': location,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'viewCount': viewCount ?? 0,
      'likeCount': likeCount ?? 0,
      'isFeatured': isFeatured ?? false,
      'isPublic': isPublic ?? true,
      'externalLink': externalLink,
      'commissionRate': commissionRate,
    };
  }
  
  factory ArtworkModel.fromMap(Map<String, dynamic> map, String id) {
    return ArtworkModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      medium: map['medium'] ?? '',
      isSold: map['isSold'] ?? false,
      dimensions: map['dimensions'],
      materials: map['materials'],
      location: map['location'],
      tags: map['tags'] != null ? List<String>.from(map['tags']) : null,
      createdAt: map['createdAt'] != null 
          ? map['createdAt'] is Timestamp 
              ? (map['createdAt'] as Timestamp).toDate() 
              : DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? map['updatedAt'] is Timestamp 
              ? (map['updatedAt'] as Timestamp).toDate() 
              : DateTime.parse(map['updatedAt']) 
          : null,
      viewCount: map['viewCount'],
      likeCount: map['likeCount'],
      isFeatured: map['isFeatured'],
      isPublic: map['isPublic'],
      externalLink: map['externalLink'],
      commissionRate: map['commissionRate'] != null 
          ? (map['commissionRate']).toDouble() 
          : null,
    );
  }
  
  factory ArtworkModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ArtworkModel.fromMap(data, doc.id);
  }
  
  ArtworkModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? imageUrl,
    double? price,
    String? medium,
    bool? isSold,
    String? dimensions,
    String? materials,
    String? location,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? viewCount,
    int? likeCount,
    bool? isFeatured,
    bool? isPublic,
    String? externalLink,
    double? commissionRate,
  }) {
    return ArtworkModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      medium: medium ?? this.medium,
      isSold: isSold ?? this.isSold,
      dimensions: dimensions ?? this.dimensions,
      materials: materials ?? this.materials,
      location: location ?? this.location,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      isFeatured: isFeatured ?? this.isFeatured,
      isPublic: isPublic ?? this.isPublic,
      externalLink: externalLink ?? this.externalLink,
      commissionRate: commissionRate ?? this.commissionRate,
    );
  }
}
EOL
  fi
}

# Function to create ArtworkService if missing
create_artwork_service() {
  if [ ! -f "/Users/kristybock/artbeat/packages/artbeat_artwork/lib/src/services/artwork_service.dart" ]; then
    # Create artwork service if missing
    mkdir -p /Users/kristybock/artbeat/packages/artbeat_artwork/lib/src/services
    cat > /Users/kristybock/artbeat/packages/artbeat_artwork/lib/src/services/artwork_service.dart << 'EOL'
// filepath: /Users/kristybock/artbeat/packages/artbeat_artwork/lib/src/services/artwork_service.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

import 'package:artbeat_artwork/src/models/artwork_model.dart';
import 'package:artbeat_artwork/src/services/image_moderation_service.dart';

class ArtworkService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImageModerationService _moderationService = ImageModerationService();
  
  // Get all artwork
  Future<List<ArtworkModel>> getAllArtwork({int limit = 20}) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('artwork')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
          
      return snapshot.docs
          .map((doc) => ArtworkModel.fromDocumentSnapshot(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting all artwork: $e');
      return [];
    }
  }
  
  // Get artwork by artist
  Future<List<ArtworkModel>> getArtistArtworks(String artistId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('artwork')
          .where('userId', isEqualTo: artistId)
          .orderBy('createdAt', descending: true)
          .get();
          
      return snapshot.docs
          .map((doc) => ArtworkModel.fromDocumentSnapshot(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting artist artwork: $e');
      return [];
    }
  }
  
  // Get artwork by ID
  Future<ArtworkModel?> getArtworkById(String id) async {
    try {
      final DocumentSnapshot doc = 
          await _firestore.collection('artwork').doc(id).get();
          
      if (doc.exists) {
        return ArtworkModel.fromDocumentSnapshot(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting artwork by ID: $e');
      return null;
    }
  }
  
  // Create new artwork
  Future<String?> createArtwork({
    required String title,
    required String description,
    required String medium,
    required double price,
    required File imageFile,
    String? dimensions,
    String? materials,
    String? location,
    List<String>? tags,
  }) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Moderate image content if needed
      final bool isAppropriate = await _moderationService.checkImage(imageFile);
      if (!isAppropriate) {
        throw Exception('Image contains inappropriate content');
      }
      
      // Upload image to Firebase Storage
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final Reference storageRef = _storage
          .ref()
          .child('artwork_images/${currentUser.uid}/$fileName');
      
      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String imageUrl = await snapshot.ref.getDownloadURL();
      
      // Create artwork in Firestore
      final ArtworkModel artwork = ArtworkModel(
        id: '', // Will be assigned by Firestore
        userId: currentUser.uid,
        title: title,
        description: description,
        imageUrl: imageUrl,
        price: price,
        medium: medium,
        dimensions: dimensions,
        materials: materials,
        location: location,
        tags: tags,
        createdAt: DateTime.now(),
      );
      
      final DocumentReference docRef = 
          await _firestore.collection('artwork').add(artwork.toMap());
          
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating artwork: $e');
      return null;
    }
  }
  
  // Update existing artwork
  Future<bool> updateArtwork({
    required String id,
    String? title,
    String? description,
    String? medium,
    double? price,
    File? imageFile,
    String? dimensions,
    String? materials,
    String? location,
    List<String>? tags,
    bool? isSold,
    bool? isPublic,
    bool? isFeatured,
    String? externalLink,
    double? commissionRate,
  }) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Get existing artwork to verify ownership
      final DocumentSnapshot doc = 
          await _firestore.collection('artwork').doc(id).get();
          
      if (!doc.exists) {
        throw Exception('Artwork not found');
      }
      
      final data = doc.data() as Map<String, dynamic>;
      if (data['userId'] != currentUser.uid) {
        throw Exception('Not authorized to update this artwork');
      }
      
      // Create update map
      final Map<String, dynamic> updateData = {};
      
      // Upload new image if provided
      if (imageFile != null) {
        // Moderate image content
        final bool isAppropriate = await _moderationService.checkImage(imageFile);
        if (!isAppropriate) {
          throw Exception('Image contains inappropriate content');
        }
        
        final String fileName = 
            '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
        final Reference storageRef = _storage
            .ref()
            .child('artwork_images/${currentUser.uid}/$fileName');
        
        final UploadTask uploadTask = storageRef.putFile(imageFile);
        final TaskSnapshot snapshot = await uploadTask;
        final String imageUrl = await snapshot.ref.getDownloadURL();
        
        updateData['imageUrl'] = imageUrl;
      }
      
      // Add other fields to update
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (medium != null) updateData['medium'] = medium;
      if (price != null) updateData['price'] = price;
      if (dimensions != null) updateData['dimensions'] = dimensions;
      if (materials != null) updateData['materials'] = materials;
      if (location != null) updateData['location'] = location;
      if (tags != null) updateData['tags'] = tags;
      if (isSold != null) updateData['isSold'] = isSold;
      if (isPublic != null) updateData['isPublic'] = isPublic;
      if (isFeatured != null) updateData['isFeatured'] = isFeatured;
      if (externalLink != null) updateData['externalLink'] = externalLink;
      if (commissionRate != null) updateData['commissionRate'] = commissionRate;
      
      // Add updated timestamp
      updateData['updatedAt'] = FieldValue.serverTimestamp();
      
      // Update the document
      await _firestore.collection('artwork').doc(id).update(updateData);
      
      return true;
    } catch (e) {
      debugPrint('Error updating artwork: $e');
      return false;
    }
  }
  
  // Delete artwork
  Future<bool> deleteArtwork(String id) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Get existing artwork to verify ownership and get image URL
      final DocumentSnapshot doc = 
          await _firestore.collection('artwork').doc(id).get();
          
      if (!doc.exists) {
        throw Exception('Artwork not found');
      }
      
      final data = doc.data() as Map<String, dynamic>;
      if (data['userId'] != currentUser.uid) {
        throw Exception('Not authorized to delete this artwork');
      }
      
      // Delete image from storage if it exists
      if (data['imageUrl'] != null) {
        try {
          final String imageUrl = data['imageUrl'] as String;
          // Extract storage path from URL
          final Uri uri = Uri.parse(imageUrl);
          final String pathWithToken = uri.path;
          // Remove /o/ prefix and everything after ?
          final String storagePath = pathWithToken
              .replaceFirst('/o/', '')
              .split('?')[0];
          
          // URL decode the path
          final String decodedPath = Uri.decodeComponent(storagePath);
          
          await _storage.ref(decodedPath).delete();
        } catch (e) {
          // Continue even if image deletion fails
          debugPrint('Warning: Failed to delete image for artwork: $e');
        }
      }
      
      // Delete the artwork document
      await _firestore.collection('artwork').doc(id).delete();
      
      return true;
    } catch (e) {
      debugPrint('Error deleting artwork: $e');
      return false;
    }
  }
  
  // Filter artwork by medium and price range
  Future<List<ArtworkModel>> filterArtwork({
    String? medium,
    String? location,
    double? minPrice,
    double? maxPrice,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection('artwork')
          .where('isPublic', isEqualTo: true);
      
      if (medium != null && medium.isNotEmpty) {
        query = query.where('medium', isEqualTo: medium);
      }
      
      if (location != null && location.isNotEmpty) {
        query = query.where('location', isEqualTo: location);
      }
      
      // Apply price range filters after fetching
      QuerySnapshot snapshot = await query.limit(limit).get();
      
      List<ArtworkModel> artworks = snapshot.docs
          .map((doc) => ArtworkModel.fromDocumentSnapshot(doc))
          .toList();
      
      // Filter by price range if specified
      if (minPrice != null || maxPrice != null) {
        artworks = artworks.where((artwork) {
          final double price = artwork.price;
          if (minPrice != null && maxPrice != null) {
            return price >= minPrice && price <= maxPrice;
          } else if (minPrice != null) {
            return price >= minPrice;
          } else if (maxPrice != null) {
            return price <= maxPrice;
          }
          return true;
        }).toList();
      }
      
      return artworks;
    } catch (e) {
      debugPrint('Error filtering artwork: $e');
      return [];
    }
  }
  
  // Search artwork by title
  Future<List<ArtworkModel>> searchArtworkByTitle(String searchTerm) async {
    try {
      // Firestore doesn't support full text search, so we'll do a simple contains check
      // For a production app, consider using Algolia or similar
      QuerySnapshot snapshot = await _firestore
          .collection('artwork')
          .where('isPublic', isEqualTo: true)
          .orderBy('title')
          .startAt([searchTerm])
          .endAt([searchTerm + '\uf8ff'])
          .get();
      
      return snapshot.docs
          .map((doc) => ArtworkModel.fromDocumentSnapshot(doc))
          .toList();
    } catch (e) {
      debugPrint('Error searching artwork: $e');
      return [];
    }
  }
  
  // Get featured artwork
  Future<List<ArtworkModel>> getFeaturedArtwork({int limit = 10}) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('artwork')
          .where('isPublic', isEqualTo: true)
          .where('isFeatured', isEqualTo: true)
          .limit(limit)
          .get();
          
      return snapshot.docs
          .map((doc) => ArtworkModel.fromDocumentSnapshot(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting featured artwork: $e');
      return [];
    }
  }
}
EOL
  fi
}

# Execute the functions
fix_duplicates
check_artwork_model
create_artwork_service

echo "Running flutter pub get on packages..."
cd /Users/kristybock/artbeat && flutter pub get

echo "Fixed duplicate imports and missing files!"
