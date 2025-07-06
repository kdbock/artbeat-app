const admin = require('firebase-admin');
const serviceAccount = require('../assets/client_secret_665020451634-sb8o1cgfji453vifsr3gqqqe1u2o5in4.apps.googleusercontent.com.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function initializeAdminStats() {
  try {
    // Create initial admin stats document
    await db.collection('admin_stats').doc('overview').set({
      totalUsers: 0,
      totalArtists: 0,
      totalGalleries: 0,
      totalArtworks: 0,
      totalCaptures: 0,
      totalEvents: 0,
      newUsersToday: 0,
      newUsersThisWeek: 0,
      newUsersThisMonth: 0,
      activeUsersToday: 0,
      activeUsersThisWeek: 0,
      activeUsersThisMonth: 0,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log('✅ Successfully initialized admin stats');
  } catch (error) {
    console.error('❌ Error initializing admin stats:', error);
  } finally {
    process.exit(0);
  }
}

initializeAdminStats();
