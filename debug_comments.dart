import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  // Initialize Firebase
  await Firebase.initializeApp();
  
  print('🔍 Checking comments in database...');
  
  try {
    final commentsSnapshot = await FirebaseFirestore.instance
        .collection('comments')
        .limit(10)  // Just check first 10 comments
        .get();
    
    print('📊 Found ${commentsSnapshot.docs.length} comments');
    
    for (var doc in commentsSnapshot.docs) {
      final data = doc.data();
      print('🔹 Comment ${doc.id}:');
      print('  - userName: "${data['userName'] ?? 'null'}"');
      print('  - userAvatarUrl: "${data['userAvatarUrl'] ?? 'null'}"');
      print('  - userId: "${data['userId'] ?? 'null'}"');
      print('  - hasAvatarUrl: ${data.containsKey('userAvatarUrl') && (data['userAvatarUrl'] as String).isNotEmpty}');
      print('');
    }
    
    // Also check users collection to see profile image URLs
    print('👤 Checking users collection...');
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .limit(5)
        .get();
    
    for (var doc in usersSnapshot.docs) {
      final data = doc.data();
      print('🔹 User ${doc.id}:');
      print('  - fullName: "${data['fullName'] ?? 'null'}"');
      print('  - profileImageUrl: "${data['profileImageUrl'] ?? 'null'}"');
      print('  - hasProfileImage: ${data.containsKey('profileImageUrl') && (data['profileImageUrl'] as String).isNotEmpty}');
      print('');
    }
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
