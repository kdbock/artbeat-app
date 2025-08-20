const admin = require('firebase-admin');

// Initialize Firebase Admin (only if not already initialized)
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

async function fixBrokenArtworkImages() {
  try {
    console.log('🔍 Starting artwork image cleanup...');
    
    const problematicUrl = "https://firebasestorage.googleapis.com/v0/b/wordnerd-artbeat.firebasestorage.app/o/artwork_images%2FEdH8MvWk4Ja6eoSZM59QtOaxEK43%2Fnew%2F1750961590495_EdH8MvWk4Ja6eoSZM59QtOaxEK43?alt=media&token=d9e1ed0b-e106-44e3-a9d4-5da43d0ff045";
    
    // Find artwork with this specific broken URL
    const artworkSnapshot = await db.collection('artwork')
      .where('imageUrl', '==', problematicUrl)
      .get();
    
    console.log(`📊 Found ${artworkSnapshot.docs.length} artwork with broken URL`);
    
    for (const doc of artworkSnapshot.docs) {
      const data = doc.data();
      console.log(`❌ Broken artwork found:`);
      console.log(`   - ID: ${doc.id}`);
      console.log(`   - Title: ${data.title}`);
      console.log(`   - Artist: ${data.userId}`);
      console.log(`   - Created: ${data.createdAt?.toDate()}`);
      
      // Update with placeholder image
      await doc.ref.update({
        imageUrl: 'https://via.placeholder.com/400x300/E0E0E0/757575?text=Image+Not+Available',
        hasPlaceholderImage: true,
        originalImageUrl: problematicUrl, // Keep reference to original
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      console.log(`✅ Fixed artwork ${doc.id} with placeholder image`);
    }
    
    console.log('🎉 Cleanup completed successfully!');
    
  } catch (error) {
    console.error('❌ Error during cleanup:', error);
  }
}

// Export for Cloud Functions or run directly
if (require.main === module) {
  fixBrokenArtworkImages().then(() => {
    console.log('Script completed');
    process.exit(0);
  });
}

module.exports = { fixBrokenArtworkImages };
