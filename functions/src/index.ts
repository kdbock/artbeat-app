import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import cors from 'cors';

const stripe = require('stripe')(functions.config().stripe.secret_key);
const corsHandler = cors({ origin: true });

admin.initializeApp();

/**
 * Create a new customer in Stripe
 */
export const createCustomer = functions.https.onRequest((request, response) => {
  return corsHandler(request, response, async () => {
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
      return response.status(200).send({
        customerId: customer.id,
        success: true,
      });
    } catch (error) {
      console.error('Error creating customer:', error);
      return response.status(500).send({ error: (error as Error).message });
    }
  });
});

/**
 * Create a setup intent for adding payment methods
 */
export const createSetupIntent = functions.https.onRequest((request, response) => {
  return corsHandler(request, response, async () => {
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

      return response.status(200).send({
        clientSecret: setupIntent.client_secret,
      });
    } catch (error) {
      console.error('Error creating setup intent:', error);
      return response.status(500).send({ error: (error as Error).message });
    }
  });
});

/**
 * Get customer's saved payment methods
 */
export const getPaymentMethods = functions.https.onRequest((request, response) => {
  return corsHandler(request, response, async () => {
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

      const paymentMethods = await stripe.paymentMethods.list({
        customer: customerId,
        type: 'card',
      });

      return response.status(200).send({
        paymentMethods: paymentMethods.data,
      });
    } catch (error) {
      console.error('Error getting payment methods:', error);
      return response.status(500).send({ error: (error as Error).message });
    }
  });
});

/**
 * Update customer (e.g., set default payment method)
 */
export const updateCustomer = functions.https.onRequest((request, response) => {
  return corsHandler(request, response, async () => {
    try {
      if (request.method !== 'POST') {
        return response.status(405).send({ error: 'Method Not Allowed' });
      }

      const { customerId, defaultPaymentMethod } = request.body;

      if (!customerId) {
        return response.status(400).send({ 
          error: 'Missing customerId' 
        });
      }

      const customer = await stripe.customers.update(
        customerId,
        { 
          invoice_settings: { 
            default_payment_method: defaultPaymentMethod 
          } 
        }
      );

      return response.status(200).send({
        customer: customer.id,
        success: true,
      });
    } catch (error) {
      console.error('Error updating customer:', error);
      return response.status(500).send({ error: (error as Error).message });
    }
  });
});

/**
 * Detach a payment method from a customer
 */
export const detachPaymentMethod = functions.https.onRequest((request, response) => {
  return corsHandler(request, response, async () => {
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

      const paymentMethod = await stripe.paymentMethods.detach(paymentMethodId);

      return response.status(200).send({
        paymentMethod: paymentMethod.id,
        success: true,
      });
    } catch (error) {
      console.error('Error detaching payment method:', error);
      return response.status(500).send({ error: (error as Error).message });
    }
  });
});

/**
 * Create subscription in Stripe
 */
export const createSubscription = functions.https.onRequest((request, response) => {
  return corsHandler(request, response, async () => {
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
      return response.status(200).send({
        subscriptionId: subscription.id,
        status: subscription.status,
        clientSecret: subscription.latest_invoice.payment_intent?.client_secret ?? '',
      });
    } catch (error) {
      console.error('Error creating subscription:', error);
      return response.status(500).send({ error: (error as Error).message });
    }
  });
});

/**
 * Cancel subscription in Stripe
 */
export const cancelSubscription = functions.https.onRequest((request, response) => {
  return corsHandler(request, response, async () => {
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
      return response.status(200).send({
        subscriptionId: subscription.id,
        status: subscription.status,
        cancelAtPeriodEnd: subscription.cancel_at_period_end,
      });
    } catch (error) {
      console.error('Error cancelling subscription:', error);
      return response.status(500).send({ error: (error as Error).message });
    }
  });
});

/**
 * Change subscription tier
 */
export const changeSubscriptionTier = functions.https.onRequest((request, response) => {
  return corsHandler(request, response, async () => {
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

      return response.status(200).send({
        subscriptionId: updatedSubscription.id,
        status: updatedSubscription.status,
      });
    } catch (error) {
      console.error('Error changing subscription tier:', error);
      return response.status(500).send({ error: (error as Error).message });
    }
  });
});

/**
 * Request a refund
 */
export const requestRefund = functions.https.onRequest((request, response) => {
  return corsHandler(request, response, async () => {
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

      return response.status(200).send({
        refundId: refund.id,
        status: refund.status,
      });
    } catch (error) {
      console.error('Error processing refund request:', error);
      return response.status(500).send({ error: (error as Error).message });
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
      'admin_ads/ARFuyX0C44PbYlHSUSlQx55b9vt2/1755734362607_upload.png',
      'admin_ads/ARFuyX0C44PbYlHSUSlQx55b9vt2/1755734362608_upload.png',
      'admin_ads/ARFuyX0C44PbYlHSUSlQx55b9vt2/1755734362609_upload.png',
      'admin_ads/ARFuyX0C44PbYlHSUSlQx55b9vt2/1755734362610_upload.png',
    ];

    // Generate fresh download URLs for all images
    const freshUrls: string[] = [];
    
    for (const imagePath of imagePaths) {
      try {
        const file = storage.bucket().file(imagePath);
        
        // Generate a signed URL that expires in 1 year
        const [url] = await file.getSignedUrl({
          action: 'read',
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
      throw new Error('Failed to generate any fresh URLs');
    }

    // Get all ads in the collection
    const adsSnapshot = await db.collection('ads').get();
    let updatedCount = 0;

    for (const doc of adsSnapshot.docs) {
      // Update imageUrl to first fresh URL and set artworkUrls to all fresh URLs
      await doc.ref.update({
        imageUrl: freshUrls[0],
        artworkUrls: freshUrls.join(','),
      });
      
      updatedCount++;
      console.log(`Updated ad ${doc.id} with fresh Firebase Storage URLs`);
    }

    res.json({ 
      success: true, 
      message: `Updated ${updatedCount} ads with ${freshUrls.length} fresh Firebase Storage URLs`,
      urls: freshUrls
    });

  } catch (error: any) {
    console.error('Error fixing admin ads:', error);
    res.status(500).json({ error: error.message });
  }
});