// Quick XP status check for Izzy
// Run in Cloud Functions console or through Firebase CLI

const admin = require('firebase-admin');

// Initialize with your service account
admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: 'wordnerd-artbeat'
});

const db = admin.firestore();
const userId = 'EdH8MvWk4Ja6eoSZM59QtOaxEK43'; // Izzy's ID

async function checkXPIssue() {
  try {
    console.log('📊 Checking XP issue for Izzy...');
    
    // Get user's current XP
    const userDoc = await db.collection('users').doc(userId).get();
    const userData = userDoc.data();
    const currentXP = userData?.experiencePoints || 0;
    console.log('⚡ Current XP:', currentXP);
    
    // Get all captures
    const capturesSnapshot = await db.collection('captures')
      .where('userId', '==', userId)
      .get();
    
    console.log('📸 Total captures:', capturesSnapshot.size);
    
    // Count by status
    const statusCounts = {};
    let approvedCount = 0;
    
    capturesSnapshot.forEach(doc => {
      const data = doc.data();
      const status = data.status || 'pending';
      statusCounts[status] = (statusCounts[status] || 0) + 1;
      
      if (status === 'approved') {
        approvedCount++;
      }
    });
    
    console.log('📈 Status breakdown:', statusCounts);
    console.log('✅ Approved captures:', approvedCount);
    console.log('💰 Expected XP (approved × 50):', approvedCount * 50);
    console.log('❌ Missing XP:', (approvedCount * 50) - currentXP);
    
  } catch (error) {
    console.error('Error:', error);
  }
}

checkXPIssue();
