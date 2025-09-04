const admin = require('firebase-admin');
const serviceAccount = require('../assets/client_secret_665020451634-sb8o1cgfji453vifsr3gqqqe1u2o5in4.apps.googleusercontent.com.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function setUserAsAdmin(email) {
  try {
    if (!email) {
      console.error('❌ Please provide an email address');
      console.log('Usage: node set_admin_user.js <email>');
      process.exit(1);
    }

    // Find user by email
    const usersSnapshot = await db.collection('users')
      .where('email', '==', email)
      .limit(1)
      .get();

    if (usersSnapshot.empty) {
      console.error(`❌ No user found with email: ${email}`);
      process.exit(1);
    }

    const userDoc = usersSnapshot.docs[0];
    const userId = userDoc.id;
    const userData = userDoc.data();

    console.log(`📧 Found user: ${userData.fullName || userData.username} (${email})`);
    console.log(`🆔 User ID: ${userId}`);
    console.log(`👤 Current user type: ${userData.userType || 'regular'}`);

    // Update user to admin
    await db.collection('users').doc(userId).update({
      userType: 'admin',
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log('✅ Successfully set user as admin!');
    console.log(`🔑 ${email} now has admin privileges`);

  } catch (error) {
    console.error('❌ Error setting user as admin:', error);
  } finally {
    process.exit(0);
  }
}

// Get email from command line arguments
const email = process.argv[2];
setUserAsAdmin(email);