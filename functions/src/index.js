const { onRequest } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");
const { defineSecret } = require("firebase-functions/params");
const cors = require("cors")({ origin: true });

// Set global options for all functions
setGlobalOptions({ maxInstances: 10 });

// Define secret for Stripe
const stripeSecretKey = defineSecret("STRIPE_SECRET_KEY");

admin.initializeApp();

/**
 * Fix leaderboard data - one-time maintenance function
 */
exports.fixLeaderboardData = onRequest((request, response) => {
  cors(request, response, async () => {
    try {
      console.log("🔧 Starting leaderboard data fix...");

      // Get all users
      const usersSnapshot = await admin.firestore().collection("users").get();
      console.log(`📊 Found ${usersSnapshot.docs.length} users to process`);

      let usersUpdated = 0;
      let capturesProcessed = 0;
      let artWalksProcessed = 0;

      for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;
        const userData = userDoc.data();

        console.log(
          `\n👤 Processing user: ${
            userData.fullName || userData.username || userId
          }`
        );

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
          const createdCount = captures.length;

          for (const capture of captures) {
            if (capture && capture.status === "approved") {
              approvedCount++;
            }
          }

          // Update stats
          if (stats.capturesCreated !== createdCount) {
            updates["stats.capturesCreated"] = createdCount;
            needsUpdate = true;
            console.log(`   ✅ Setting capturesCreated: ${createdCount}`);
          }

          if (stats.capturesApproved !== approvedCount) {
            updates["stats.capturesApproved"] = approvedCount;
            needsUpdate = true;
            console.log(`   ✅ Setting capturesApproved: ${approvedCount}`);
          }

          capturesProcessed += captures.length;
        } else {
          // Ensure zero values for users with no captures
          if (stats.capturesCreated == null) {
            updates["stats.capturesCreated"] = 0;
            needsUpdate = true;
          }
          if (stats.capturesApproved == null) {
            updates["stats.capturesApproved"] = 0;
            needsUpdate = true;
          }
        }

        // Fix art walks data
        const artWalksSnapshot = await admin
          .firestore()
          .collection("artWalks")
          .where("userId", "==", userId)
          .get();

        if (!artWalksSnapshot.empty) {
          const walksCreated = artWalksSnapshot.docs.length;
          console.log(`   🎨 Found ${walksCreated} art walks created`);

          if (stats.walksCreated !== walksCreated) {
            updates["stats.walksCreated"] = walksCreated;
            needsUpdate = true;
            console.log(`   ✅ Setting walksCreated: ${walksCreated}`);
          }

          artWalksProcessed += walksCreated;
        } else {
          // Ensure zero value for users with no art walks
          if (stats.walksCreated == null) {
            updates["stats.walksCreated"] = 0;
            needsUpdate = true;
          }
        }

        // Initialize other missing stats
        if (stats.walksCompleted == null) {
          updates["stats.walksCompleted"] = 0;
          needsUpdate = true;
        }
        if (stats.reviewsSubmitted == null) {
          updates["stats.reviewsSubmitted"] = 0;
          needsUpdate = true;
        }
        if (stats.helpfulVotes == null) {
          updates["stats.helpfulVotes"] = 0;
          needsUpdate = true;
        }
        if (stats.highestRatedCapture == null) {
          updates["stats.highestRatedCapture"] = 0;
          needsUpdate = true;
        }
        if (stats.highestRatedArtWalk == null) {
          updates["stats.highestRatedArtWalk"] = 0;
          needsUpdate = true;
        }

        // Calculate expected XP
        const currentXP = userData.experiencePoints || 0;
        const capturesCreated =
          (stats.capturesCreated || 0) +
          (updates["stats.capturesCreated"] || 0);
        const capturesApproved =
          (stats.capturesApproved || 0) +
          (updates["stats.capturesApproved"] || 0);
        const walksCreated =
          (stats.walksCreated || 0) + (updates["stats.walksCreated"] || 0);
        const walksCompleted = stats.walksCompleted || 0;

        let expectedXP = 0;
        expectedXP += capturesCreated * 25; // 25 XP per capture created
        expectedXP += capturesApproved * 25; // Additional 25 XP when approved
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
          await admin
            .firestore()
            .collection("users")
            .doc(userId)
            .update(updates);
          usersUpdated++;
          console.log("   ✅ User updated successfully");
        } else {
          console.log("   ℹ️  No updates needed");
        }
      }

      const summary = {
        success: true,
        usersProcessed: usersSnapshot.docs.length,
        usersUpdated: usersUpdated,
        capturesProcessed: capturesProcessed,
        artWalksProcessed: artWalksProcessed,
      };

      console.log("\n🎉 Leaderboard data fix completed!");
      console.log("📊 Summary:", summary);

      response.status(200).send(summary);
    } catch (error) {
      console.error("❌ Error fixing leaderboard data:", error);
      response.status(500).send({ error: error.message });
    }
  });
});

/**
 * Fix specific user's data by name
 */
exports.fixUserData = onRequest((request, response) => {
  cors(request, response, async () => {
    try {
      const userName = request.body?.name || request.query?.name || "Izzy Piel";
      console.log(`🔧 Starting data fix for: ${userName}`);

      // Find user by name
      const usersSnapshot = await admin
        .firestore()
        .collection("users")
        .where("fullName", "==", userName)
        .get();

      if (usersSnapshot.empty) {
        console.log(`❌ ${userName} not found`);
        return response.status(404).send({ error: `${userName} not found` });
      }

      const userDoc = usersSnapshot.docs[0];
      const userId = userDoc.id;
      const userData = userDoc.data();

      console.log(`👤 Found ${userName}: ${userId}`);
      console.log("📊 Current data:", {
        experiencePoints: userData.experiencePoints || 0,
        level: userData.level || 1,
        stats: userData.stats || {},
      });

      // Check captures in the captures collection
      const capturesSnapshot = await admin
        .firestore()
        .collection("captures")
        .where("userId", "==", userId)
        .get();

      const captureCount = capturesSnapshot.docs.length;
      console.log(`📸 Found ${captureCount} captures in captures collection`);

      // Count approved captures
      let approvedCount = 0;
      const createdCount = capturesSnapshot.docs.length;

      for (const captureDoc of capturesSnapshot.docs) {
        const captureData = captureDoc.data();
        if (captureData.status === "approved") {
          approvedCount++;
          console.log(`   ✅ Approved capture: ${captureDoc.id}`);
        }
        console.log(
          `   📸 Capture ${captureDoc.id}: status=${captureData.status}`
        );
      }

      console.log(
        `📊 Total captures: ${createdCount}, Approved: ${approvedCount}`
      );

      // Calculate expected stats and XP
      const expectedStats = {
        capturesCreated: createdCount,
        capturesApproved: approvedCount,
        walksCreated: 0,
        walksCompleted: 0,
        reviewsSubmitted: 0,
        helpfulVotes: 0,
        highestRatedCapture: 0,
        highestRatedArtWalk: 0,
      };

      const expectedXP = createdCount * 25 + approvedCount * 25;
      const expectedLevel = calculateLevel(expectedXP);

      console.log("📊 Expected stats:", expectedStats);
      console.log(`⚡ Expected XP: ${expectedXP}`);
      console.log(`👑 Expected level: ${expectedLevel}`);

      // Update Julie's document
      const updates = {
        stats: expectedStats,
        experiencePoints: expectedXP,
        level: expectedLevel,
      };

      await admin.firestore().collection("users").doc(userId).update(updates);

      const summary = {
        success: true,
        userId: userId,
        userName: userName,
        capturesCreated: expectedStats.capturesCreated,
        capturesApproved: expectedStats.capturesApproved,
        experiencePoints: expectedXP,
        level: expectedLevel,
      };

      console.log(`✅ ${userName} data updated successfully!`);
      console.log("📊 Summary:", summary);

      response.status(200).send(summary);
    } catch (error) {
      console.error("❌ Error fixing Julie data:", error);
      response.status(500).send({ error: error.message });
    }
  });
});

/**
 * Test leaderboard queries directly
 */
exports.testLeaderboardQuery = onRequest((request, response) => {
  cors(request, response, async () => {
    try {
      console.log("🧪 Testing leaderboard queries...");

      // Test Total XP query
      console.log("Testing Total XP query...");
      const xpQuery = await admin
        .firestore()
        .collection("users")
        .orderBy("experiencePoints", "desc")
        .limit(10)
        .get();

      const xpResults = xpQuery.docs.map((doc) => ({
        id: doc.id,
        name: doc.data().fullName || doc.data().username,
        xp: doc.data().experiencePoints || 0,
      }));
      console.log("XP Results:", xpResults);

      // Test Captures Created query
      console.log("Testing Captures Created query...");
      const capturesQuery = await admin
        .firestore()
        .collection("users")
        .orderBy("stats.capturesCreated", "desc")
        .limit(10)
        .get();

      const capturesResults = capturesQuery.docs.map((doc) => ({
        id: doc.id,
        name: doc.data().fullName || doc.data().username,
        captures: (doc.data().stats || {}).capturesCreated || 0,
      }));
      console.log("Captures Results:", capturesResults);

      response.status(200).send({
        success: true,
        xpResults,
        capturesResults,
      });
    } catch (error) {
      console.error("❌ Error testing queries:", error);
      response.status(500).send({ error: error.message, stack: error.stack });
    }
  });
});

/**
 * Debug user data for leaderboard issues
 */
exports.debugUsers = onRequest((request, response) => {
  cors(request, response, async () => {
    try {
      console.log("🔍 Debugging user data...");

      // Get all users with XP > 0
      const usersSnapshot = await admin
        .firestore()
        .collection("users")
        .where("experiencePoints", ">", 0)
        .orderBy("experiencePoints", "desc")
        .get();

      console.log(`👥 Found ${usersSnapshot.docs.length} users with XP`);

      const userDebugInfo = [];
      for (const doc of usersSnapshot.docs) {
        const userData = doc.data();
        const stats = userData.stats || {};

        const userInfo = {
          id: doc.id,
          name: userData.fullName || userData.username || "Unknown",
          xp: userData.experiencePoints || 0,
          level: userData.level || 1,
          stats: {
            capturesCreated: stats.capturesCreated || 0,
            capturesApproved: stats.capturesApproved || 0,
            walksCreated: stats.walksCreated || 0,
            walksCompleted: stats.walksCompleted || 0,
            highestRatedCapture: stats.highestRatedCapture || 0,
            highestRatedArtWalk: stats.highestRatedArtWalk || 0,
          },
        };

        userDebugInfo.push(userInfo);
        console.log(
          `👤 ${userInfo.name}: XP=${userInfo.xp}, Level=${userInfo.level}`
        );
      }

      // Check art walks collection
      console.log("🚶 Checking art walks...");
      const artWalksSnapshot = await admin
        .firestore()
        .collection("artWalks")
        .get();
      console.log(`Found ${artWalksSnapshot.docs.length} art walks total`);

      const creatorCounts = {};
      const walkRatings = {};
      for (const doc of artWalksSnapshot.docs) {
        const walkData = doc.data();
        const creatorId = walkData.createdBy || walkData.userId;
        if (creatorId) {
          creatorCounts[creatorId] = (creatorCounts[creatorId] || 0) + 1;

          // Check for ratings
          if (walkData.averageRating && walkData.averageRating > 0) {
            if (
              !walkRatings[creatorId] ||
              walkData.averageRating > walkRatings[creatorId]
            ) {
              walkRatings[creatorId] = walkData.averageRating;
            }
          }
        }
      }

      console.log("Art walk creators:", creatorCounts);
      console.log("Art walk ratings:", walkRatings);

      // Check captures for ratings
      console.log("📸 Checking capture ratings...");
      const allCapturesSnapshot = await admin
        .firestore()
        .collection("captures")
        .get();
      const captureRatings = {};
      for (const doc of allCapturesSnapshot.docs) {
        const captureData = doc.data();
        const userId = captureData.userId;
        if (
          userId &&
          captureData.averageRating &&
          captureData.averageRating > 0
        ) {
          if (
            !captureRatings[userId] ||
            captureData.averageRating > captureRatings[userId]
          ) {
            captureRatings[userId] = captureData.averageRating;
          }
        }
      }
      console.log("Capture ratings:", captureRatings);

      response.status(200).send({
        success: true,
        users: userDebugInfo,
        artWalkCreators: creatorCounts,
        walkRatings: walkRatings,
        captureRatings: captureRatings,
        totalArtWalks: artWalksSnapshot.docs.length,
        totalCaptures: allCapturesSnapshot.docs.length,
      });
    } catch (error) {
      console.error("❌ Error debugging users:", error);
      response.status(500).send({ error: error.message });
    }
  });
});

// Calculate user level based on XP (matches RewardsService logic)
/**
 * Calculate user level based on experience points
 * @param {number} xp - The user's experience points
 * @return {number} The calculated level
 */
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

/**
 * Create a new customer in Stripe
 */
exports.createCustomer = onRequest(
  { secrets: [stripeSecretKey] },
  (request, response) => {
    cors(request, response, async () => {
      try {
        console.log("🔍 createCustomer called - Method:", request.method);
        console.log("🔍 Headers:", JSON.stringify(request.headers, null, 2));
        console.log("🔍 Body:", JSON.stringify(request.body, null, 2));

        // Verify Firebase Auth token
        const authHeader = request.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
          console.log("❌ No valid auth header found");
          return response.status(401).send({ error: "Unauthorized" });
        }

        const idToken = authHeader.split("Bearer ")[1];
        console.log("🔐 Token received, length:", idToken.length);

        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const authUserId = decodedToken.uid;
        console.log("✅ Auth successful for user:", authUserId);

        // Initialize Stripe with the secret
        const stripe = require("stripe")(stripeSecretKey.value());

        if (request.method !== "POST") {
          return response.status(405).send({ error: "Method Not Allowed" });
        }

        const { email, userId } = request.body;

        if (!email || !userId) {
          return response.status(400).send({
            error: "Missing required fields",
          });
        }

        // Verify the userId matches the authenticated user
        if (userId !== authUserId) {
          return response.status(403).send({ error: "Forbidden" });
        }

        // Create customer
        const customer = await stripe.customers.create({
          email,
          metadata: {
            userId,
            firebaseUserId: userId,
          },
        });

        // Return customer ID
        response.status(200).send({
          customerId: customer.id,
          success: true,
        });
      } catch (error) {
        console.error("Error creating customer:", error);
        response.status(500).send({ error: error.message });
      }
    });
  }
);

/**
 * Create a setup intent for adding payment methods
 */
exports.createSetupIntent = onRequest(
  { secrets: [stripeSecretKey] },
  (request, response) => {
    cors(request, response, async () => {
      try {
        console.log("🔍 createSetupIntent called - Method:", request.method);
        console.log("🔍 Headers:", JSON.stringify(request.headers, null, 2));
        console.log("🔍 Body:", JSON.stringify(request.body, null, 2));

        // Verify Firebase Auth token
        const authHeader = request.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
          console.log("❌ No valid auth header found");
          return response.status(401).send({ error: "Unauthorized" });
        }

        const idToken = authHeader.split("Bearer ")[1];
        console.log("🔐 Token received, length:", idToken.length);

        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const authUserId = decodedToken.uid;
        console.log("✅ Auth successful for user:", authUserId);

        const stripe = require("stripe")(stripeSecretKey.value());

        if (request.method !== "POST") {
          return response.status(405).send({ error: "Method Not Allowed" });
        }

        const { customerId } = request.body;

        if (!customerId) {
          return response.status(400).send({
            error: "Missing customer ID",
          });
        }

        const setupIntent = await stripe.setupIntents.create({
          customer: customerId,
          usage: "off_session",
        });

        response.status(200).send({
          clientSecret: setupIntent.client_secret,
          success: true,
        });
      } catch (error) {
        console.error("Error creating setup intent:", error);
        response.status(500).send({ error: error.message });
      }
    });
  }
);

/**
 * Create a payment intent for direct one-time payments
 * (no stored payment methods)
 */
exports.createPaymentIntent = onRequest(
  { secrets: [stripeSecretKey] },
  (request, response) => {
    cors(request, response, async () => {
      try {
        console.log("🔍 createPaymentIntent called - Method:", request.method);
        console.log("🔍 Headers:", JSON.stringify(request.headers, null, 2));
        console.log("🔍 Body:", JSON.stringify(request.body, null, 2));

        // Verify Firebase Auth token
        const authHeader = request.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
          console.log("❌ No valid auth header found");
          return response.status(401).send({ error: "Unauthorized" });
        }

        const idToken = authHeader.split("Bearer ")[1];
        console.log("🔐 Token received, length:", idToken.length);

        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const authUserId = decodedToken.uid;
        console.log("✅ Auth successful for user:", authUserId);

        const stripe = require("stripe")(stripeSecretKey.value());

        if (request.method !== "POST") {
          return response.status(405).send({ error: "Method Not Allowed" });
        }

        const {
          amount,
          currency = "usd",
          description,
          metadata = {},
        } = request.body;

        if (!amount || amount <= 0) {
          return response.status(400).send({
            error: "Invalid amount",
          });
        }

        // Convert amount to cents for Stripe
        const amountInCents = Math.round(amount * 100);

        console.log(
          `💰 Creating payment intent for $${amount} (${amountInCents} cents)`
        );

        const paymentIntent = await stripe.paymentIntents.create({
          amount: amountInCents,
          currency: currency,
          description: description || "ArtBeat Gift Payment",
          metadata: {
            userId: authUserId,
            ...metadata,
          },
          automatic_payment_methods: {
            enabled: true,
          },
        });

        console.log("✅ Payment intent created:", paymentIntent.id);

        response.status(200).send({
          clientSecret: paymentIntent.client_secret,
          paymentIntentId: paymentIntent.id,
          success: true,
        });
      } catch (error) {
        console.error("❌ Error creating payment intent:", error);
        response.status(500).send({ error: error.message });
      }
    });
  }
);

/**
 * Get payment methods for a customer
 */
exports.getPaymentMethods = onRequest(
  { secrets: [stripeSecretKey] },
  (request, response) => {
    cors(request, response, async () => {
      try {
        console.log("🔍 getPaymentMethods called - Method:", request.method);
        console.log("🔍 Headers:", JSON.stringify(request.headers, null, 2));
        console.log("🔍 Body:", JSON.stringify(request.body, null, 2));

        // Verify Firebase Auth token
        const authHeader = request.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
          console.log("❌ No valid auth header found");
          return response.status(401).send({ error: "Unauthorized" });
        }

        const idToken = authHeader.split("Bearer ")[1];
        console.log("🔐 Token received, length:", idToken.length);

        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const authUserId = decodedToken.uid;
        console.log("✅ Auth successful for user:", authUserId);

        const stripe = require("stripe")(stripeSecretKey.value());

        if (request.method !== "POST") {
          return response.status(405).send({ error: "Method Not Allowed" });
        }

        const { customerId } = request.body;

        if (!customerId) {
          return response.status(400).send({
            error: "Missing customer ID",
          });
        }

        console.log("🔄 Getting payment methods for customer:", customerId);
        const paymentMethods = await stripe.paymentMethods.list({
          customer: customerId,
          type: "card",
        });

        console.log("✅ Found", paymentMethods.data.length, "payment methods");
        response.status(200).send({
          paymentMethods: paymentMethods.data,
          success: true,
        });
      } catch (error) {
        console.error("❌ Error getting payment methods:", error);
        response.status(500).send({ error: error.message });
      }
    });
  }
);

/**
 * Update customer information
 */
exports.updateCustomer = onRequest(
  { secrets: [stripeSecretKey] },
  (request, response) => {
    cors(request, response, async () => {
      try {
        console.log("🔍 updateCustomer called - Method:", request.method);
        console.log("🔍 Headers:", JSON.stringify(request.headers, null, 2));
        console.log("🔍 Body:", JSON.stringify(request.body, null, 2));

        // Verify Firebase Auth token
        const authHeader = request.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
          console.log("❌ No valid auth header found");
          return response.status(401).send({ error: "Unauthorized" });
        }

        const idToken = authHeader.split("Bearer ")[1];
        console.log("🔐 Token received, length:", idToken.length);

        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const authUserId = decodedToken.uid;
        console.log("✅ Auth successful for user:", authUserId);

        const stripe = require("stripe")(stripeSecretKey.value());

        if (request.method !== "POST") {
          return response.status(405).send({ error: "Method Not Allowed" });
        }

        const { customerId, email, name, defaultPaymentMethod } = request.body;

        if (!customerId) {
          return response.status(400).send({
            error: "Missing customer ID",
          });
        }

        const updateData = {};
        if (email) updateData.email = email;
        if (name) updateData.name = name;
        if (defaultPaymentMethod) {
          updateData.invoice_settings = {
            default_payment_method: defaultPaymentMethod,
          };
        }

        const customer = await stripe.customers.update(customerId, updateData);

        response.status(200).send({
          customer,
          success: true,
        });
      } catch (error) {
        console.error("Error updating customer:", error);
        response.status(500).send({ error: error.message });
      }
    });
  }
);

/**
 * Detach a payment method from a customer
 */
exports.detachPaymentMethod = onRequest(
  { secrets: [stripeSecretKey] },
  (request, response) => {
    cors(request, response, async () => {
      try {
        console.log("🔍 detachPaymentMethod called - Method:", request.method);
        console.log("🔍 Headers:", JSON.stringify(request.headers, null, 2));
        console.log("🔍 Body:", JSON.stringify(request.body, null, 2));

        // Verify Firebase Auth token
        const authHeader = request.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
          console.log("❌ No valid auth header found");
          return response.status(401).send({ error: "Unauthorized" });
        }

        const idToken = authHeader.split("Bearer ")[1];
        console.log("🔐 Token received, length:", idToken.length);

        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const authUserId = decodedToken.uid;
        console.log("✅ Auth successful for user:", authUserId);

        const stripe = require("stripe")(stripeSecretKey.value());

        if (request.method !== "POST") {
          return response.status(405).send({ error: "Method Not Allowed" });
        }

        const { paymentMethodId } = request.body;

        if (!paymentMethodId) {
          return response.status(400).send({
            error: "Missing payment method ID",
          });
        }

        const paymentMethod = await stripe.paymentMethods.detach(
          paymentMethodId
        );

        response.status(200).send({
          paymentMethod,
          success: true,
        });
      } catch (error) {
        console.error("Error detaching payment method:", error);
        response.status(500).send({ error: error.message });
      }
    });
  }
);

/**
 * Create a subscription
 */
exports.createSubscription = onRequest(
  { secrets: [stripeSecretKey] },
  (request, response) => {
    cors(request, response, async () => {
      try {
        const stripe = require("stripe")(stripeSecretKey.value());

        if (request.method !== "POST") {
          return response.status(405).send({ error: "Method Not Allowed" });
        }

        const { customerId, priceId, paymentMethodId } = request.body;

        if (!customerId || !priceId) {
          return response.status(400).send({
            error: "Missing required fields",
          });
        }

        const subscription = await stripe.subscriptions.create({
          customer: customerId,
          items: [{ price: priceId }],
          default_payment_method: paymentMethodId,
          expand: ["latest_invoice.payment_intent"],
        });

        const clientSecret =
          subscription.latest_invoice.payment_intent?.client_secret ?? "";

        response.status(200).send({
          subscriptionId: subscription.id,
          clientSecret,
          success: true,
        });
      } catch (error) {
        console.error("Error creating subscription:", error);
        response.status(500).send({ error: error.message });
      }
    });
  }
);

/**
 * Cancel a subscription
 */
exports.cancelSubscription = onRequest(
  { secrets: [stripeSecretKey] },
  (request, response) => {
    cors(request, response, async () => {
      try {
        const stripe = require("stripe")(stripeSecretKey.value());

        if (request.method !== "POST") {
          return response.status(405).send({ error: "Method Not Allowed" });
        }

        const { subscriptionId, cancelAtPeriodEnd } = request.body;

        if (!subscriptionId) {
          return response.status(400).send({
            error: "Missing subscription ID",
          });
        }

        let subscription;
        if (cancelAtPeriodEnd) {
          subscription = await stripe.subscriptions.update(subscriptionId, {
            cancel_at_period_end: true,
          });
        } else {
          subscription = await stripe.subscriptions.cancel(subscriptionId);
        }

        response.status(200).send({
          subscription,
          success: true,
        });
      } catch (error) {
        console.error("Error canceling subscription:", error);
        response.status(500).send({ error: error.message });
      }
    });
  }
);

/**
 * Change subscription tier
 */
exports.changeSubscriptionTier = onRequest(
  { secrets: [stripeSecretKey] },
  (request, response) => {
    cors(request, response, async () => {
      try {
        const stripe = require("stripe")(stripeSecretKey.value());

        if (request.method !== "POST") {
          return response.status(405).send({ error: "Method Not Allowed" });
        }

        const { subscriptionId, newPriceId } = request.body;

        if (!subscriptionId || !newPriceId) {
          return response.status(400).send({
            error: "Missing required fields",
          });
        }

        // Get current subscription
        const subscription = await stripe.subscriptions.retrieve(
          subscriptionId
        );

        // Update subscription with new price
        const updatedSubscription = await stripe.subscriptions.update(
          subscriptionId,
          {
            items: [
              {
                id: subscription.items.data[0].id,
                price: newPriceId,
              },
            ],
            proration_behavior: "create_prorations",
          }
        );

        response.status(200).send({
          subscription: updatedSubscription,
          success: true,
        });
      } catch (error) {
        console.error("Error changing subscription tier:", error);
        response.status(500).send({ error: error.message });
      }
    });
  }
);

/**
 * Process gift payment after payment intent is confirmed
 */
exports.processGiftPayment = onRequest(
  { secrets: [stripeSecretKey] },
  (request, response) => {
    cors(request, response, async () => {
      try {
        console.log("🎁 processGiftPayment called - Method:", request.method);
        console.log("🔍 Body:", JSON.stringify(request.body, null, 2));

        // Verify Firebase Auth token
        const authHeader = request.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
          console.log("❌ No valid auth header found");
          return response.status(401).send({ error: "Unauthorized" });
        }

        const idToken = authHeader.split("Bearer ")[1];
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const authUserId = decodedToken.uid;
        console.log("✅ Auth successful for user:", authUserId);

        const stripe = require("stripe")(stripeSecretKey.value());

        if (request.method !== "POST") {
          return response.status(405).send({ error: "Method Not Allowed" });
        }

        const {
          paymentIntentId,
          recipientId,
          amount,
          giftType,
          message,
          campaignId,
          isFreeGift,
          skipPaymentValidation,
        } = request.body;

        // Check for free gift with skip validation flag
        if (isFreeGift && skipPaymentValidation) {
          console.log("🎁 Processing free gift - skipping payment validation");

          if (!recipientId || amount === undefined) {
            return response.status(400).send({
              error:
                "Missing required fields for free gift: recipientId, amount",
            });
          }

          // Skip payment intent validation for free gifts
        } else {
          // Regular paid gift validation
          if (!paymentIntentId || !recipientId || !amount) {
            return response.status(400).send({
              error:
                "Missing required fields: paymentIntentId, recipientId, amount",
            });
          }

          // Verify the payment intent was successful
          const paymentIntent = await stripe.paymentIntents.retrieve(
            paymentIntentId
          );

          if (paymentIntent.status !== "succeeded") {
            return response.status(400).send({
              error: `Payment not completed. Status: ${paymentIntent.status}`,
            });
          }
        }

        if (isFreeGift && skipPaymentValidation) {
          console.log(`✅ Free gift validated for $${amount}`);
        } else {
          console.log(`✅ Payment verified: ${paymentIntentId} for $${amount}`);
        }

        // Create gift record in Firestore
        const giftData = {
          senderId: authUserId,
          recipientId: recipientId,
          amount: amount,
          giftType: giftType || "Custom Gift",
          message: message || null,
          campaignId: campaignId || null,
          status: "completed",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
          isFreeGift: isFreeGift || false,
        };

        // Only add paymentIntentId if it exists (not for free gifts)
        if (paymentIntentId) {
          giftData.paymentIntentId = paymentIntentId;
        }

        const giftRef = await admin
          .firestore()
          .collection("gifts")
          .add(giftData);
        console.log(`🎁 Gift record created: ${giftRef.id}`);

        // Update recipient's balance
        const recipientRef = admin
          .firestore()
          .collection("users")
          .doc(recipientId);
        await admin.firestore().runTransaction(async (transaction) => {
          const recipientDoc = await transaction.get(recipientRef);
          const currentBalance = recipientDoc.data()?.balance || 0;
          const newBalance = currentBalance + amount;

          transaction.update(recipientRef, {
            balance: newBalance,
            lastGiftReceived: admin.firestore.FieldValue.serverTimestamp(),
          });
        });

        console.log(`💰 Updated recipient balance: +$${amount}`);

        // Create notification for recipient
        await admin
          .firestore()
          .collection("notifications")
          .add({
            userId: recipientId,
            type: "gift_received",
            title: "You received a gift!",
            message: `You received a ${giftType || "gift"} worth $${amount}${
              message ? ` with message: "${message}"` : ""
            }`,
            data: {
              giftId: giftRef.id,
              senderId: authUserId,
              amount: amount,
              giftType: giftType,
            },
            read: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });

        console.log("📱 Notification sent to recipient");

        response.status(200).send({
          success: true,
          giftId: giftRef.id,
          message: "Gift sent successfully!",
        });
      } catch (error) {
        console.error("❌ Error processing gift payment:", error);
        response.status(500).send({ error: error.message });
      }
    });
  }
);

/**
 * Process subscription payment after payment intent is confirmed
 */
exports.processSubscriptionPayment = onRequest(
  { secrets: [stripeSecretKey] },
  (request, response) => {
    cors(request, response, async () => {
      try {
        console.log("💳 processSubscriptionPayment called");
        console.log("🔍 Body:", JSON.stringify(request.body, null, 2));

        // Verify Firebase Auth token
        const authHeader = request.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
          return response.status(401).send({ error: "Unauthorized" });
        }

        const idToken = authHeader.split("Bearer ")[1];
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const authUserId = decodedToken.uid;

        const stripe = require("stripe")(stripeSecretKey.value());

        if (request.method !== "POST") {
          return response.status(405).send({ error: "Method Not Allowed" });
        }

        const { paymentIntentId, tier, priceAmount, billingCycle } =
          request.body;

        if (!paymentIntentId || !tier || !priceAmount) {
          return response.status(400).send({
            error:
              "Missing required fields: paymentIntentId, tier, priceAmount",
          });
        }

        // Verify the payment intent was successful
        const paymentIntent = await stripe.paymentIntents.retrieve(
          paymentIntentId
        );

        if (paymentIntent.status !== "succeeded") {
          return response.status(400).send({
            error: `Payment not completed. Status: ${paymentIntent.status}`,
          });
        }

        console.log(
          `✅ Payment verified: ${paymentIntentId} for $${priceAmount}`
        );

        // Create subscription record in Firestore
        const subscriptionData = {
          userId: authUserId,
          tier: tier,
          priceAmount: priceAmount,
          billingCycle: billingCycle || "monthly",
          paymentIntentId: paymentIntentId,
          status: "active",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          nextBillingDate: admin.firestore.FieldValue.serverTimestamp(),
        };

        const subscriptionRef = await admin
          .firestore()
          .collection("subscriptions")
          .add(subscriptionData);
        console.log(`💳 Subscription record created: ${subscriptionRef.id}`);

        // Update user's subscription status
        await admin.firestore().collection("users").doc(authUserId).update({
          subscriptionTier: tier,
          subscriptionStatus: "active",
          subscriptionId: subscriptionRef.id,
          lastPayment: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log("👤 User subscription status updated");

        response.status(200).send({
          success: true,
          subscriptionId: subscriptionRef.id,
          message: "Subscription activated successfully!",
        });
      } catch (error) {
        console.error("❌ Error processing subscription payment:", error);
        response.status(500).send({ error: error.message });
      }
    });
  }
);

/**
 * Process ad payment after payment intent is confirmed
 */
exports.processAdPayment = onRequest(
  { secrets: [stripeSecretKey] },
  (request, response) => {
    cors(request, response, async () => {
      try {
        console.log("📢 processAdPayment called");
        console.log("🔍 Body:", JSON.stringify(request.body, null, 2));

        // Verify Firebase Auth token
        const authHeader = request.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
          return response.status(401).send({ error: "Unauthorized" });
        }

        const idToken = authHeader.split("Bearer ")[1];
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const authUserId = decodedToken.uid;

        const stripe = require("stripe")(stripeSecretKey.value());

        if (request.method !== "POST") {
          return response.status(405).send({ error: "Method Not Allowed" });
        }

        const {
          paymentIntentId,
          adType,
          duration,
          amount,
          targetAudience,
          adContent,
        } = request.body;

        if (!paymentIntentId || !adType || !duration || !amount) {
          return response.status(400).send({
            error:
              "Missing required fields: paymentIntentId, adType, " +
              "duration, amount",
          });
        }

        // Verify the payment intent was successful
        const paymentIntent = await stripe.paymentIntents.retrieve(
          paymentIntentId
        );

        if (paymentIntent.status !== "succeeded") {
          return response.status(400).send({
            error: `Payment not completed. Status: ${paymentIntent.status}`,
          });
        }

        console.log(`✅ Payment verified: ${paymentIntentId} for $${amount}`);

        // Create ad record in Firestore
        const adData = {
          userId: authUserId,
          adType: adType,
          duration: duration,
          amount: amount,
          targetAudience: targetAudience || {},
          adContent: adContent || {},
          paymentIntentId: paymentIntentId,
          status: "active",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          startDate: admin.firestore.FieldValue.serverTimestamp(),
          endDate: new Date(Date.now() + duration * 24 * 60 * 60 * 1000),
          // duration in days
        };

        const adRef = await admin
          .firestore()
          .collection("advertisements")
          .add(adData);
        console.log(`📢 Ad record created: ${adRef.id}`);

        response.status(200).send({
          success: true,
          adId: adRef.id,
          message: "Advertisement activated successfully!",
        });
      } catch (error) {
        console.error("❌ Error processing ad payment:", error);
        response.status(500).send({ error: error.message });
      }
    });
  }
);

/**
 * Process sponsorship payment after payment intent is confirmed
 */
exports.processSponsorshipPayment = onRequest(
  { secrets: [stripeSecretKey] },
  (request, response) => {
    cors(request, response, async () => {
      try {
        console.log("🤝 processSponsorshipPayment called");
        console.log("🔍 Body:", JSON.stringify(request.body, null, 2));

        // Verify Firebase Auth token
        const authHeader = request.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
          return response.status(401).send({ error: "Unauthorized" });
        }

        const idToken = authHeader.split("Bearer ")[1];
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const authUserId = decodedToken.uid;

        const stripe = require("stripe")(stripeSecretKey.value());

        if (request.method !== "POST") {
          return response.status(405).send({ error: "Method Not Allowed" });
        }

        const {
          paymentIntentId,
          artistId,
          amount,
          sponsorshipType,
          duration,
          benefits,
        } = request.body;

        if (!paymentIntentId || !artistId || !amount || !sponsorshipType) {
          return response.status(400).send({
            error:
              "Missing required fields: paymentIntentId, artistId, " +
              "amount, sponsorshipType",
          });
        }

        // Verify the payment intent was successful
        const paymentIntent = await stripe.paymentIntents.retrieve(
          paymentIntentId
        );

        if (paymentIntent.status !== "succeeded") {
          return response.status(400).send({
            error: `Payment not completed. Status: ${paymentIntent.status}`,
          });
        }

        console.log(`✅ Payment verified: ${paymentIntentId} for $${amount}`);

        // Create sponsorship record in Firestore
        const sponsorshipData = {
          sponsorId: authUserId,
          artistId: artistId,
          amount: amount,
          sponsorshipType: sponsorshipType,
          duration: duration || 30, // default 30 days
          benefits: benefits || [],
          paymentIntentId: paymentIntentId,
          status: "active",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          startDate: admin.firestore.FieldValue.serverTimestamp(),
          endDate: new Date(
            Date.now() + (duration || 30) * 24 * 60 * 60 * 1000
          ),
        };

        const sponsorshipRef = await admin
          .firestore()
          .collection("sponsorships")
          .add(sponsorshipData);
        console.log(`🤝 Sponsorship record created: ${sponsorshipRef.id}`);

        // Update artist's balance (they get 80% of sponsorship)
        const artistShare = amount * 0.8;
        const artistRef = admin.firestore().collection("users").doc(artistId);
        await admin.firestore().runTransaction(async (transaction) => {
          const artistDoc = await transaction.get(artistRef);
          const currentBalance = artistDoc.data()?.balance || 0;
          const newBalance = currentBalance + artistShare;

          transaction.update(artistRef, {
            balance: newBalance,
            lastSponsorshipReceived:
              admin.firestore.FieldValue.serverTimestamp(),
          });
        });

        console.log(`💰 Updated artist balance: +$${artistShare}`);

        // Create notification for artist
        await admin
          .firestore()
          .collection("notifications")
          .add({
            userId: artistId,
            type: "sponsorship_received",
            title: "New Sponsorship!",
            message:
              `You received a ${sponsorshipType} sponsorship ` +
              `worth $${amount}`,
            data: {
              sponsorshipId: sponsorshipRef.id,
              sponsorId: authUserId,
              amount: amount,
              sponsorshipType: sponsorshipType,
            },
            read: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });

        response.status(200).send({
          success: true,
          sponsorshipId: sponsorshipRef.id,
          message: "Sponsorship activated successfully!",
        });
      } catch (error) {
        console.error("❌ Error processing sponsorship payment:", error);
        response.status(500).send({ error: error.message });
      }
    });
  }
);

/**
 * Process commission payment after payment intent is confirmed
 */
exports.processCommissionPayment = onRequest(
  { secrets: [stripeSecretKey] },
  (request, response) => {
    cors(request, response, async () => {
      try {
        console.log("🎨 processCommissionPayment called");
        console.log("🔍 Body:", JSON.stringify(request.body, null, 2));

        // Verify Firebase Auth token
        const authHeader = request.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
          return response.status(401).send({ error: "Unauthorized" });
        }

        const idToken = authHeader.split("Bearer ")[1];
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const authUserId = decodedToken.uid;

        const stripe = require("stripe")(stripeSecretKey.value());

        if (request.method !== "POST") {
          return response.status(405).send({ error: "Method Not Allowed" });
        }

        const {
          paymentIntentId,
          artistId,
          amount,
          commissionType,
          description,
          deadline,
        } = request.body;

        if (!paymentIntentId || !artistId || !amount || !commissionType) {
          return response.status(400).send({
            error:
              "Missing required fields: paymentIntentId, artistId, " +
              "amount, commissionType",
          });
        }

        // Verify the payment intent was successful
        const paymentIntent = await stripe.paymentIntents.retrieve(
          paymentIntentId
        );

        if (paymentIntent.status !== "succeeded") {
          return response.status(400).send({
            error: `Payment not completed. Status: ${paymentIntent.status}`,
          });
        }

        console.log(`✅ Payment verified: ${paymentIntentId} for $${amount}`);

        // Create commission record in Firestore
        const commissionData = {
          clientId: authUserId,
          artistId: artistId,
          amount: amount,
          commissionType: commissionType,
          description: description || "",
          deadline: deadline || null,
          paymentIntentId: paymentIntentId,
          status: "pending", // Artist needs to accept
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          paymentHeld: true, // Payment is held until completion
        };

        const commissionRef = await admin
          .firestore()
          .collection("commissions")
          .add(commissionData);
        console.log(`🎨 Commission record created: ${commissionRef.id}`);

        // Create notification for artist
        await admin
          .firestore()
          .collection("notifications")
          .add({
            userId: artistId,
            type: "commission_request",
            title: "New Commission Request!",
            message:
              `You have a new ${commissionType} commission request ` +
              `worth $${amount}`,
            data: {
              commissionId: commissionRef.id,
              clientId: authUserId,
              amount: amount,
              commissionType: commissionType,
            },
            read: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });

        response.status(200).send({
          success: true,
          commissionId: commissionRef.id,
          message: "Commission request sent successfully!",
        });
      } catch (error) {
        console.error("❌ Error processing commission payment:", error);
        response.status(500).send({ error: error.message });
      }
    });
  }
);

/**
 * Request a refund
 */
exports.requestRefund = onRequest(
  { secrets: [stripeSecretKey] },
  (request, response) => {
    cors(request, response, async () => {
      try {
        const stripe = require("stripe")(stripeSecretKey.value());

        if (request.method !== "POST") {
          return response.status(405).send({ error: "Method Not Allowed" });
        }

        const { paymentId, subscriptionId, userId, reason, additionalDetails } =
          request.body;

        if (!paymentId || !userId || !reason) {
          return response.status(400).send({
            error: "Missing required fields",
          });
        }

        // Create refund in Stripe
        const refund = await stripe.refunds.create({
          payment_intent: paymentId,
          reason: "requested_by_customer",
          metadata: {
            userId,
            subscriptionId: subscriptionId || "",
            refundReason: reason,
            additionalDetails: additionalDetails || "",
          },
        });

        // Store refund request in Firestore
        await admin
          .firestore()
          .collection("refundRequests")
          .add({
            userId,
            paymentId,
            subscriptionId: subscriptionId || null,
            reason,
            additionalDetails: additionalDetails || "",
            stripeRefundId: refund.id,
            status: "pending",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });

        response.status(200).send({
          refundId: refund.id,
          success: true,
        });
      } catch (error) {
        console.error("Error requesting refund:", error);
        response.status(500).send({ error: error.message });
      }
    });
  }
);
