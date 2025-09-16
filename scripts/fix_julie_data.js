const admin = require('firebase-admin');

// Initialize Firebase Admin (assumes running in Firebase environment)
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

async function fixJulieData() {
  console.log('🔧 Starting Julie data fix...');

  try {
    // Find Julie by name
    const usersSnapshot = await db.collection('users')
      .where('fullName', '==', 'Julie Babbin')
      .get();

    if (usersSnapshot.empty) {
      console.log('❌ Julie Babbin not found');
      return;
    }

    const julieDoc = usersSnapshot.docs[0];
    const julieId = julieDoc.id;
    const julieData = julieDoc.data();
    
    console.log(`👤 Found Julie: ${julieId}`);
    console.log(`📊 Current data:`, {
      experiencePoints: julieData.experiencePoints || 0,
      level: julieData.level || 1,
      stats: julieData.stats || {}
    });

    // Check her captures
    const captures = julieData.captures || [];
    console.log(`📸 Found ${captures.length} captures in user document`);

    // Count approved captures
    let approvedCount = 0;
    for (const capture of captures) {
      if (capture && capture.status === 'approved') {
        approvedCount++;
        console.log(`   ✅ Approved capture: ${capture.id || 'unknown'}`);
      }
    }

    console.log(`📊 Approved captures: ${approvedCount}`);

    // Calculate expected stats and XP
    const expectedStats = {
      capturesCreated: captures.length,
      capturesApproved: approvedCount,
      walksCreated: 0,
      walksCompleted: 0,
      reviewsSubmitted: 0,
      helpfulVotes: 0,
      highestRatedCapture: 0,
      highestRatedArtWalk: 0
    };

    const expectedXP = (captures.length * 25) + (approvedCount * 25);
    const expectedLevel = calculateLevel(expectedXP);

    console.log(`📊 Expected stats:`, expectedStats);
    console.log(`⚡ Expected XP: ${expectedXP}`);
    console.log(`👑 Expected level: ${expectedLevel}`);

    // Update Julie's document
    const updates = {
      stats: expectedStats,
      experiencePoints: expectedXP,
      level: expectedLevel
    };

    await db.collection('users').doc(julieId).update(updates);
    
    console.log('✅ Julie data updated successfully!');
    console.log('📊 Summary:', {
      userId: julieId,
      capturesCreated: expectedStats.capturesCreated,
      capturesApproved: expectedStats.capturesApproved,
      experiencePoints: expectedXP,
      level: expectedLevel
    });

  } catch (error) {
    console.error('❌ Error fixing Julie data:', error);
    process.exit(1);
  }
}

// Calculate user level based on XP (matches RewardsService logic)
function calculateLevel(xp) {
  const levelSystem = {
    1: { minXP: 0, maxXP: 199 },
    2: { minXP: 200, maxXP: 499 },
    3: { minXP: 500, maxXP: 999 },
    4: { minXP: 1000, maxXP: 1499 },
    5: { minXP: 1500, maxXP: 2499 },
    6: { minXP: 2500, maxXP: 3999 },
    7: { minXP: 4000, maxXP: 5999 },
    8: { minXP: 6000, maxXP: 7999 },
    9: { minXP: 8000, maxXP: 9999 },
    10: { minXP: 10000, maxXP: 999999 },
  };

  for (let level = 10; level >= 1; level--) {
    const levelData = levelSystem[level];
    if (xp >= levelData.minXP) {
      return level;
    }
  }
  return 1;
}

// Run the fix
fixJulieData();