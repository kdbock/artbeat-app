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
