import * as functions from "firebase-functions";
import {onSchedule} from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import cors from "cors";
// eslint-disable-next-line @typescript-eslint/no-var-requires
const stripe = require("stripe")(functions.config().stripe.secret_key);
const corsHandler = cors({origin: true});

admin.initializeApp();

/**
 * Create a new customer in Stripe
 */
export const createCustomer = functions.https.onRequest((request, response) => {
  return corsHandler(request, response, async () => {
    try {
      if (request.method !== "POST") {
        return response.status(405).send({error: "Method Not Allowed"});
      }

      const {email, userId} = request.body;

      if (!email || !userId) {
        return response.status(400).send({
          error: "Missing required fields",
        });
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
      return response.status(200).send({
        customerId: customer.id,
        success: true,
      });
    } catch (error) {
      console.error("Error creating customer:", error);
      return response.status(500).send({error: (error as Error).message});
    }
  });
});

/**
 * Create a setup intent for adding payment methods
 */
export const createSetupIntent = functions.https.onRequest(
  (request, response) => {
    return corsHandler(request, response, async () => {
      try {
        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {customerId} = request.body;

        if (!customerId) {
          return response.status(400).send({
            error: "Missing customerId",
          });
        }

        const setupIntent = await stripe.setupIntents.create({
          customer: customerId,
          payment_method_types: ["card"],
        });

        return response.status(200).send({
          clientSecret: setupIntent.client_secret,
        });
      } catch (error) {
        console.error("Error creating setup intent:", error);
        return response.status(500).send({error: (error as Error).message});
      }
    });
  });

/**
 * Get customer's saved payment methods
 */
export const getPaymentMethods = functions.https.onRequest(
  (request, response) => {
    return corsHandler(request, response, async () => {
      try {
        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {customerId} = request.body;

        if (!customerId) {
          return response.status(400).send({
            error: "Missing customerId",
          });
        }

        const paymentMethods = await stripe.paymentMethods.list({
          customer: customerId,
          type: "card",
        });

        return response.status(200).send({
          paymentMethods: paymentMethods.data,
        });
      } catch (error) {
        console.error("Error getting payment methods:", error);
        return response.status(500).send({error: (error as Error).message});
      }
    });
  });

/**
 * Update customer (e.g., set default payment method)
 */
export const updateCustomer = functions.https.onRequest((request, response) => {
  return corsHandler(request, response, async () => {
    try {
      if (request.method !== "POST") {
        return response.status(405).send({error: "Method Not Allowed"});
      }

      const {customerId, defaultPaymentMethod} = request.body;

      if (!customerId) {
        return response.status(400).send({
          error: "Missing customerId",
        });
      }

      const customer = await stripe.customers.update(
        customerId,
        {
          invoice_settings: {
            default_payment_method: defaultPaymentMethod,
          },
        }
      );

      return response.status(200).send({
        customer: customer.id,
        success: true,
      });
    } catch (error) {
      console.error("Error updating customer:", error);
      return response.status(500).send({error: (error as Error).message});
    }
  });
});

/**
 * Detach a payment method from a customer
 */
export const detachPaymentMethod = functions.https.onRequest(
  (request, response) => {
    return corsHandler(request, response, async () => {
      try {
        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {paymentMethodId} = request.body;

        if (!paymentMethodId) {
          return response.status(400).send({
            error: "Missing paymentMethodId",
          });
        }

        const paymentMethod = await stripe.paymentMethods.detach(
          paymentMethodId
        );

        return response.status(200).send({
          paymentMethod: paymentMethod.id,
          success: true,
        });
      } catch (error) {
        console.error("Error detaching payment method:", error);
        return response.status(500).send({error: (error as Error).message});
      }
    });
  });

/**
 * Create subscription in Stripe
 */
export const createSubscription = functions.https.onRequest(
  (request, response) => {
    return corsHandler(request, response, async () => {
      try {
        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {customerId, priceId, userId} = request.body;

        if (!customerId || !priceId || !userId) {
          return response.status(400).send({
            error: "Missing required parameters",
          });
        }

        // Create subscription
        const subscription = await stripe.subscriptions.create({
          customer: customerId,
          items: [{price: priceId}],
          payment_behavior: "default_incomplete",
          expand: ["latest_invoice.payment_intent"],
          metadata: {
            userId,
            firebaseUserId: userId,
          },
        });

        // Return subscription details
        return response.status(200).send({
          subscriptionId: subscription.id,
          status: subscription.status,
          clientSecret: subscription.latest_invoice.payment_intent
            ?.client_secret ?? "",
        });
      } catch (error) {
        console.error("Error creating subscription:", error);
        return response.status(500).send({error: (error as Error).message});
      }
    });
  });

/**
 * Cancel subscription in Stripe
 */
export const cancelSubscription = functions.https.onRequest(
  (request, response) => {
    return corsHandler(request, response, async () => {
      try {
        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {subscriptionId} = request.body;

        if (!subscriptionId) {
          return response.status(400).send({
            error: "Missing subscription ID",
          });
        }

        // Cancel at period end to avoid immediate cancellation
        const subscription = await stripe.subscriptions.update(
          subscriptionId,
          {cancel_at_period_end: true}
        );

        // Return cancellation details
        return response.status(200).send({
          subscriptionId: subscription.id,
          status: subscription.status,
          cancelAtPeriodEnd: subscription.cancel_at_period_end,
        });
      } catch (error) {
        console.error("Error cancelling subscription:", error);
        return response.status(500).send({error: (error as Error).message});
      }
    });
  });

/**
 * Change subscription tier
 */
export const changeSubscriptionTier = functions.https.onRequest(
  (request, response) => {
    return corsHandler(request, response, async () => {
      try {
        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {subscriptionId, newPriceId, userId, prorated} = request.body;

        if (!subscriptionId || !newPriceId || !userId) {
          return response.status(400).send({
            error: "Missing required parameters",
          });
        }

        // Get current subscription to verify ownership
        const subscription = await stripe.subscriptions.retrieve(
          subscriptionId
        );
        if (subscription.metadata.userId !== userId) {
          return response.status(403).send({
            error: "Not authorized to modify this subscription",
          });
        }

        // Get subscription item ID
        const subscriptionItemId = subscription.items.data[0].id;

        // Update subscription with new price
        const updatedSubscription = await stripe.subscriptions.update(
          subscriptionId,
          {
            items: [
              {
                id: subscriptionItemId,
                price: newPriceId,
              },
            ],
            proration_behavior: prorated ? "create_prorations" : "none",
            metadata: {
              userId,
              firebaseUserId: userId,
              updatedAt: new Date().toISOString(),
            },
          }
        );

        return response.status(200).send({
          subscriptionId: updatedSubscription.id,
          status: updatedSubscription.status,
        });
      } catch (error) {
        console.error("Error changing subscription tier:", error);
        return response.status(500).send({error: (error as Error).message});
      }
    });
  });

/**
 * Request a refund
 */
export const requestRefund = functions.https.onRequest((request, response) => {
  return corsHandler(request, response, async () => {
    try {
      if (request.method !== "POST") {
        return response.status(405).send({error: "Method Not Allowed"});
      }

      const {
        paymentId,
        subscriptionId,
        userId,
        reason,
        additionalDetails,
      } = request.body;

      if (!paymentId || !subscriptionId || !userId || !reason) {
        return response.status(400).send({
          error: "Missing required parameters",
        });
      }

      // Verify subscription ownership
      const subscription = await stripe.subscriptions.retrieve(subscriptionId);
      if (subscription.metadata.userId !== userId) {
        return response.status(403).send({
          error: "Not authorized to request refund for this subscription",
        });
      }

      // Create refund
      const refund = await stripe.refunds.create({
        payment_intent: paymentId,
        metadata: {
          userId,
          subscriptionId,
          reason,
          additionalDetails: additionalDetails || "",
        },
      });

      // Cancel subscription if active
      if (["active", "trialing"].includes(subscription.status)) {
        await stripe.subscriptions.cancel(subscriptionId, {
          invoice_now: false,
          prorate: true,
        });
      }

      return response.status(200).send({
        refundId: refund.id,
        status: refund.status,
      });
    } catch (error) {
      console.error("Error processing refund request:", error);
      return response.status(500).send({error: (error as Error).message});
    }
  });
});

/**
 * Process custom gift payment with flexible amounts
 */
export const processCustomGiftPayment = functions.https.onRequest(
  (request, response) => {
    return corsHandler(request, response, async () => {
      try {
        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {senderId, recipientId, amount, paymentMethodId, message} = request.body;

        if (!senderId || !recipientId || !amount || !paymentMethodId) {
          return response.status(400).send({
            error: "Missing required parameters",
          });
        }

        // Validate amount (minimum $1, maximum $1000)
        if (amount < 1 || amount > 1000) {
          return response.status(400).send({
            error: "Amount must be between $1.00 and $1,000.00",
          });
        }

        // Create payment intent
        const paymentIntent = await stripe.paymentIntents.create({
          amount: Math.round(amount * 100), // Convert to cents
          currency: "usd",
          payment_method: paymentMethodId,
          confirm: true,
          return_url: "https://artbeat.app/payment-return",
          metadata: {
            type: "custom_gift",
            senderId,
            recipientId,
            message: message || "",
          },
        });

        // Update artist earnings if payment succeeded
        if (paymentIntent.status === "succeeded") {
          const artistEarningsRef = admin.firestore()
            .collection("artist_earnings")
            .doc(recipientId);

          await admin.firestore().runTransaction(async (transaction) => {
            const earningsDoc = await transaction.get(artistEarningsRef);
            
            if (earningsDoc.exists) {
              transaction.update(artistEarningsRef, {
                giftEarnings: admin.firestore.FieldValue.increment(amount),
                totalEarnings: admin.firestore.FieldValue.increment(amount),
                lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
              });
            } else {
              transaction.set(artistEarningsRef, {
                artistId: recipientId,
                giftEarnings: amount,
                sponsorshipEarnings: 0,
                commissionEarnings: 0,
                totalEarnings: amount,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
              });
            }
          });
        }

        return response.status(200).send({
          paymentIntentId: paymentIntent.id,
          status: paymentIntent.status,
          clientSecret: paymentIntent.client_secret,
        });
      } catch (error) {
        console.error("Error processing custom gift payment:", error);
        return response.status(500).send({error: (error as Error).message});
      }
    });
  });

/**
 * Create a gift subscription for recurring payments
 */
export const createGiftSubscription = functions.https.onRequest(
  (request, response) => {
    return corsHandler(request, response, async () => {
      try {
        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {senderId, recipientId, amount, interval, intervalCount, paymentMethodId} = request.body;

        if (!senderId || !recipientId || !amount || !interval || !paymentMethodId) {
          return response.status(400).send({
            error: "Missing required parameters",
          });
        }

        // Get or create customer
        const senderDoc = await admin.firestore()
          .collection("users")
          .doc(senderId)
          .get();

        if (!senderDoc.exists) {
          return response.status(404).send({error: "Sender not found"});
        }

        const senderData = senderDoc.data();
        let customerId = senderData?.stripeCustomerId;

        if (!customerId) {
          const customer = await stripe.customers.create({
            email: senderData?.email || "",
            metadata: {
              userId: senderId,
              firebaseUserId: senderId,
            },
          });
          customerId = customer.id;

          // Update user document with customer ID
          await admin.firestore()
            .collection("users")
            .doc(senderId)
            .update({
              stripeCustomerId: customerId,
            });
        }

        // Create product and price for this specific gift subscription
        const product = await stripe.products.create({
          name: `Gift Subscription - $${amount}`,
          metadata: {
            type: "gift_subscription",
            senderId,
            recipientId,
          },
        });

        const price = await stripe.prices.create({
          product: product.id,
          unit_amount: Math.round(amount * 100), // Convert to cents
          currency: "usd",
          recurring: {
            interval: interval as "week" | "month",
            interval_count: intervalCount || 1,
          },
        });

        // Create subscription
        const subscription = await stripe.subscriptions.create({
          customer: customerId,
          items: [{price: price.id}],
          payment_behavior: "default_incomplete",
          default_payment_method: paymentMethodId,
          expand: ["latest_invoice.payment_intent"],
          metadata: {
            type: "gift_subscription",
            senderId,
            recipientId,
          },
        });

        return response.status(200).send({
          subscriptionId: subscription.id,
          status: subscription.status,
          clientSecret: subscription.latest_invoice?.payment_intent?.client_secret,
        });
      } catch (error) {
        console.error("Error creating gift subscription:", error);
        return response.status(500).send({error: (error as Error).message});
      }
    });
  });

/**
 * Pause a gift subscription
 */
export const pauseGiftSubscription = functions.https.onRequest(
  (request, response) => {
    return corsHandler(request, response, async () => {
      try {
        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {subscriptionId} = request.body;

        if (!subscriptionId) {
          return response.status(400).send({
            error: "Missing subscriptionId",
          });
        }

        // Pause subscription in Stripe
        const subscription = await stripe.subscriptions.update(subscriptionId, {
          pause_collection: {
            behavior: "keep_as_draft",
          },
        });

        return response.status(200).send({
          subscriptionId: subscription.id,
          status: subscription.status,
        });
      } catch (error) {
        console.error("Error pausing gift subscription:", error);
        return response.status(500).send({error: (error as Error).message});
      }
    });
  });

/**
 * Resume a gift subscription
 */
export const resumeGiftSubscription = functions.https.onRequest(
  (request, response) => {
    return corsHandler(request, response, async () => {
      try {
        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {subscriptionId} = request.body;

        if (!subscriptionId) {
          return response.status(400).send({
            error: "Missing subscriptionId",
          });
        }

        // Resume subscription in Stripe
        const subscription = await stripe.subscriptions.update(subscriptionId, {
          pause_collection: null,
        });

        return response.status(200).send({
          subscriptionId: subscription.id,
          status: subscription.status,
        });
      } catch (error) {
        console.error("Error resuming gift subscription:", error);
        return response.status(500).send({error: (error as Error).message});
      }
    });
  });

/**
 * Cancel a gift subscription
 */
export const cancelGiftSubscription = functions.https.onRequest(
  (request, response) => {
    return corsHandler(request, response, async () => {
      try {
        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {subscriptionId} = request.body;

        if (!subscriptionId) {
          return response.status(400).send({
            error: "Missing subscriptionId",
          });
        }

        // Cancel in Stripe
        const subscription = await stripe.subscriptions.cancel(subscriptionId);

        return response.status(200).send({
          subscriptionId: subscription.id,
          status: subscription.status,
        });
      } catch (error) {
        console.error("Error cancelling gift subscription:", error);
        return response.status(500).send({error: (error as Error).message});
      }
    });
  });

/**
 * Fix admin ads to use Firebase Storage URLs instead of placeholder URLs
 */
export const fixAdminAds = functions.https.onRequest(async (req, res) => {
  try {
    const db = admin.firestore();
    const storage = admin.storage();

    // File paths in Firebase Storage
    const imagePaths = [
      "admin_ads/ARFuyX0C44PbYlHSUSlQx55b9vt2/1755734362607_upload.png",
      "admin_ads/ARFuyX0C44PbYlHSUSlQx55b9vt2/1755734362608_upload.png",
      "admin_ads/ARFuyX0C44PbYlHSUSlQx55b9vt2/1755734362609_upload.png",
      "admin_ads/ARFuyX0C44PbYlHSUSlQx55b9vt2/1755734362610_upload.png",
    ];

    // Generate fresh download URLs for all images
    const freshUrls: string[] = [];

    for (const imagePath of imagePaths) {
      try {
        const file = storage.bucket().file(imagePath);

        // Generate a signed URL that expires in 1 year
        const [url] = await file.getSignedUrl({
          action: "read",
          expires: Date.now() + 365 * 24 * 60 * 60 * 1000, // 1 year from now
        });

        freshUrls.push(url);
        console.log(`Generated fresh URL for ${imagePath}`);
      } catch (error) {
        console.error(`Error generating URL for ${imagePath}:`, error);
        // If URL generation fails, skip this image
      }
    }

    if (freshUrls.length === 0) {
      throw new Error("Failed to generate any fresh URLs");
    }

    // Get all ads in the collection
    const adsSnapshot = await db.collection("ads").get();
    let updatedCount = 0;

    for (const doc of adsSnapshot.docs) {
      // Update imageUrl to first fresh URL and set artworkUrls to all fresh
      // URLs
      await doc.ref.update({
        imageUrl: freshUrls[0],
        artworkUrls: freshUrls.join(","),
      });

      updatedCount++;
      console.log(`Updated ad ${doc.id} with fresh Firebase Storage URLs`);
    }

    res.json({
      success: true,
      message: `Updated ${updatedCount} ads with ${freshUrls.length} ` +
        "fresh Firebase Storage URLs",
      urls: freshUrls,
    });
  } catch (error: any) {
    console.error("Error fixing admin ads:", error);
    res.status(500).json({error: error.message});
  }
});

// =============================================================================
// 2025 OPTIMIZATION FUNCTIONS
// =============================================================================

/**
 * Calculate and process monthly usage overages
 */
export const processMonthlyOverages = onSchedule(
  {
    schedule: "0 0 1 * *", // First day of each month at midnight
    timeZone: "UTC",
  },
  async () => {
    console.log("Processing monthly usage overages...");

    try {
      const usersSnapshot = await admin.firestore()
        .collection("users")
        .where("subscriptionTier", "!=", "free")
        .get();

      const billingPromises: Promise<void>[] = [];

      for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;
        const userData = userDoc.data();

        billingPromises.push(processUserOverages(userId, userData));
      }

      await Promise.all(billingPromises);
      console.log(`Processed overages for ${usersSnapshot.docs.length} users`);
    } catch (error) {
      console.error("Error processing monthly overages:", error);
      throw error;
    }
  });

/**
 * Get user's current usage and overage projection
 */
export const getUserUsageProjection = functions.https.onRequest(
  (request, response) => {
    return corsHandler(request, response, async () => {
      try {
        if (request.method !== "GET") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {userId} = request.query;
        if (!userId || typeof userId !== "string") {
          return response.status(400).send({error: "Missing userId parameter"});
        }

        // Get user subscription tier
        const userDoc = await admin.firestore()
          .collection("users")
          .doc(userId)
          .get();

        if (!userDoc.exists) {
          return response.status(404).send({error: "User not found"});
        }

        const userData = userDoc.data();
        const subscriptionTier = userData?.subscriptionTier || "free";

        // Get current usage
        const usageDoc = await admin.firestore()
          .collection("usage")
          .doc(userId)
          .get();

        const usage = usageDoc.exists ? usageDoc.data() : {
          artworksCount: 0,
          storageUsedGB: 0,
          aiCreditsUsed: 0,
          teamMembersCount: 1,
        };

        const limits = getTierLimits(subscriptionTier);
        const projectedOverages = calculateOverages(usage, limits);

        return response.status(200).send({
          userId: userId,
          subscriptionTier: subscriptionTier,
          usage: usage,
          limits: limits,
          projectedOverages: projectedOverages,
          billingDate: getNextBillingDate(),
        });
      } catch (error: any) {
        console.error("Error getting usage projection:", error);
        return response.status(500).send({error: error.message});
      }
    });
  });

/**
 * Handle AI feature usage tracking
 */
export const trackAIUsage = functions.https.onRequest((request, response) => {
  return corsHandler(request, response, async () => {
    try {
      if (request.method !== "POST") {
        return response.status(405).send({error: "Method Not Allowed"});
      }

      const {userId, feature, creditsUsed, metadata} = request.body;

      if (!userId || !feature || creditsUsed === undefined) {
        return response.status(400).send({
          error: "Missing required parameters: userId, feature, creditsUsed",
        });
      }

      // Update user's AI credit usage
      await admin.firestore()
        .collection("usage")
        .doc(userId)
        .update({
          aiCreditsUsed: admin.firestore.FieldValue.increment(creditsUsed),
          lastAIUsage: admin.firestore.Timestamp.now(),
        });

      // Log AI usage event for analytics
      await admin.firestore().collection("aiUsageEvents").add({
        userId: userId,
        feature: feature,
        creditsUsed: creditsUsed,
        metadata: metadata || {},
        timestamp: admin.firestore.Timestamp.now(),
      });

      return response.status(200).send({
        success: true,
        creditsUsed: creditsUsed,
        feature: feature,
      });
    } catch (error: any) {
      console.error("Error tracking AI usage:", error);
      return response.status(500).send({error: error.message});
    }
  });
});

// =============================================================================
// HELPER FUNCTIONS FOR 2025 OPTIMIZATION
// =============================================================================

/**
 * Process overages for a specific user
 * @param {string} userId - The user ID to process overages for
 * @param {any} userData - The user data from Firestore
 * @return {Promise<void>} Promise that resolves when processing is complete
 */
async function processUserOverages(
  userId: string,
  userData: any
): Promise<void> {
  try {
    const subscriptionTier = userData.subscriptionTier || "free";
    // No overage billing for free users
    if (subscriptionTier === "free") return;

    // Get user's usage data
    const usageDoc = await admin.firestore()
      .collection("usage")
      .doc(userId)
      .get();

    if (!usageDoc.exists) return;

    const usage = usageDoc.data();
    const limits = getTierLimits(subscriptionTier);
    const overages = calculateOverages(usage, limits);

    if (overages.totalAmount > 0) {
      await createOverageBill(userId, overages, subscriptionTier);
      await resetMonthlyUsage(userId);
    }
  } catch (error) {
    console.error(`Error processing overages for user ${userId}:`, error);
  }
}

/**
 * Get feature limits for a subscription tier
 * @param {string} tier - The subscription tier name
 * @return {any} Object containing tier limits
 */
function getTierLimits(tier: string): any {
  const limits: Record<string, any> = {
    starter: {
      artworks: 25,
      storageGB: 5,
      aiCredits: 50,
      teamMembers: 1,
    },
    creator: {
      artworks: 100,
      storageGB: 25,
      aiCredits: 200,
      teamMembers: 1,
    },
    business: {
      artworks: -1, // Unlimited
      storageGB: 100,
      aiCredits: 500,
      teamMembers: 5,
    },
    enterprise: {
      artworks: -1, // Unlimited
      storageGB: -1, // Unlimited
      aiCredits: -1, // Unlimited
      teamMembers: -1, // Unlimited
    },
  };

  return limits[tier] || limits.starter;
}

/**
 * Calculate overage amounts based on usage and limits
 * @param {any} usage - Current usage data for the user
 * @param {any} limits - Tier limits for the user's subscription
 * @return {any} Object containing calculated overages
 */
function calculateOverages(usage: any, limits: any): any {
  const overagePricing = {
    artwork: 0.99,
    storageGB: 0.49,
    aiCredit: 0.05,
    teamMember: 9.99,
  };

  const overages = {
    artworks: 0,
    storage: 0,
    aiCredits: 0,
    teamMembers: 0,
    totalAmount: 0,
    details: [] as any[],
  };

  // Calculate artwork overage
  if (limits.artworks !== -1 && usage.artworksCount > limits.artworks) {
    const overageCount = usage.artworksCount - limits.artworks;
    const amount = overageCount * overagePricing.artwork;
    overages.artworks = overageCount;
    overages.totalAmount += amount;
    overages.details.push({
      type: "artwork",
      count: overageCount,
      unitPrice: overagePricing.artwork,
      amount: amount,
    });
  }

  // Calculate storage overage
  if (limits.storageGB !== -1 && usage.storageUsedGB > limits.storageGB) {
    const overageGB = usage.storageUsedGB - limits.storageGB;
    const amount = overageGB * overagePricing.storageGB;
    overages.storage = overageGB;
    overages.totalAmount += amount;
    overages.details.push({
      type: "storage",
      count: overageGB,
      unitPrice: overagePricing.storageGB,
      amount: amount,
    });
  }

  // Calculate AI credits overage
  if (limits.aiCredits !== -1 && usage.aiCreditsUsed > limits.aiCredits) {
    const overageCredits = usage.aiCreditsUsed - limits.aiCredits;
    const amount = overageCredits * overagePricing.aiCredit;
    overages.aiCredits = overageCredits;
    overages.totalAmount += amount;
    overages.details.push({
      type: "aiCredit",
      count: overageCredits,
      unitPrice: overagePricing.aiCredit,
      amount: amount,
    });
  }

  // Calculate team member overage
  if (limits.teamMembers !== -1 &&
      usage.teamMembersCount > limits.teamMembers) {
    const overageMembers = usage.teamMembersCount - limits.teamMembers;
    const amount = overageMembers * overagePricing.teamMember;
    overages.teamMembers = overageMembers;
    overages.totalAmount += amount;
    overages.details.push({
      type: "teamMember",
      count: overageMembers,
      unitPrice: overagePricing.teamMember,
      amount: amount,
    });
  }

  return overages;
}

/**
 * Create overage bill and charge the user
 * @param {string} userId - The user ID to bill
 * @param {any} overages - Calculated overage amounts
 * @param {string} subscriptionTier - User's subscription tier
 * @return {Promise<void>} Promise that resolves when billing is complete
 */
async function createOverageBill(
  userId: string,
  overages: any,
  subscriptionTier: string
): Promise<void> {
  try {
    // Get user's Stripe customer ID
    const userDoc = await admin.firestore()
      .collection("users")
      .doc(userId)
      .get();

    const userData = userDoc.data();
    const stripeCustomerId = userData?.stripeCustomerId;
    if (!stripeCustomerId) {
      console.error(`No Stripe customer ID for user ${userId}`);
      return;
    }

    // Create invoice item for overage
    const invoiceItem = await stripe.invoiceItems.create({
      customer: stripeCustomerId,
      amount: Math.round(overages.totalAmount * 100), // Convert to cents
      currency: "usd",
      description: `Usage overage charges for ${new Date().toLocaleString(
        "default",
        {month: "long", year: "numeric"}
      )}`,
      metadata: {
        userId: userId,
        subscriptionTier: subscriptionTier,
        type: "usage_overage",
        billingPeriod: new Date().toISOString(),
      },
    });

    // Create and finalize invoice
    const invoice = await stripe.invoices.create({
      customer: stripeCustomerId,
      auto_advance: true, // Automatically finalize and attempt payment
      collection_method: "charge_automatically",
      description: "Monthly usage overage charges",
    });

    await stripe.invoices.finalizeInvoice(invoice.id);

    // Store overage record in Firestore
    await admin.firestore().collection("overageBills").add({
      userId: userId,
      subscriptionTier: subscriptionTier,
      billingPeriod: admin.firestore.Timestamp.now(),
      overages: overages,
      stripeInvoiceId: invoice.id,
      stripeInvoiceItemId: invoiceItem.id,
      totalAmount: overages.totalAmount,
      status: "billed",
      createdAt: admin.firestore.Timestamp.now(),
    });

    // Send notification to user
    await admin.firestore().collection("notifications").add({
      userId: userId,
      type: "overage_bill",
      title: "Usage Overage Charges",
      message: `You've been charged $${overages.totalAmount.toFixed(2)} ` +
        "for usage overages this month. View details in your billing section.",
      isRead: false,
      createdAt: admin.firestore.Timestamp.now(),
      additionalData: {
        amount: overages.totalAmount,
        details: overages.details,
        invoiceId: invoice.id,
      },
    });

    console.log(
      `Created overage bill for user ${userId}: ` +
      `$${overages.totalAmount.toFixed(2)}`
    );
  } catch (error) {
    console.error(`Error creating overage bill for user ${userId}:`, error);
  }
}

/**
 * Reset monthly usage counters
 * @param {string} userId - The user ID to reset usage for
 * @return {Promise<void>} Promise that resolves when reset is complete
 */
async function resetMonthlyUsage(userId: string): Promise<void> {
  try {
    await admin.firestore()
      .collection("usage")
      .doc(userId)
      .update({
        aiCreditsUsed: 0,
        lastUsageReset: admin.firestore.Timestamp.now(),
        monthlyResetCount: admin.firestore.FieldValue.increment(1),
      });
  } catch (error) {
    console.error(`Error resetting monthly usage for user ${userId}:`, error);
  }
}

/**
 * Get next billing date (1st of next month)
 * @return {string} ISO string of next billing date
 */
function getNextBillingDate(): string {
  const now = new Date();
  const nextMonth = new Date(now.getFullYear(), now.getMonth() + 1, 1);
  return nextMonth.toISOString();
}

// ============================================================================
// ENHANCED SPONSORSHIP SYSTEM FUNCTIONS
// ============================================================================

/**
 * Create a custom subscription for sponsorships
 */
export const createCustomSubscription = functions.https.onRequest(
  (request, response) => {
    return corsHandler(request, response, async () => {
      try {
        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {
          customerId,
          paymentMethodId,
          priceAmount,
          currency = "usd",
          metadata = {},
        } = request.body;

        if (!customerId || !paymentMethodId || !priceAmount) {
          return response.status(400).send({
            error: "Missing required parameters",
          });
        }

        // Create a price for this specific amount
        const price = await stripe.prices.create({
          unit_amount: Math.round(priceAmount * 100), // Convert to cents
          currency: currency,
          recurring: {
            interval: "month",
          },
          product_data: {
            name: `${metadata.tier || "Custom"} Sponsorship`,
            description: `Monthly sponsorship - ${metadata.tier || "Custom"} tier`,
          },
          metadata: {
            type: "sponsorship",
            tier: metadata.tier || "custom",
            artistId: metadata.artistId || "",
          },
        });

        // Create subscription
        const subscription = await stripe.subscriptions.create({
          customer: customerId,
          items: [{price: price.id}],
          default_payment_method: paymentMethodId,
          expand: ["latest_invoice.payment_intent"],
          metadata: {
            type: "sponsorship",
            ...metadata,
          },
        });

        return response.status(200).send({
          subscriptionId: subscription.id,
          customerId: customerId,
          priceId: price.id,
          status: subscription.status,
          clientSecret: subscription.latest_invoice?.payment_intent
            ?.client_secret,
        });
      } catch (error) {
        console.error("Error creating custom subscription:", error);
        return response.status(500).send({error: (error as Error).message});
      }
    });
  });

/**
 * Pause a subscription
 */
export const pauseSubscription = functions.https.onRequest(
  (request, response) => {
    return corsHandler(request, response, async () => {
      try {
        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {subscriptionId} = request.body;

        if (!subscriptionId) {
          return response.status(400).send({
            error: "Missing subscription ID",
          });
        }

        // Pause subscription by setting pause_collection
        const subscription = await stripe.subscriptions.update(
          subscriptionId,
          {
            pause_collection: {
              behavior: "keep_as_draft",
            },
          }
        );

        return response.status(200).send({
          subscriptionId: subscription.id,
          status: subscription.status,
          paused: subscription.pause_collection !== null,
        });
      } catch (error) {
        console.error("Error pausing subscription:", error);
        return response.status(500).send({error: (error as Error).message});
      }
    });
  });

/**
 * Resume a paused subscription
 */
export const resumeSubscription = functions.https.onRequest(
  (request, response) => {
    return corsHandler(request, response, async () => {
      try {
        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {subscriptionId} = request.body;

        if (!subscriptionId) {
          return response.status(400).send({
            error: "Missing subscription ID",
          });
        }

        // Resume subscription by removing pause_collection
        const subscription = await stripe.subscriptions.update(
          subscriptionId,
          {
            pause_collection: null,
          }
        );

        return response.status(200).send({
          subscriptionId: subscription.id,
          status: subscription.status,
          paused: subscription.pause_collection !== null,
        });
      } catch (error) {
        console.error("Error resuming subscription:", error);
        return response.status(500).send({error: (error as Error).message});
      }
    });
  });

/**
 * Update subscription price (for tier changes)
 */
export const updateSubscriptionPrice = functions.https.onRequest(
  (request, response) => {
    return corsHandler(request, response, async () => {
      try {
        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {subscriptionId, newPriceAmount, metadata = {}} = request.body;

        if (!subscriptionId || !newPriceAmount) {
          return response.status(400).send({
            error: "Missing required parameters",
          });
        }

        // Get current subscription
        const currentSubscription = await stripe.subscriptions.retrieve(
          subscriptionId
        );

        // Create new price
        const newPrice = await stripe.prices.create({
          unit_amount: Math.round(newPriceAmount * 100), // Convert to cents
          currency: "usd",
          recurring: {
            interval: "month",
          },
          product_data: {
            name: `${metadata.tier || "Custom"} Sponsorship`,
            description: `Monthly sponsorship - ${metadata.tier || "Custom"} tier`,
          },
          metadata: {
            type: "sponsorship",
            tier: metadata.tier || "custom",
            artistId: metadata.artistId || "",
          },
        });

        // Update subscription with new price
        const subscription = await stripe.subscriptions.update(
          subscriptionId,
          {
            items: [
              {
                id: currentSubscription.items.data[0].id,
                price: newPrice.id,
              },
            ],
            proration_behavior: "create_prorations",
          }
        );

        return response.status(200).send({
          subscriptionId: subscription.id,
          newPriceId: newPrice.id,
          status: subscription.status,
        });
      } catch (error) {
        console.error("Error updating subscription price:", error);
        return response.status(500).send({error: (error as Error).message});
      }
    });
  });

/**
 * Stripe webhook handler for sponsorship events
 */
export const sponsorshipWebhook = functions.https.onRequest(
  async (request, response) => {
    const sig = request.headers["stripe-signature"] as string;
    const webhookSecret = functions.config().stripe.webhook_secret;

    let event;

    try {
      // Verify webhook signature
      event = stripe.webhooks.constructEvent(
        request.rawBody,
        sig,
        webhookSecret
      );
    } catch (err) {
      console.error("Webhook signature verification failed:", err);
      return response.status(400).send(`Webhook Error: ${err}`);
    }

    // Handle webhook events
    try {
      switch (event.type) {
        case "invoice.payment_succeeded":
          await handleSponsorshipPaymentSucceeded(event.data.object);
          break;

        case "invoice.payment_failed":
          await handleSponsorshipPaymentFailed(event.data.object);
          break;

        case "customer.subscription.updated":
          await handleSponsorshipSubscriptionUpdated(event.data.object);
          break;

        case "customer.subscription.deleted":
          await handleSponsorshipSubscriptionDeleted(event.data.object);
          break;

        default:
          console.log(`Unhandled event type: ${event.type}`);
      }

      response.status(200).send({received: true});
    } catch (error) {
      console.error("Error handling webhook:", error);
      response.status(500).send({error: "Webhook handler failed"});
    }
  });

/**
 * Handle successful sponsorship payment
 */
async function handleSponsorshipPaymentSucceeded(invoice: any): Promise<void> {
  try {
    const subscription = await stripe.subscriptions.retrieve(
      invoice.subscription
    );

    // Check if this is a sponsorship subscription
    if (subscription.metadata.type !== "sponsorship") {
      return;
    }

    const {artistId, tier} = subscription.metadata;
    const amount = invoice.amount_paid / 100; // Convert from cents

    // Find the sponsorship record in Firestore
    const sponsorshipQuery = await admin.firestore()
      .collection("sponsorships")
      .where("stripeSubscriptionId", "==", subscription.id)
      .limit(1)
      .get();

    if (sponsorshipQuery.empty) {
      console.error("Sponsorship record not found for subscription:",
        subscription.id);
      return;
    }

    const sponsorshipDoc = sponsorshipQuery.docs[0];
    const sponsorshipData = sponsorshipDoc.data();

    // Record the payment
    await admin.firestore().collection("sponsorship_payments").add({
      sponsorshipId: sponsorshipDoc.id,
      amount: amount,
      paymentDate: admin.firestore.Timestamp.now(),
      status: "succeeded",
      stripePaymentIntentId: invoice.payment_intent,
      stripeInvoiceId: invoice.id,
    });

    // Update artist earnings
    await admin.firestore().collection("earnings_transactions").add({
      artistId: artistId,
      type: "sponsorship",
      amount: amount,
      fromUserId: sponsorshipData.sponsorId,
      fromUserName: sponsorshipData.sponsorName,
      timestamp: admin.firestore.Timestamp.now(),
      status: "completed",
      description: `Monthly ${tier} sponsorship payment`,
      metadata: {
        sponsorshipId: sponsorshipDoc.id,
        tier: tier,
        stripeInvoiceId: invoice.id,
      },
    });

    // Update next billing date
    const nextBillingDate = new Date();
    nextBillingDate.setMonth(nextBillingDate.getMonth() + 1);

    await sponsorshipDoc.ref.update({
      nextBillingDate: admin.firestore.Timestamp.fromDate(nextBillingDate),
      lastPaymentDate: admin.firestore.Timestamp.now(),
      lastPaymentAmount: amount,
    });

    console.log(`Sponsorship payment processed: ${amount} for ${artistId}`);
  } catch (error) {
    console.error("Error handling sponsorship payment succeeded:", error);
  }
}

/**
 * Handle failed sponsorship payment
 */
async function handleSponsorshipPaymentFailed(invoice: any): Promise<void> {
  try {
    const subscription = await stripe.subscriptions.retrieve(
      invoice.subscription
    );

    // Check if this is a sponsorship subscription
    if (subscription.metadata.type !== "sponsorship") {
      return;
    }

    // Find the sponsorship record
    const sponsorshipQuery = await admin.firestore()
      .collection("sponsorships")
      .where("stripeSubscriptionId", "==", subscription.id)
      .limit(1)
      .get();

    if (sponsorshipQuery.empty) {
      return;
    }

    const sponsorshipDoc = sponsorshipQuery.docs[0];
    const amount = invoice.amount_due / 100;

    // Record the failed payment
    await admin.firestore().collection("sponsorship_payments").add({
      sponsorshipId: sponsorshipDoc.id,
      amount: amount,
      paymentDate: admin.firestore.Timestamp.now(),
      status: "failed",
      stripePaymentIntentId: invoice.payment_intent,
      stripeInvoiceId: invoice.id,
      failureReason: "Payment failed",
    });

    console.log(`Sponsorship payment failed: ${amount} for subscription ${subscription.id}`);
  } catch (error) {
    console.error("Error handling sponsorship payment failed:", error);
  }
}

/**
 * Handle sponsorship subscription updates
 */
async function handleSponsorshipSubscriptionUpdated(
  subscription: any
): Promise<void> {
  try {
    // Check if this is a sponsorship subscription
    if (subscription.metadata.type !== "sponsorship") {
      return;
    }

    // Find the sponsorship record
    const sponsorshipQuery = await admin.firestore()
      .collection("sponsorships")
      .where("stripeSubscriptionId", "==", subscription.id)
      .limit(1)
      .get();

    if (sponsorshipQuery.empty) {
      return;
    }

    const sponsorshipDoc = sponsorshipQuery.docs[0];

    // Update sponsorship status based on subscription status
    let status = "active";
    if (subscription.status === "canceled") {
      status = "cancelled";
    } else if (subscription.pause_collection) {
      status = "paused";
    }

    await sponsorshipDoc.ref.update({
      status: status,
      updatedAt: admin.firestore.Timestamp.now(),
    });

    console.log(`Sponsorship subscription updated: ${subscription.id} -> ${status}`);
  } catch (error) {
    console.error("Error handling sponsorship subscription updated:", error);
  }
}

/**
 * Handle sponsorship subscription deletion
 */
async function handleSponsorshipSubscriptionDeleted(
  subscription: any
): Promise<void> {
  try {
    // Check if this is a sponsorship subscription
    if (subscription.metadata.type !== "sponsorship") {
      return;
    }

    // Find the sponsorship record
    const sponsorshipQuery = await admin.firestore()
      .collection("sponsorships")
      .where("stripeSubscriptionId", "==", subscription.id)
      .limit(1)
      .get();

    if (sponsorshipQuery.empty) {
      return;
    }

    const sponsorshipDoc = sponsorshipQuery.docs[0];

    // Update sponsorship status to cancelled
    await sponsorshipDoc.ref.update({
      status: "cancelled",
      cancelledAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now(),
    });

    console.log(`Sponsorship subscription cancelled: ${subscription.id}`);
  } catch (error) {
    console.error("Error handling sponsorship subscription deleted:", error);
  }
}

/**
 * Get sponsorship analytics for an artist
 */
export const getSponsorshipAnalytics = functions.https.onRequest(
  (request, response) => {
    return corsHandler(request, response, async () => {
      try {
        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {artistId, timeframe = "month"} = request.body;

        if (!artistId) {
          return response.status(400).send({
            error: "Missing artist ID",
          });
        }

        // Calculate date range based on timeframe
        const now = new Date();
        let startDate: Date;

        switch (timeframe) {
          case "week":
            startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
            break;
          case "month":
            startDate = new Date(now.getFullYear(), now.getMonth(), 1);
            break;
          case "year":
            startDate = new Date(now.getFullYear(), 0, 1);
            break;
          default:
            startDate = new Date(now.getFullYear(), now.getMonth(), 1);
        }

        // Get active sponsorships
        const sponsorshipsSnapshot = await admin.firestore()
          .collection("sponsorships")
          .where("artistId", "==", artistId)
          .where("status", "==", "active")
          .get();

        const sponsorships = sponsorshipsSnapshot.docs.map(doc => ({
          id: doc.id,
          ...doc.data(),
        }));

        // Get sponsorship payments in timeframe
        const paymentsSnapshot = await admin.firestore()
          .collection("sponsorship_payments")
          .where("paymentDate", ">=", admin.firestore.Timestamp.fromDate(startDate))
          .where("paymentDate", "<=", admin.firestore.Timestamp.fromDate(now))
          .where("status", "==", "succeeded")
          .get();

        const payments = paymentsSnapshot.docs.map(doc => doc.data());

        // Filter payments for this artist's sponsorships
        const sponsorshipIds = sponsorships.map(s => s.id);
        const artistPayments = payments.filter(p => 
          sponsorshipIds.includes(p.sponsorshipId)
        );

        // Calculate analytics
        const totalRevenue = artistPayments.reduce((sum, p) => sum + p.amount, 0);
        const totalSponsors = sponsorships.length;
        const averageAmount = totalSponsors > 0 ? totalRevenue / totalSponsors : 0;

        // Tier breakdown
        const tierBreakdown = sponsorships.reduce((acc, s) => {
          const tier = s.tier;
          acc[tier] = (acc[tier] || 0) + 1;
          return acc;
        }, {} as Record<string, number>);

        // Monthly revenue trend (last 6 months)
        const monthlyTrend = [];
        for (let i = 5; i >= 0; i--) {
          const monthStart = new Date(now.getFullYear(), now.getMonth() - i, 1);
          const monthEnd = new Date(now.getFullYear(), now.getMonth() - i + 1, 0);
          
          const monthPayments = payments.filter(p => {
            const paymentDate = p.paymentDate.toDate();
            return paymentDate >= monthStart && paymentDate <= monthEnd &&
                   sponsorshipIds.includes(p.sponsorshipId);
          });

          const monthRevenue = monthPayments.reduce((sum, p) => sum + p.amount, 0);
          
          monthlyTrend.push({
            month: monthStart.toISOString().substring(0, 7), // YYYY-MM format
            revenue: monthRevenue,
            paymentCount: monthPayments.length,
          });
        }

        const analytics = {
          totalSponsors,
          totalRevenue,
          averageAmount,
          tierBreakdown,
          monthlyTrend,
          timeframe,
          generatedAt: new Date().toISOString(),
        };

        return response.status(200).send(analytics);
      } catch (error) {
        console.error("Error getting sponsorship analytics:", error);
        return response.status(500).send({error: (error as Error).message});
      }
    });
  });

/**
 * Create payment intent for commission deposit
 */
export const createCommissionPayment = functions.https.onRequest(
  (request, response) => {
    return corsHandler(request, response, async () => {
      try {
        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {
          commissionId,
          amount,
          currency = "usd",
          customerId,
          milestoneId,
        } = request.body;

        if (!commissionId || !amount || !customerId) {
          return response.status(400).send({
            error: "Missing required parameters",
          });
        }

        // Get commission details
        const commissionDoc = await admin.firestore()
          .collection("direct_commissions")
          .doc(commissionId)
          .get();

        if (!commissionDoc.exists) {
          return response.status(404).send({error: "Commission not found"});
        }

        const commission = commissionDoc.data();

        // Create payment intent
        const paymentIntent = await stripe.paymentIntents.create({
          amount: Math.round(amount * 100), // Convert to cents
          currency,
          customer: customerId,
          metadata: {
            commissionId,
            milestoneId: milestoneId || "deposit",
            artistId: commission?.artistId || "",
            clientId: commission?.clientId || "",
            type: "commission",
          },
          description: `Commission payment for "${commission?.title || "Artwork"}"`,
        });

        return response.status(200).send({
          clientSecret: paymentIntent.client_secret,
          paymentIntentId: paymentIntent.id,
        });
      } catch (error) {
        console.error("Error creating commission payment:", error);
        return response.status(500).send({error: (error as Error).message});
      }
    });
  });

/**
 * Handle commission payment webhook
 */
export const handleCommissionPaymentWebhook = functions.https.onRequest(
  async (request, response) => {
    const sig = request.headers["stripe-signature"] as string;
    let event;

    try {
      event = stripe.webhooks.constructEvent(
        request.rawBody,
        sig,
        functions.config().stripe.webhook_secret
      );
    } catch (err) {
      console.error("Webhook signature verification failed:", err);
      return response.status(400).send(`Webhook Error: ${err}`);
    }

    try {
      if (event.type === "payment_intent.succeeded") {
        const paymentIntent = event.data.object;
        const {commissionId, milestoneId, artistId} = paymentIntent.metadata;

        if (commissionId && paymentIntent.metadata.type === "commission") {
          // Update commission status
          const commissionRef = admin.firestore()
            .collection("direct_commissions")
            .doc(commissionId);

          const commissionDoc = await commissionRef.get();
          if (!commissionDoc.exists) {
            console.error("Commission not found:", commissionId);
            return response.status(404).send("Commission not found");
          }

          const commission = commissionDoc.data();
          const amount = paymentIntent.amount / 100; // Convert from cents

          // Update milestone if specified
          if (milestoneId && milestoneId !== "deposit") {
            const milestones = commission?.milestones || [];
            const updatedMilestones = milestones.map((milestone: any) => {
              if (milestone.id === milestoneId) {
                return {
                  ...milestone,
                  status: "paid",
                  completedAt: admin.firestore.Timestamp.now(),
                  paymentIntentId: paymentIntent.id,
                };
              }
              return milestone;
            });

            await commissionRef.update({
              milestones: updatedMilestones,
            });
          } else {
            // This is a deposit payment - start the commission
            await commissionRef.update({
              status: "inProgress",
              "metadata.depositPaidAt": admin.firestore.Timestamp.now(),
              "metadata.depositPaymentIntentId": paymentIntent.id,
            });
          }

          // Create earnings transaction for artist
          if (artistId) {
            const earningsRef = admin.firestore()
              .collection("earnings_transactions")
              .doc();

            await earningsRef.set({
              id: earningsRef.id,
              artistId,
              type: "commission",
              amount,
              fromUserId: commission?.clientId || "",
              fromUserName: commission?.clientName || "Unknown Client",
              timestamp: admin.firestore.Timestamp.now(),
              status: "completed",
              description: `Commission payment: ${commission?.title || "Artwork"}`,
              metadata: {
                commissionId,
                milestoneId: milestoneId || "deposit",
                paymentIntentId: paymentIntent.id,
              },
            });

            // Update artist earnings
            const artistEarningsRef = admin.firestore()
              .collection("artist_earnings")
              .doc(artistId);

            await artistEarningsRef.set({
              commissionEarnings: admin.firestore.FieldValue.increment(amount),
              totalEarnings: admin.firestore.FieldValue.increment(amount),
              availableBalance: admin.firestore.FieldValue.increment(amount),
              lastUpdated: admin.firestore.Timestamp.now(),
            }, {merge: true});
          }

          // Add message to commission
          const messages = commission?.messages || [];
          const newMessage = {
            id: admin.firestore().collection("temp").doc().id,
            senderId: "system",
            senderName: "System",
            message: milestoneId === "deposit" ? 
              `Deposit payment of $${amount.toFixed(2)} received. Work can now begin!` :
              `Milestone payment of $${amount.toFixed(2)} received.`,
            timestamp: admin.firestore.Timestamp.now(),
            attachments: [],
          };

          await commissionRef.update({
            messages: admin.firestore.FieldValue.arrayUnion(newMessage),
          });
        }
      }

      return response.status(200).send("Webhook handled successfully");
    } catch (error) {
      console.error("Error handling commission payment webhook:", error);
      return response.status(500).send("Webhook handler failed");
    }
  });

/**
 * Send commission notification
 */
export const sendCommissionNotification = functions.firestore
  .document("direct_commissions/{commissionId}")
  .onUpdate(async (change, context) => {
    try {
      const before = change.before.data();
      const after = change.after.data();
      const commissionId = context.params.commissionId;

      // Check if status changed
      if (before.status !== after.status) {
        const {clientId, artistId, title, status} = after;
        
        // Determine who to notify based on status change
        let recipientId = "";
        let notificationTitle = "";
        let notificationBody = "";

        switch (status) {
          case "quoted":
            recipientId = clientId;
            notificationTitle = "Commission Quote Ready";
            notificationBody = `Your commission "${title}" has been quoted. Review and accept to proceed.`;
            break;
          case "accepted":
            recipientId = artistId;
            notificationTitle = "Commission Accepted";
            notificationBody = `Your quote for "${title}" has been accepted. Waiting for deposit payment.`;
            break;
          case "inProgress":
            recipientId = clientId;
            notificationTitle = "Commission Started";
            notificationBody = `Work has begun on your commission "${title}".`;
            break;
          case "completed":
            recipientId = clientId;
            notificationTitle = "Commission Completed";
            notificationBody = `Your commission "${title}" is ready for review!`;
            break;
          case "delivered":
            recipientId = clientId;
            notificationTitle = "Commission Delivered";
            notificationBody = `Your commission "${title}" has been delivered successfully.`;
            break;
        }

        if (recipientId && notificationTitle) {
          // Get user's FCM token
          const userDoc = await admin.firestore()
            .collection("users")
            .doc(recipientId)
            .get();

          const userData = userDoc.data();
          const fcmToken = userData?.fcmToken;

          if (fcmToken) {
            // Send push notification
            await admin.messaging().send({
              token: fcmToken,
              notification: {
                title: notificationTitle,
                body: notificationBody,
              },
              data: {
                type: "commission_update",
                commissionId,
                status,
              },
            });
          }

          // Create in-app notification
          await admin.firestore()
            .collection("notifications")
            .add({
              userId: recipientId,
              type: "commission_update",
              title: notificationTitle,
              body: notificationBody,
              data: {
                commissionId,
                status,
              },
              read: false,
              createdAt: admin.firestore.Timestamp.now(),
            });
        }
      }
    } catch (error) {
      console.error("Error sending commission notification:", error);
    }
  });

/**
 * Calculate commission pricing
 */
export const calculateCommissionPricing = functions.https.onRequest(
  (request, response) => {
    return corsHandler(request, response, async () => {
      try {
        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {artistId, type, specs} = request.body;

        if (!artistId || !type || !specs) {
          return response.status(400).send({
            error: "Missing required parameters",
          });
        }

        // Get artist commission settings
        const settingsDoc = await admin.firestore()
          .collection("artist_commission_settings")
          .doc(artistId)
          .get();

        if (!settingsDoc.exists) {
          return response.status(404).send({
            error: "Artist commission settings not found",
          });
        }

        const settings = settingsDoc.data();
        let basePrice = settings?.basePrice || 0;

        // Add type-specific pricing
        const typePricing = settings?.typePricing || {};
        if (typePricing[type]) {
          basePrice += typePricing[type];
        }

        // Add size-specific pricing
        const sizePricing = settings?.sizePricing || {};
        if (sizePricing[specs.size]) {
          basePrice += sizePricing[specs.size];
        }

        // Add commercial use fee (typically 50% more)
        if (specs.commercialUse) {
          basePrice *= 1.5;
        }

        // Add revision fee for extra revisions
        if (specs.revisions > 1) {
          basePrice += (specs.revisions - 1) * (basePrice * 0.1);
        }

        const depositPercentage = settings?.depositPercentage || 50;
        const depositAmount = basePrice * (depositPercentage / 100);

        return response.status(200).send({
          basePrice,
          totalPrice: basePrice,
          depositAmount,
          remainingAmount: basePrice - depositAmount,
          depositPercentage,
          breakdown: {
            base: settings?.basePrice || 0,
            typeAddition: typePricing[type] || 0,
            sizeAddition: sizePricing[specs.size] || 0,
            commercialMultiplier: specs.commercialUse ? 1.5 : 1,
            revisionFee: specs.revisions > 1 ? 
              (specs.revisions - 1) * (basePrice * 0.1) : 0,
          },
        });
      } catch (error) {
        console.error("Error calculating commission pricing:", error);
        return response.status(500).send({error: (error as Error).message});
      }
    });
  });

// Export Direct Commission functions
export {
  createCommissionRequest,
  submitCommissionQuote,
  acceptCommissionQuote,
  handleDepositPayment,
  completeCommission,
  handleFinalPayment,
} from "./directCommissions";
