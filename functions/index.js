const functions = require('firebase-functions');
const admin = require('firebase-admin');
const stripe = require('stripe')(functions.config().stripe.secret_key);
const cors = require('cors')({ origin: true });

admin.initializeApp();

// Constants for Stripe products and prices
const STRIPE_PRODUCTS = {
  ARTIST_PRO: 'prod_artist_pro', // Replace with your actual Stripe product ID
  GALLERY: 'prod_gallery', // Replace with your actual Stripe product ID
};

const STRIPE_PRICES = {
  ARTIST_PRO_MONTHLY: 'price_artist_pro_monthly', // Replace with your actual Stripe price ID
  GALLERY_MONTHLY: 'price_gallery_monthly', // Replace with your actual Stripe price ID
};

/**
 * Create a payment intent for subscription purchase
 */
exports.createPaymentIntent = functions.https.onRequest((request, response) => {
  cors(request, response, async () => {
    try {
      if (request.method !== 'POST') {
        return response.status(405).send({ error: 'Method Not Allowed' });
      }

      const { email, amount, currency, userId, planId, metadata } = request.body;

      if (!email || !amount || !currency || !userId || !planId) {
        return response.status(400).send({ 
          error: 'Missing required parameters' 
        });
      }

      // Create or get customer
      let customer;
      const customerSearch = await stripe.customers.search({
        query: `email:'${email}'`,
      });

      if (customerSearch.data.length > 0) {
        customer = customerSearch.data[0];
      } else {
        customer = await stripe.customers.create({
          email,
          metadata: { 
            userId,
            firebaseUserId: userId,
          },
        });
      }

      // Create ephemeral key for customer
      const ephemeralKey = await stripe.ephemeralKeys.create(
        { customer: customer.id },
        { apiVersion: '2023-10-16' } // Use the latest Stripe API version
      );

      // Create payment intent
      const paymentIntent = await stripe.paymentIntents.create({
        amount,
        currency,
        customer: customer.id,
        automatic_payment_methods: { enabled: true },
        metadata: {
          userId,
          planId,
          ...metadata,
        },
      });

      // Return client secret and customer info
      response.status(200).send({
        clientSecret: paymentIntent.client_secret,
        customer: customer.id,
        ephemeralKey: ephemeralKey.secret,
        paymentIntentId: paymentIntent.id,
      });
    } catch (error) {
      console.error('Error creating payment intent:', error);
      response.status(500).send({ error: error.message });
    }
  });
});

/**
 * Create subscription in Stripe
 */
exports.createSubscription = functions.https.onRequest((request, response) => {
  cors(request, response, async () => {
    try {
      if (request.method !== 'POST') {
        return response.status(405).send({ error: 'Method Not Allowed' });
      }

      const { customerId, priceId, userId } = request.body;

      if (!customerId || !priceId || !userId) {
        return response.status(400).send({ 
          error: 'Missing required parameters' 
        });
      }

      // Create subscription
      const subscription = await stripe.subscriptions.create({
        customer: customerId,
        items: [{ price: priceId }],
        payment_behavior: 'default_incomplete',
        expand: ['latest_invoice.payment_intent'],
        metadata: {
          userId,
          firebaseUserId: userId,
        },
      });

      // Return subscription details
      response.status(200).send({
        subscriptionId: subscription.id,
        status: subscription.status,
        clientSecret: subscription.latest_invoice.payment_intent?.client_secret ?? '',
      });
    } catch (error) {
      console.error('Error creating subscription:', error);
      response.status(500).send({ error: error.message });
    }
  });
});

/**
 * Cancel subscription in Stripe
 */
exports.cancelSubscription = functions.https.onRequest((request, response) => {
  cors(request, response, async () => {
    try {
      if (request.method !== 'POST') {
        return response.status(405).send({ error: 'Method Not Allowed' });
      }

      const { subscriptionId } = request.body;

      if (!subscriptionId) {
        return response.status(400).send({ 
          error: 'Missing subscription ID' 
        });
      }

      // Cancel at period end to avoid immediate cancellation
      const subscription = await stripe.subscriptions.update(
        subscriptionId,
        { cancel_at_period_end: true }
      );

      // Return cancellation details
      response.status(200).send({
        subscriptionId: subscription.id,
        status: subscription.status,
        cancelAtPeriodEnd: subscription.cancel_at_period_end,
      });
    } catch (error) {
      console.error('Error cancelling subscription:', error);
      response.status(500).send({ error: error.message });
    }
  });
});

/**
 * Webhook handler for Stripe events
 */
exports.stripeWebhook = functions.https.onRequest(async (request, response) => {
  const signature = request.headers['stripe-signature'];
  const webhookSecret = functions.config().stripe.webhook_secret;

  let event;

  try {
    // Verify the event came from Stripe
    event = stripe.webhooks.constructEvent(
      request.rawBody,
      signature,
      webhookSecret
    );
  } catch (error) {
    console.error('Webhook signature verification failed:', error);
    return response.status(400).send({ error: error.message });
  }

  // Handle different event types
  switch (event.type) {
    case 'customer.subscription.created':
    case 'customer.subscription.updated': {
      const subscription = event.data.object;
      const { userId } = subscription.metadata;

      if (!userId) {
        console.error('No userId found in subscription metadata');
        break;
      }

      const isActive = ['active', 'trialing'].includes(subscription.status);
      const currentPeriodEnd = new Date(subscription.current_period_end * 1000);
      
      try {
        // Get user to check notification preferences
        const userRef = admin.firestore().collection('users').doc(userId);
        const userSnapshot = await userRef.get();
        const user = userSnapshot.exists ? userSnapshot.data() : null;
        const userPrefs = user?.notificationPreferences ?? {};
        
        // Update user subscription in Firestore
        const subscriptionsRef = admin.firestore().collection('subscriptions');
        const existingSubscriptions = await subscriptionsRef
          .where('stripeSubscriptionId', '==', subscription.id)
          .get();

        const isNewSubscription = existingSubscriptions.empty;
        let previousTier = null;
        let newTier = null;
        
        // Get human-readable tier names for notifications
        const tierDisplayNames = {
          'free': 'Artist Basic (Free)',
          'standard': 'Artist Pro',
          'premium': 'Gallery'
        };
        
        if (!existingSubscriptions.empty) {
          // Get previous tier before updating
          const existingSubscription = existingSubscriptions.docs[0].data();
          previousTier = existingSubscription.tier;
          
          // Update existing subscription
          await existingSubscriptions.docs[0].ref.update({
            isActive,
            autoRenew: !subscription.cancel_at_period_end,
            endDate: admin.firestore.Timestamp.fromDate(currentPeriodEnd),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          
          // Handle subscription renewal
          if (event.type === 'customer.subscription.updated' && 
              subscription.status === 'active' &&
              existingSubscription.isActive) {
            
            const notifyOnSubscriptionRenewal = userPrefs.notifyOnSubscriptionRenewal !== false; // Default to true
            
            if (notifyOnSubscriptionRenewal) {
              // Format renewal date
              const renewalDate = new Intl.DateTimeFormat('en-US', {
                year: 'numeric', 
                month: 'long', 
                day: 'numeric'
              }).format(currentPeriodEnd);
              
              // Create renewal notification
              await admin.firestore().collection('notifications').add({
                userId: userId,
                type: 'subscriptionRenewal',
                content: `Your ${tierDisplayNames[previousTier] || previousTier} subscription has been renewed successfully. Next billing date: ${renewalDate}.`,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                isRead: false,
                subscriptionId: subscription.id,
                additionalData: {
                  tier: previousTier,
                  renewalDate: currentPeriodEnd.toISOString(),
                }
              });
            }
          }
          
          // Handle subscription about to expire (7 days warning)
          const previousEndDate = existingSubscription.endDate.toDate();
          const newEndDate = currentPeriodEnd;
          const oneWeekBeforeEnd = new Date(newEndDate);
          oneWeekBeforeEnd.setDate(oneWeekBeforeEnd.getDate() - 7);
          
          // Schedule a notification for 7 days before expiration if auto-renew is off
          if (subscription.cancel_at_period_end) {
            const notifyOnSubscriptionCancelled = userPrefs.notifyOnSubscriptionCancelled !== false; // Default to true
            
            if (notifyOnSubscriptionCancelled) {
              const formattedEndDate = new Intl.DateTimeFormat('en-US', {
                year: 'numeric', 
                month: 'long', 
                day: 'numeric'
              }).format(newEndDate);
              
              // We're not actually creating this notification now, but this would be handled
              // by a scheduled function that runs daily to check for expiring subscriptions
              console.log(`Subscription ${subscription.id} for user ${userId} will expire on ${formattedEndDate}`);
            }
          }
        } else {
          // Create new subscription record
          const tierMap = {
            [STRIPE_PRICES.ARTIST_PRO_MONTHLY]: 'standard',
            [STRIPE_PRICES.GALLERY_MONTHLY]: 'premium',
          };
          
          newTier = tierMap[subscription.items.data[0].price.id] || 'free';
          
          await subscriptionsRef.add({
            userId,
            tier: newTier,
            stripeCustomerId: subscription.customer,
            stripePriceId: subscription.items.data[0].price.id,
            stripeSubscriptionId: subscription.id,
            startDate: admin.firestore.Timestamp.now(),
            endDate: admin.firestore.Timestamp.fromDate(currentPeriodEnd),
            isActive,
            autoRenew: !subscription.cancel_at_period_end,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          
          // Also update artist profile with subscription tier
          const artistProfilesRef = admin.firestore().collection('artistProfiles');
          const artistProfiles = await artistProfilesRef
            .where('userId', '==', userId)
            .get();
            
          if (!artistProfiles.empty) {
            await artistProfiles.docs[0].ref.update({
              subscriptionTier: newTier,
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          }
          
          const notifyOnSubscriptionChanges = userPrefs.notifyOnSubscriptionChanges !== false; // Default to true
          
          if (notifyOnSubscriptionChanges) {
            // Format end date for display
            const formattedEndDate = new Intl.DateTimeFormat('en-US', {
              year: 'numeric', 
              month: 'long', 
              day: 'numeric'
            }).format(currentPeriodEnd);
            
            // Send notification for new subscription
            await admin.firestore().collection('notifications').add({
              userId: userId,
              type: 'tierUpgrade',
              content: `You have successfully subscribed to the ${tierDisplayNames[newTier] || newTier} plan. Your subscription is valid until ${formattedEndDate}.`,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              isRead: false,
              subscriptionId: subscription.id,
              additionalData: {
                tier: newTier,
                endDate: currentPeriodEnd.toISOString(),
              }
            });
          }
        }
        
        // Handle tier changes
        if (!isNewSubscription && previousTier && newTier && previousTier !== newTier) {
          const notifyOnSubscriptionChanges = userPrefs.notifyOnSubscriptionChanges !== false; // Default to true
          
          if (notifyOnSubscriptionChanges) {
            const isUpgrade = newTier === 'premium' || (previousTier === 'free' && newTier === 'standard');
            const notificationType = isUpgrade ? 'tierUpgrade' : 'tierDowngrade';
            
            const message = isUpgrade ?
              `You have upgraded from ${tierDisplayNames[previousTier] || previousTier} to ${tierDisplayNames[newTier] || newTier}.` :
              `Your subscription has changed from ${tierDisplayNames[previousTier] || previousTier} to ${tierDisplayNames[newTier] || newTier}.`;
              
            // Create tier change notification
            await admin.firestore().collection('notifications').add({
              userId: userId,
              type: notificationType,
              content: message,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              isRead: false,
              subscriptionId: subscription.id,
            });
          }
        }
      } catch (error) {
        console.error('Error updating subscription in Firestore:', error);
      }
      break;
    }
    
    case 'customer.subscription.deleted': {
      const subscription = event.data.object;
      const { userId } = subscription.metadata;

      if (!userId) {
        console.error('No userId found in subscription metadata');
        break;
      }

      try {
        // Update subscription in Firestore
        const subscriptionsRef = admin.firestore().collection('subscriptions');
        const existingSubscriptions = await subscriptionsRef
          .where('stripeSubscriptionId', '==', subscription.id)
          .get();

        if (!existingSubscriptions.empty) {
          const existingSubscription = existingSubscriptions.docs[0].data();
          const previousTier = existingSubscription.tier;
          
          // Set subscription to inactive
          await existingSubscriptions.docs[0].ref.update({
            isActive: false,
            autoRenew: false,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          
          // Check notification preferences before creating notification
          const userRef = admin.firestore().collection('users').doc(userId);
          const userDoc = await userRef.get();
          
          if (userDoc.exists) {
            const userPrefs = (userDoc.data().notificationPreferences || {});
            const notifyOnSubscriptionCancelled = userPrefs.notifyOnSubscriptionCancelled !== false; // Default to true
            
            if (notifyOnSubscriptionCancelled) {
              // Get human-readable tier names
              const tierDisplayNames = {
                'free': 'Artist Basic (Free)',
                'standard': 'Artist Pro',
                'premium': 'Gallery'
              };
              
              // Create subscription cancelled notification
              await admin.firestore().collection('notifications').add({
                userId: userId,
                type: 'subscriptionCancelled',
                content: `Your ${tierDisplayNames[previousTier] || previousTier} subscription has been cancelled. Your subscription benefits will end on ${new Date(subscription.current_period_end * 1000).toLocaleDateString()}.`,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                isRead: false,
                subscriptionId: subscription.id,
                additionalData: {
                  tier: previousTier,
                  endDate: new Date(subscription.current_period_end * 1000).toISOString(),
                }
              });
            }
          }
        }
        
        // Update artist profile to free tier
        const artistProfilesRef = admin.firestore().collection('artistProfiles');
        const artistProfiles = await artistProfilesRef
          .where('userId', '==', userId)
          .get();
          
        if (!artistProfiles.empty) {
          await artistProfilesRef.docs[0].ref.update({
            subscriptionTier: 'free',
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      } catch (error) {
        console.error('Error updating subscription in Firestore:', error);
      }
      break;
    }
    
    // Add other webhook handlers as needed
  }

  response.status(200).send({ received: true });
});

/**
 * Change subscription tier (upgrade/downgrade)
 */
exports.changeSubscriptionTier = functions.https.onRequest((request, response) => {
  cors(request, response, async () => {
    try {
      if (request.method !== 'POST') {
        return response.status(405).send({ error: 'Method Not Allowed' });
      }

      const { subscriptionId, newPriceId, prorated, userId } = request.body;

      if (!subscriptionId || !newPriceId || userId === undefined) {
        return response.status(400).send({ 
          error: 'Missing required parameters' 
        });
      }

      // Update subscription with new price
      const subscription = await stripe.subscriptions.retrieve(subscriptionId);
      
      // Check if the customer owns this subscription
      if (subscription.metadata.userId !== userId) {
        return response.status(403).send({ 
          error: 'Not authorized to modify this subscription' 
        });
      }
      
      // Get subscription item ID (typically there's only one item)
      const subscriptionItemId = subscription.items.data[0].id;
      
      // Update the subscription with the new price
      const updatedSubscription = await stripe.subscriptions.update(
        subscriptionId,
        {
          items: [
            {
              id: subscriptionItemId,
              price: newPriceId,
            },
          ],
          proration_behavior: prorated ? 'create_prorations' : 'none',
          metadata: {
            userId,
            firebaseUserId: userId,
            updatedAt: new Date().toISOString(),
          },
        }
      );

      // Return updated subscription details
      response.status(200).send({
        subscriptionId: updatedSubscription.id,
        status: updatedSubscription.status,
        currentPeriodEnd: new Date(updatedSubscription.current_period_end * 1000),
      });
    } catch (error) {
      console.error('Error changing subscription tier:', error);
      response.status(500).send({ error: error.message });
    }
  });
});

/**
 * Request refund for subscription payment
 */
exports.requestRefund = functions.https.onRequest((request, response) => {
  cors(request, response, async () => {
    try {
      if (request.method !== 'POST') {
        return response.status(405).send({ error: 'Method Not Allowed' });
      }

      const { paymentId, subscriptionId, userId, reason, additionalDetails } = request.body;

      if (!paymentId || !subscriptionId || !userId || !reason) {
        return response.status(400).send({ 
          error: 'Missing required parameters' 
        });
      }

      // 1. Verify that the user owns this subscription
      const subscription = await stripe.subscriptions.retrieve(subscriptionId);
      
      if (subscription.metadata.userId !== userId) {
        return response.status(403).send({ 
          error: 'Not authorized to request refund for this subscription' 
        });
      }
      
      // 2. Create a refund in Stripe
      const refund = await stripe.refunds.create({
        payment_intent: paymentId,
        metadata: {
          userId,
          subscriptionId,
          reason,
          additionalDetails: additionalDetails || '',
        }
      });

      // 3. Cancel subscription if it's still active
      if (['active', 'trialing'].includes(subscription.status)) {
        await stripe.subscriptions.cancel(subscriptionId, {
          invoice_now: false,
          prorate: true,
        });
      }

      // 4. Return refund details
      response.status(200).send({
        refundId: refund.id,
        status: refund.status,
      });
    } catch (error) {
      console.error('Error processing refund request:', error);
      response.status(500).send({ error: error.message });
    }
  });
});

/**
 * Check and enforce artwork limits based on subscription tier
 */
exports.checkArtworkLimits = functions.firestore
  .document('artwork/{artworkId}')
  .onCreate(async (snap, context) => {
    const artwork = snap.data();
    const { userId } = artwork;
    
    if (!userId) return;
    
    try {
      // Get user's active subscription
      const subscriptionsRef = admin.firestore().collection('subscriptions');
      const subscriptionsSnapshot = await subscriptionsRef
        .where('userId', '==', userId)
        .where('isActive', '==', true)
        .get();
      
      // If no active subscription, default to free tier
      let tier = 'free';
      
      if (!subscriptionsSnapshot.empty) {
        const subscription = subscriptionsSnapshot.docs[0].data();
        tier = subscription.tier;
      }
      
      // If free tier, check artwork count
      if (tier === 'free') {
        const artworkRef = admin.firestore().collection('artwork');
        const artworkSnapshot = await artworkRef
          .where('userId', '==', userId)
          .get();
        
        // Check if user has exceeded the limit (5 artworks for free tier)
        if (artworkSnapshot.size > 5) {
          // Delete the newest artwork if over limit
          await snap.ref.delete();
          
          // Get user to check notification preferences
          const userRef = admin.firestore().collection('users').doc(userId);
          const userDoc = await userRef.get();
          
          if (userDoc.exists) {
            const userPrefs = (userDoc.data().notificationPreferences || {});
            const notifyOnArtworkLimitReached = userPrefs.notifyOnArtworkLimitReached !== false; // Default to true
            
            if (notifyOnArtworkLimitReached) {
              // Send notification about artwork limit with upgrade info
              await admin.firestore().collection('notifications').add({
                userId: userId,
                type: 'artworkLimitReached',
                content: 'You\'ve reached the artwork limit for the free tier. Upgrade to Artist Pro to add unlimited artwork and get featured in the discover section.',
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                isRead: false,
                artworkId: snap.id,
                additionalData: {
                  currentTier: 'free',
                  suggestedUpgrade: 'standard',
                  artworkCount: artworkSnapshot.size
                }
              });
            }
          }
          
          console.log(`User ${userId} exceeded free tier artwork limit. Artwork ${snap.id} deleted.`);
        }
      }
    } catch (error) {
      console.error('Error checking artwork limits:', error);
    }
  });

/**
 * Check for artists approaching their artwork limits
 * Runs daily at 3:00 AM
 */
exports.checkApproachingArtworkLimits = functions.pubsub
  .schedule('0 3 * * *') // Daily at 3:00 AM
  .timeZone('America/New_York')
  .onRun(async (context) => {
    try {
      // Free tier limit
      const FREE_TIER_LIMIT = 5;
      const WARNING_THRESHOLD = 1; // How many slots left before warning
      
      // Get all users with free tier subscriptions
      const usersSnapshot = await admin.firestore().collection('users')
        .where('userType', '==', 'artist')
        .get();
      
      console.log(`Checking artwork limits for ${usersSnapshot.size} artists`);
      
      const notificationsToCreate = [];
      
      for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;
        
        // Get user's subscription
        const subscriptionsRef = admin.firestore().collection('subscriptions');
        const subscriptionSnapshot = await subscriptionsRef
          .where('userId', '==', userId)
          .where('isActive', '==', true)
          .get();
          
        // Skip if not on free tier
        if (!subscriptionSnapshot.empty) {
          const subscription = subscriptionSnapshot.docs[0].data();
          if (subscription.tier !== 'free') {
            continue;
          }
        }
        
        // Count artwork
        const artworkRef = admin.firestore().collection('artwork');
        const artworkSnapshot = await artworkRef
          .where('userId', '==', userId)
          .get();
          
        const artworkCount = artworkSnapshot.size;
        const slotsRemaining = FREE_TIER_LIMIT - artworkCount;
        
        // If approaching limit, create a notification
        if (slotsRemaining <= WARNING_THRESHOLD && slotsRemaining > 0) {
          const userPrefs = (userDoc.data().notificationPreferences || {});
          const notifyOnArtworkLimitReached = userPrefs.notifyOnArtworkLimitReached !== false; // Default to true
          
          if (notifyOnArtworkLimitReached) {
            notificationsToCreate.push({
              userId,
              type: 'artworkLimitReached',
              content: `You have only ${slotsRemaining} artwork slot${slotsRemaining === 1 ? '' : 's'} remaining on your free tier. Consider upgrading to Artist Pro for unlimited artwork.`,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              isRead: false,
              additionalData: {
                currentTier: 'free',
                suggestedUpgrade: 'standard',
                artworkCount: artworkCount,
                slotsRemaining: slotsRemaining,
                maxSlots: FREE_TIER_LIMIT
              }
            });
          }
        }
      }
      
      // Create notifications in batch
      const batch = admin.firestore().batch();
      const notificationsRef = admin.firestore().collection('notifications');
      
      for (const notification of notificationsToCreate) {
        const newNotificationRef = notificationsRef.doc(); // Auto-generate ID
        batch.set(newNotificationRef, notification);
      }
      
      await batch.commit();
      
      console.log(`Created ${notificationsToCreate.length} approaching artwork limit notifications`);
      
      return null;
    } catch (error) {
      console.error('Error checking approaching artwork limits:', error);
      return null;
    }
  });

/**
 * Handle successful payment intents to update subscription status
 */
exports.handlePaymentSuccess = functions.firestore
  .document('stripe_events/payment_intent.succeeded/{docId}')
  .onCreate(async (snap, context) => {
    try {
      const paymentIntent = snap.data();
      
      // Ignore if no metadata or userId
      if (!paymentIntent.metadata || !paymentIntent.metadata.userId) {
        console.log('No user metadata found in payment intent');
        return;
      }
      
      const { userId, subscriptionTier } = paymentIntent.metadata;
      
      // Update user's payment status
      const userRef = admin.firestore().collection('users').doc(userId);
      const user = await userRef.get();
      
      if (!user.exists) {
        console.error(`User ${userId} not found`);
        return;
      }
      
      // Log payment to payments collection
      const paymentDoc = await admin.firestore().collection('payments').add({
        userId: userId,
        paymentIntentId: paymentIntent.id,
        amount: paymentIntent.amount,
        currency: paymentIntent.currency,
        status: paymentIntent.status,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      console.log(`Payment recorded for user ${userId}`);
      
      // Create a notification for successful payment
      const userPrefs = (user.data().notificationPreferences || {});
      const notifyOnPaymentEvents = userPrefs.notifyOnPaymentEvents !== false; // Default to true if not set
      
      if (notifyOnPaymentEvents) {
        // Format amount for display ($XX.XX)
        const formattedAmount = new Intl.NumberFormat('en-US', {
          style: 'currency',
          currency: paymentIntent.currency.toUpperCase(),
        }).format(paymentIntent.amount / 100);
        
        await admin.firestore().collection('notifications').add({
          userId: userId,
          type: 'paymentSuccess',
          content: `Your payment of ${formattedAmount} was successful.`,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          isRead: false,
          paymentId: paymentDoc.id,
          subscriptionId: paymentIntent.metadata.subscriptionId,
          additionalData: {
            amount: paymentIntent.amount,
            currency: paymentIntent.currency,
          }
        });
      }
    } catch (error) {
      console.error('Error handling payment success:', error);
    }
  });

/**
 * Handle failed payment intents to send notifications
 */
exports.handlePaymentFailure = functions.firestore
  .document('stripe_events/payment_intent.payment_failed/{docId}')
  .onCreate(async (snap, context) => {
    try {
      const paymentIntent = snap.data();
      
      // Ignore if no metadata or userId
      if (!paymentIntent.metadata || !paymentIntent.metadata.userId) {
        console.log('No user metadata found in payment intent');
        return;
      }
      
      const { userId } = paymentIntent.metadata;
      
      // Get user to check notification preferences
      const userRef = admin.firestore().collection('users').doc(userId);
      const user = await userRef.get();
      
      if (!user.exists) {
        console.error(`User ${userId} not found`);
        return;
      }
      
      // Log failed payment
      const paymentDoc = await admin.firestore().collection('payments').add({
        userId: userId,
        paymentIntentId: paymentIntent.id,
        amount: paymentIntent.amount,
        currency: paymentIntent.currency,
        status: 'failed',
        errorMessage: paymentIntent.last_payment_error?.message ?? 'Payment failed',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      console.log(`Failed payment recorded for user ${userId}`);
      
      // Create a notification for failed payment
      const userPrefs = (user.data().notificationPreferences || {});
      const notifyOnPaymentEvents = userPrefs.notifyOnPaymentEvents !== false; // Default to true if not set
      
      if (notifyOnPaymentEvents) {
        // Get subscription details if this is a subscription payment
        let subscriptionDetails = '';
        let subscriptionId = paymentIntent.metadata.subscriptionId;
        
        if (subscriptionId) {
          try {
            const subscription = await stripe.subscriptions.retrieve(subscriptionId);
            if (subscription) {
              // Try to determine subscription tier
              const priceId = subscription.items.data[0]?.price.id ?? '';
              let tier = 'subscription';
              
              if (priceId === STRIPE_PRICES.ARTIST_PRO_MONTHLY) {
                tier = 'Artist Pro';
              } else if (priceId === STRIPE_PRICES.GALLERY_MONTHLY) {
                tier = 'Gallery';
              }
              
              subscriptionDetails = ` for your ${tier}`;
            }
          } catch (e) {
            console.error(`Error getting subscription: ${e}`);
          }
        }
        
        await admin.firestore().collection('notifications').add({
          userId: userId,
          type: 'paymentFailed',
          content: `Your payment${subscriptionDetails} failed. Please update your payment method to continue your service.`,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          isRead: false,
          paymentId: paymentDoc.id,
          subscriptionId: subscriptionId,
          additionalData: {
            amount: paymentIntent.amount,
            currency: paymentIntent.currency,
            errorMessage: paymentIntent.last_payment_error?.message ?? 'Payment failed',
          }
        });
      }
    } catch (error) {
      console.error('Error handling payment failure:', error);
    }
  });

/**
 * Create a setup intent for adding a payment method
 */
exports.createSetupIntent = functions.https.onRequest((request, response) => {
  cors(request, response, async () => {
    try {
      if (request.method !== 'POST') {
        return response.status(405).send({ error: 'Method Not Allowed' });
      }

      const { customerId } = request.body;

      if (!customerId) {
        return response.status(400).send({ 
          error: 'Missing customerId' 
        });
      }

      // Create a setup intent
      const setupIntent = await stripe.setupIntents.create({
        customer: customerId,
        payment_method_types: ['card'],
      });

      // Return client secret
      response.status(200).send({
        clientSecret: setupIntent.client_secret,
      });
    } catch (error) {
      console.error('Error creating setup intent:', error);
      response.status(500).send({ error: error.message });
    }
  });
});

/**
 * Get all payment methods for a customer
 */
exports.getPaymentMethods = functions.https.onRequest((request, response) => {
  cors(request, response, async () => {
    try {
      if (request.method !== 'POST') {
        return response.status(405).send({ error: 'Method Not Allowed' });
      }

      const { customerId } = request.body;

      if (!customerId) {
        return response.status(400).send({ 
          error: 'Missing customerId' 
        });
      }

      // Get payment methods
      const paymentMethods = await stripe.paymentMethods.list({
        customer: customerId,
        type: 'card',
      });

      // Return payment methods
      response.status(200).send({
        paymentMethods: paymentMethods.data,
      });
    } catch (error) {
      console.error('Error getting payment methods:', error);
      response.status(500).send({ error: error.message });
    }
  });
});

/**
 * Detach a payment method from a customer
 */
exports.detachPaymentMethod = functions.https.onRequest((request, response) => {
  cors(request, response, async () => {
    try {
      if (request.method !== 'POST') {
        return response.status(405).send({ error: 'Method Not Allowed' });
      }

      const { paymentMethodId } = request.body;

      if (!paymentMethodId) {
        return response.status(400).send({ 
          error: 'Missing paymentMethodId' 
        });
      }

      // Detach payment method
      const paymentMethod = await stripe.paymentMethods.detach(paymentMethodId);

      // Return success
      response.status(200).send({
        paymentMethod: paymentMethod,
        success: true,
      });
    } catch (error) {
      console.error('Error detaching payment method:', error);
      response.status(500).send({ error: error.message });
    }
  });
});

/**
 * Update customer's default payment method
 */
exports.updateCustomer = functions.https.onRequest((request, response) => {
  cors(request, response, async () => {
    try {
      if (request.method !== 'POST') {
        return response.status(405).send({ error: 'Method Not Allowed' });
      }

      const { customerId, defaultPaymentMethod } = request.body;

      if (!customerId || !defaultPaymentMethod) {
        return response.status(400).send({ 
          error: 'Missing required fields' 
        });
      }

      // Update customer
      const customer = await stripe.customers.update(
        customerId,
        { invoice_settings: { default_payment_method: defaultPaymentMethod } }
      );

      // Return success
      response.status(200).send({
        customer: customer,
        success: true,
      });
    } catch (error) {
      console.error('Error updating customer:', error);
      response.status(500).send({ error: error.message });
    }
  });
});

/**
 * Create a new customer in Stripe
 */
exports.createCustomer = functions.https.onRequest((request, response) => {
  cors(request, response, async () => {
    try {
      if (request.method !== 'POST') {
        return response.status(405).send({ error: 'Method Not Allowed' });
      }

      const { email, userId } = request.body;

      if (!email || !userId) {
        return response.status(400).send({ 
          error: 'Missing required fields' 
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
      response.status(200).send({
        customerId: customer.id,
        success: true,
      });
    } catch (error) {
      console.error('Error creating customer:', error);
      response.status(500).send({ error: error.message });
    }
  });
});

/**
 * Scheduled function to check for expiring subscriptions and send reminders
 * Runs daily at midnight
 */
exports.checkExpiringSubscriptions = functions.pubsub
  .schedule('0 0 * * *') // Daily at midnight
  .timeZone('America/New_York')
  .onRun(async (context) => {
    try {
      const now = admin.firestore.Timestamp.now();
      const oneWeekFromNow = new admin.firestore.Timestamp(
        now.seconds + (7 * 24 * 60 * 60), // 7 days in seconds
        now.nanoseconds
      );
      
      // Get subscriptions that are set to expire in about a week
      const subscriptionsRef = admin.firestore().collection('subscriptions');
      const expiringSubscriptions = await subscriptionsRef
        .where('isActive', '==', true)
        .where('autoRenew', '==', false) // Only notify about non-autorenewing subscriptions
        .where('endDate', '>=', now)
        .where('endDate', '<=', oneWeekFromNow)
        .get();
        
      console.log(`Found ${expiringSubscriptions.size} subscriptions expiring soon`);
      
      // Process each expiring subscription
      const batch = admin.firestore().batch();
      const notificationsToCreate = [];
      
      for (const doc of expiringSubscriptions.docs) {
        const subscription = doc.data();
        const userId = subscription.userId;
        const tier = subscription.tier;
        
        // Skip if notified already (using a marker we'll set)
        if (subscription.expiryNotificationSent) {
          continue;
        }
        
        // Get user to check notification preferences
        const userRef = admin.firestore().collection('users').doc(userId);
        const userDoc = await userRef.get();
        
        if (!userDoc.exists) {
          console.log(`User ${userId} not found, skipping notification`);
          continue;
        }
        
        const userPrefs = (userDoc.data().notificationPreferences || {});
        const notifyOnSubscriptionCancelled = userPrefs.notifyOnSubscriptionCancelled !== false; // Default to true
        
        if (notifyOnSubscriptionCancelled) {
          // Get human-readable tier names
          const tierDisplayNames = {
            'free': 'Artist Basic (Free)',
            'standard': 'Artist Pro',
            'premium': 'Gallery'
          };
          
          // Format expiration date
          const endDate = subscription.endDate.toDate();
          const formattedEndDate = endDate.toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'long',
            day: 'numeric'
          });
          
          // Create notification
          notificationsToCreate.push({
            userId,
            type: 'subscriptionCancelled',
            content: `Your ${tierDisplayNames[tier] || tier} subscription will expire on ${formattedEndDate}. Renew now to maintain your benefits.`,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            isRead: false,
            subscriptionId: doc.id,
            additionalData: {
              tier,
              endDate: endDate.toISOString(),
            }
          });
          
          // Mark subscription as notified
          batch.update(doc.ref, { 
            expiryNotificationSent: true,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
        }
      }
      
      // Add all notifications
      const notificationsRef = admin.firestore().collection('notifications');
      for (const notification of notificationsToCreate) {
        const newNotificationRef = notificationsRef.doc(); // Auto-generate ID
        batch.set(newNotificationRef, notification);
      }
      
      // Commit all updates
      await batch.commit();
      
      console.log(`Sent ${notificationsToCreate.length} subscription expiration notifications`);
      
      return null;
    } catch (error) {
      console.error('Error checking expiring subscriptions:', error);
      return null;
    }
  });
