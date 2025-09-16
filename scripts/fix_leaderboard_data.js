const admin = require('firebase-admin');

// Initialize Firebase Admin (assumes running in Firebase environment)
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

async function fixLeaderboardData() {
  console.log('🔧 Starting leaderboard data fix...');

  try {
    // Get all users
    const usersSnapshot = await db.collection('users').get();
    console.log(`📊 Found ${usersSnapshot.docs.length} users to process`);

    let usersUpdated = 0;
    let capturesProcessed = 0;
    let artWalksProcessed = 0;

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const userData = userDoc.data();
      
      console.log(`\n👤 Processing user: ${userData.fullName || userData.username || userId}`);

      // Initialize stats if missing
      const stats = userData.stats || {};
      let needsUpdate = false;
      const updates = {};

      // Fix captures data
      const captures = userData.captures || [];
      if (captures.length > 0) {
        console.log(`   📸 Found ${captures.length} captures`);
        
        // Count approved captures
        let approvedCount = 0;
        let createdCount = captures.length;
        
        for (const capture of captures) {
          if (capture && capture.status === 'approved') {
            approvedCount++;
          }
        }

        // Update stats
        if (stats.capturesCreated !== createdCount) {
          updates['stats.capturesCreated'] = createdCount;
          needsUpdate = true;
          console.log(`   ✅ Setting capturesCreated: ${createdCount}`);
        }

        if (stats.capturesApproved !== approvedCount) {
          updates['stats.capturesApproved'] = approvedCount;
          needsUpdate = true;
          console.log(`   ✅ Setting capturesApproved: ${approvedCount}`);
        }

        capturesProcessed += captures.length;
      } else {
        // Ensure zero values for users with no captures
        if (stats.capturesCreated == null) {
          updates['stats.capturesCreated'] = 0;
          needsUpdate = true;
        }
        if (stats.capturesApproved == null) {
          updates['stats.capturesApproved'] = 0;
          needsUpdate = true;
        }
      }

      // Fix art walks data
      const artWalksSnapshot = await db
          .collection('artWalks')
          .where('userId', '==', userId)
          .get();
      
      if (!artWalksSnapshot.empty) {
        const walksCreated = artWalksSnapshot.docs.length;
        console.log(`   🎨 Found ${walksCreated} art walks created`);
        
        if (stats.walksCreated !== walksCreated) {
          updates['stats.walksCreated'] = walksCreated;
          needsUpdate = true;
          console.log(`   ✅ Setting walksCreated: ${walksCreated}`);
        }
        
        artWalksProcessed += walksCreated;
      } else {
        // Ensure zero value for users with no art walks
        if (stats.walksCreated == null) {
          updates['stats.walksCreated'] = 0;
          needsUpdate = true;
        }
      }

      // Initialize other missing stats
      if (stats.walksCompleted == null) {
        updates['stats.walksCompleted'] = 0;
        needsUpdate = true;
      }
      if (stats.reviewsSubmitted == null) {
        updates['stats.reviewsSubmitted'] = 0;
        needsUpdate = true;
      }
      if (stats.helpfulVotes == null) {
        updates['stats.helpfulVotes'] = 0;
        needsUpdate = true;
      }
      if (stats.highestRatedCapture == null) {
        updates['stats.highestRatedCapture'] = 0;
        needsUpdate = true;
      }
      if (stats.highestRatedArtWalk == null) {
        updates['stats.highestRatedArtWalk'] = 0;
        needsUpdate = true;
      }

      // Calculate expected XP
      const currentXP = userData.experiencePoints || 0;
      const capturesCreated = (stats.capturesCreated || 0) + (updates['stats.capturesCreated'] || 0);
      const capturesApproved = (stats.capturesApproved || 0) + (updates['stats.capturesApproved'] || 0);
      const walksCreated = (stats.walksCreated || 0) + (updates['stats.walksCreated'] || 0);
      const walksCompleted = stats.walksCompleted || 0;

      let expectedXP = 0;
      expectedXP += capturesCreated * 25; // 25 XP per capture created
      expectedXP += capturesApproved * 25; // Additional 25 XP when approved (total 50)
      expectedXP += walksCreated * 75; // 75 XP per art walk created
      expectedXP += walksCompleted * 100; // 100 XP per art walk completed

      if (currentXP !== expectedXP) {
        updates.experiencePoints = expectedXP;
        needsUpdate = true;
        console.log(`   ⚡ Updating XP: ${currentXP} → ${expectedXP}`);
        
        // Recalculate level
        const newLevel = calculateLevel(expectedXP);
        const currentLevel = userData.level || 1;
        if (newLevel !== currentLevel) {
          updates.level = newLevel;
          console.log(`   👑 Updating level: ${currentLevel} → ${newLevel}`);
        }
      }

      // Apply updates if needed
      if (needsUpdate) {
        await db.collection('users').doc(userId).update(updates);
        usersUpdated++;
        console.log('   ✅ User updated successfully');
      } else {
        console.log('   ℹ️  No updates needed');
      }
    }

    console.log('\n🎉 Leaderboard data fix completed!');
    console.log('📊 Summary:');
    console.log(`   - Users processed: ${usersSnapshot.docs.length}`);
    console.log(`   - Users updated: ${usersUpdated}`);
    console.log(`   - Captures processed: ${capturesProcessed}`);
    console.log(`   - Art walks processed: ${artWalksProcessed}`);

  } catch (error) {
    console.error('❌ Error fixing leaderboard data:', error);
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
fixLeaderboardData();