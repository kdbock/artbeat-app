// Simple script to set admin user using Firebase Admin SDK
const admin = require('firebase-admin');

// Initialize with application default credentials
try {
  admin.initializeApp({
    projectId: 'wordnerd-artbeat'
  });
} catch (error) {
  console.log('Firebase already initialized or error:', error.message);
}

const db = admin.firestore();

async function setUserAsAdmin(email) {
  try {
    if (!email) {
      console.error('❌ Please provide an email address');
      console.log('Usage: node set_admin_simple.js <email>');
      process.exit(1);
    }

    console.log(`🔍 Looking for user with email: ${email}`);

    // Find user by email
    const usersSnapshot = await db.collection('users')
      .where('email', '==', email)
      .limit(1)
      .get();

    if (usersSnapshot.empty) {
      console.error(`❌ No user found with email: ${email}`);
      console.log('');
      console.log('📋 Manual steps to set admin privileges:');
      console.log('1. Go to Firebase Console: https://console.firebase.google.com/project/wordnerd-artbeat/firestore');
      console.log('2. Navigate to the "users" collection');
      console.log(`3. Find the document with email: ${email}`);
      console.log('4. Edit the document and set the "userType" field to "admin"');
      console.log('5. Save the changes');
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
    console.log('🔄 Please restart your app to see the admin features.');

  } catch (error) {
    console.error('❌ Error setting user as admin:', error.message);
    console.log('');
    console.log('📋 Manual steps to set admin privileges:');
    console.log('1. Go to Firebase Console: https://console.firebase.google.com/project/wordnerd-artbeat/firestore');
    console.log('2. Navigate to the "users" collection');
    console.log(`3. Find the document with email: ${email}`);
    console.log('4. Edit the document and set the "userType" field to "admin"');
    console.log('5. Save the changes');
  } finally {
    process.exit(0);
  }
}

// Get email from command line arguments
const email = process.argv[2];
setUserAsAdmin(email);