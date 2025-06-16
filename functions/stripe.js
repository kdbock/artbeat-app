const functions = require('firebase-functions');
const admin = require('firebase-admin');
const stripe = require('stripe')(functions.config().stripe.secret_key);
const cors = require('cors')({ origin: true });

const STRIPE_PRICES = {
  ARTIST_PRO_MONTHLY: 'price_artist_pro_monthly', // Replace with your actual Stripe price ID
  GALLERY_MONTHLY: 'price_gallery_monthly', // Replace with your actual Stripe price ID
};

const TIER_DISPLAY_NAMES = {
  'free': 'Artist Basic (Free)',
  'standard': 'Artist Pro',
  'premium': 'Gallery'
};

const TIER_MAP = {
  [STRIPE_PRICES.ARTIST_PRO_MONTHLY]: 'standard',
  [STRIPE_PRICES.GALLERY_MONTHLY]: 'premium',
};

/**
 * Create a Stripe customer
 */
exports.createCustomer = functions.https.onRequest((request, response) => {
  cors(request, response, async () => {
    try {
      if (request.method !== 'POST') {
        return response.status(405).send({ error: 'Method Not Allowed' });
      }

      const { email, name, metadata } = request.body;

      if (!email || !name || !metadata?.userId) {
        return response.status(400).send({ 
          error: 'Missing required parameters' 
        });
      }

      // Create customer in Stripe
      const customer = await stripe.customers.create({
        email,
        name,
        metadata,
      });

      // Store Stripe customer ID in Firestore
      await admin.firestore().collection('users')
        .doc(metadata.userId)
        .update({
          stripeCustomerId: customer.id,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      response.status(200).send({
        customerId: customer.id,
      });
    } catch (error) {
      console.error('Error creating customer:', error);
      response.status(500).send({ error: error.message });
    }
  });
});

/**
 * Create a subscription
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
 * Change subscription tier
 */
exports.changeSubscriptionTier = functions.https.onRequest((request, response) => {
  cors(request, response, async () => {
    try {
      if (request.method !== 'POST') {
        return response.status(405).send({ error: 'Method Not Allowed' });
      }

      const { subscriptionId, newPriceId, userId, prorated } = request.body;

      if (!subscriptionId || !newPriceId || !userId) {
        return response.status(400).send({ 
          error: 'Missing required parameters' 
        });
      }

      // Get current subscription to verify ownership
      const subscription = await stripe.subscriptions.retrieve(subscriptionId);
      if (subscription.metadata.userId !== userId) {
        return response.status(403).send({ 
          error: 'Not authorized to modify this subscription' 
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
          proration_behavior: prorated ? 'create_prorations' : 'none',
          metadata: {
            userId,
            firebaseUserId: userId,
            updatedAt: new Date().toISOString(),
          },
        }
      );

      response.status(200).send({
        subscriptionId: updatedSubscription.id,
        status: updatedSubscription.status,
      });
    } catch (error) {
      console.error('Error changing subscription tier:', error);
      response.status(500).send({ error: error.message });
    }
  });
});

/**
 * Cancel subscription
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

      // Cancel at period end
      const subscription = await stripe.subscriptions.update(
        subscriptionId,
        { cancel_at_period_end: true }
      );

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
 * Create a setup intent for adding payment methods
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

      const setupIntent = await stripe.setupIntents.create({
        customer: customerId,
        payment_method_types: ['card'],
      });

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
 * Request a refund
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

      // Verify subscription ownership
      const subscription = await stripe.subscriptions.retrieve(subscriptionId);
      if (subscription.metadata.userId !== userId) {
        return response.status(403).send({ 
          error: 'Not authorized to request refund for this subscription' 
        });
      }

      // Create refund
      const refund = await stripe.refunds.create({
        payment_intent: paymentId,
        metadata: {
          userId,
          subscriptionId,
          reason,
          additionalDetails: additionalDetails || '',
        }
      });

      // Cancel subscription if active
      if (['active', 'trialing'].includes(subscription.status)) {
        await stripe.subscriptions.cancel(subscriptionId, {
          invoice_now: false,
          prorate: true,
        });
      }

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
 * Webhook handler for Stripe events
 */
exports.stripeWebhook = functions.https.onRequest(async (request, response) => {
  try {
    const signature = request.headers['stripe-signature'];
    const webhookSecret = functions.config().stripe.webhook_secret;

    // Verify webhook signature
    let event;
    try {
      event = stripe.webhooks.constructEvent(
        request.rawBody,
        signature,
        webhookSecret
      );
    } catch (err) {
      response.status(400).send(`Webhook Error: ${err.message}`);
      return;
    }

    // Handle webhook events
    switch (event.type) {
      case 'customer.subscription.created':
      case 'customer.subscription.updated': {
        const subscription = event.data.object;
        const { userId } = subscription.metadata;
        const isActive = ['active', 'trialing'].includes(subscription.status);
        const currentPeriodEnd = new Date(subscription.current_period_end * 1000);

        // Update subscription in Firestore
        if (userId && subscription.items.data[0]?.price) {
          const subscriptionsRef = admin.firestore().collection('subscriptions');
          const existingSubscriptions = await subscriptionsRef
            .where('stripeSubscriptionId', '==', subscription.id)
            .get();

          const tier = TIER_MAP[subscription.items.data[0].price.id] || 'free';

          if (existingSubscriptions.empty) {
            // Create new subscription document
            await subscriptionsRef.add({
              userId,
              tier,
              stripeSubscriptionId: subscription.id,
              stripePriceId: subscription.items.data[0].price.id,
              startDate: admin.firestore.Timestamp.now(),
              endDate: admin.firestore.Timestamp.fromDate(currentPeriodEnd),
              isActive,
              autoRenew: !subscription.cancel_at_period_end,
              createdAt: admin.firestore.Timestamp.serverTimestamp(),
              updatedAt: admin.firestore.Timestamp.serverTimestamp(),
            });
          } else {
            // Update existing subscription
            await existingSubscriptions.docs[0].ref.update({
              tier,
              stripePriceId: subscription.items.data[0].price.id,
              isActive,
              endDate: admin.firestore.Timestamp.fromDate(currentPeriodEnd),
              autoRenew: !subscription.cancel_at_period_end,
              updatedAt: admin.firestore.Timestamp.serverTimestamp(),
            });
          }

          // Update artist profile
          const artistProfilesRef = admin.firestore().collection('artistProfiles');
          const artistProfiles = await artistProfilesRef
            .where('userId', '==', userId)
            .get();

          if (!artistProfiles.empty) {
            await artistProfiles.docs[0].ref.update({
              subscriptionTier: tier,
              updatedAt: admin.firestore.Timestamp.serverTimestamp(),
            });
          }
        }
        break;
      }

      case 'customer.subscription.deleted': {
        const subscription = event.data.object;
        const { userId } = subscription.metadata;

        if (userId) {
          const subscriptionsRef = admin.firestore().collection('subscriptions');
          const existingSubscriptions = await subscriptionsRef
            .where('stripeSubscriptionId', '==', subscription.id)
            .get();

          if (!existingSubscriptions.empty) {
            const existingSubscription = existingSubscriptions.docs[0].data();
            const previousTier = existingSubscription.tier;

            // Update subscription to inactive
            await existingSubscriptions.docs[0].ref.update({
              isActive: false,
              autoRenew: false,
              updatedAt: admin.firestore.Timestamp.serverTimestamp(),
            });

            // Check notification preferences
            const userDoc = await admin.firestore()
              .collection('users')
              .doc(userId)
              .get();

            if (userDoc.exists) {
              const userPrefs = userDoc.data().notificationPreferences || {};
              const notifyOnSubscriptionCancelled = userPrefs.notifyOnSubscriptionCancelled !== false;

              if (notifyOnSubscriptionCancelled) {
                await admin.firestore().collection('notifications').add({
                  userId,
                  type: 'subscriptionCancelled',
                  content: `Your ${TIER_DISPLAY_NAMES[previousTier]} subscription has been cancelled. Your subscription benefits will end on ${new Date(subscription.current_period_end * 1000).toLocaleDateString()}.`,
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
            await artistProfiles.docs[0].ref.update({
              subscriptionTier: 'free',
              updatedAt: admin.firestore.Timestamp.serverTimestamp(),
            });
          }
        }
        break;
      }

      case 'payment_intent.succeeded': {
        const paymentIntent = event.data.object;
        const { userId } = paymentIntent.metadata;

        if (userId) {
          // Log successful payment
          const paymentDoc = await admin.firestore().collection('payments').add({
            userId,
            paymentIntentId: paymentIntent.id,
            amount: paymentIntent.amount,
            currency: paymentIntent.currency,
            status: 'succeeded',
            createdAt: admin.firestore.Timestamp.serverTimestamp(),
          });

          // Create payment success notification
          const userDoc = await admin.firestore()
            .collection('users')
            .doc(userId)
            .get();

          if (userDoc.exists) {
            const userPrefs = userDoc.data().notificationPreferences || {};
            const notifyOnPaymentEvents = userPrefs.notifyOnPaymentEvents !== false;

            if (notifyOnPaymentEvents) {
              await admin.firestore().collection('notifications').add({
                userId,
                type: 'paymentSuccess',
                content: `Your payment of ${(paymentIntent.amount / 100).toFixed(2)} ${paymentIntent.currency.toUpperCase()} was successful.`,
                createdAt: admin.firestore.Timestamp.serverTimestamp(),
                isRead: false,
                paymentId: paymentDoc.id,
                subscriptionId: paymentIntent.metadata.subscriptionId,
                additionalData: {
                  amount: paymentIntent.amount,
                  currency: paymentIntent.currency,
                }
              });
            }
          }
        }
        break;
      }

      case 'payment_intent.payment_failed': {
        const paymentIntent = event.data.object;
        const { userId } = paymentIntent.metadata;

        if (userId) {
          // Log failed payment
          const paymentDoc = await admin.firestore().collection('payments').add({
            userId,
            paymentIntentId: paymentIntent.id,
            amount: paymentIntent.amount,
            currency: paymentIntent.currency,
            status: 'failed',
            errorMessage: paymentIntent.last_payment_error?.message ?? 'Payment failed',
            createdAt: admin.firestore.Timestamp.serverTimestamp(),
          });

          // Create payment failure notification
          const userDoc = await admin.firestore()
            .collection('users')
            .doc(userId)
            .get();

          if (userDoc.exists) {
            const userPrefs = userDoc.data().notificationPreferences || {};
            const notifyOnPaymentEvents = userPrefs.notifyOnPaymentEvents !== false;

            if (notifyOnPaymentEvents) {
              let subscriptionDetails = '';
              const subscriptionId = paymentIntent.metadata.subscriptionId;

              if (subscriptionId) {
                try {
                  const subscription = await stripe.subscriptions.retrieve(subscriptionId);
                  if (subscription) {
                    const priceId = subscription.items.data[0]?.price.id;
                    const tier = TIER_MAP[priceId] || 'subscription';
                    subscriptionDetails = ` for your ${TIER_DISPLAY_NAMES[tier]}`;
                  }
                } catch (e) {
                  console.error(`Error getting subscription: ${e}`);
                }
              }

              await admin.firestore().collection('notifications').add({
                userId,
                type: 'paymentFailed',
                content: `Your payment${subscriptionDetails} failed. Please update your payment method to continue your service.`,
                createdAt: admin.firestore.Timestamp.serverTimestamp(),
                isRead: false,
                paymentId: paymentDoc.id,
                subscriptionId,
                additionalData: {
                  amount: paymentIntent.amount,
                  currency: paymentIntent.currency,
                  errorMessage: paymentIntent.last_payment_error?.message ?? 'Payment failed',
                }
              });
            }
          }
        }
        break;
      }
    }

    response.json({ received: true });
  } catch (error) {
    console.error('Webhook error:', error);
    response.status(500).send('Webhook error');
  }
});

/**
 * Process a gift payment
 */
exports.processGiftPayment = functions.https.onRequest((request, response) => {
  cors(request, response, async () => {
    try {
      if (request.method !== 'POST') {
        return response.status(405).send({ error: 'Method Not Allowed' });
      }

      const { senderId, recipientId, amount, paymentMethodId, message } = request.body;

      if (!senderId || !recipientId || !amount || !paymentMethodId) {
        return response.status(400).send({ 
          error: 'Missing required parameters' 
        });
      }

      // Get sender's customer ID from Firestore
      const senderDoc = await admin.firestore().collection('users')
        .doc(senderId)
        .get();

      if (!senderDoc.exists) {
        return response.status(404).send({ error: 'Sender not found' });
      }

      const customerId = senderDoc.data().stripeCustomerId;
      if (!customerId) {
        return response.status(400).send({ error: 'Sender has no payment setup' });
      }

      // Create a payment intent
      const paymentIntent = await stripe.paymentIntents.create({
        amount: Math.round(amount * 100), // Convert to cents
        currency: 'usd',
        customer: customerId,
        payment_method: paymentMethodId,
        off_session: true,
        confirm: true,
        metadata: {
          type: 'gift',
          senderId,
          recipientId,
          message: message || '',
        },
      });

      // Return the payment intent details
      return response.status(200).send({
        paymentIntentId: paymentIntent.id,
        status: paymentIntent.status,
        amount: paymentIntent.amount / 100,
      });

    } catch (error) {
      console.error('Error processing gift payment:', error);
      return response.status(500).send({ error: error.message });
    }
  });
});
