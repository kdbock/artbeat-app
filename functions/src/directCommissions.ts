import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import Stripe from 'stripe';

const stripe = new Stripe(functions.config().stripe.secret_key, {
  apiVersion: '2023-10-16',
});

const db = admin.firestore();

export interface DirectCommissionData {
  id: string;
  clientId: string;
  clientName: string;
  artistId: string;
  artistName: string;
  title: string;
  description: string;
  type: string;
  specs: {
    size: string;
    medium: string;
    style: string;
    colorScheme: string;
    revisions: number;
    commercialUse: boolean;
    deliveryFormat: string;
    customRequirements: Record<string, any>;
  };
  status: string;
  basePrice: number;
  totalPrice: number;
  depositAmount: number;
  finalAmount: number;
  milestones: Array<{
    id: string;
    title: string;
    description: string;
    amount: number;
    dueDate: string;
    status: string;
    completedAt?: string;
    paymentIntentId?: string;
  }>;
  messages: Array<{
    id: string;
    senderId: string;
    senderName: string;
    message: string;
    timestamp: string;
    attachments: string[];
  }>;
  files: Array<{
    id: string;
    name: string;
    url: string;
    type: string;
    sizeBytes: number;
    uploadedAt: string;
    uploadedBy: string;
    description?: string;
  }>;
  metadata: {
    requestedAt: string;
    quotedAt?: string;
    acceptedAt?: string;
    startedAt?: string;
    completedAt?: string;
    deliveredAt?: string;
  };
  createdAt: string;
  updatedAt: string;
}

/**
 * Create a new commission request
 */
export const createCommissionRequest = functions.https.onCall(
  async (data, context) => {
    try {
      // Verify authentication
      if (!context.auth) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'User must be authenticated'
        );
      }

      const {
        artistId,
        title,
        description,
        type,
        specs,
        basePrice,
        depositAmount,
        finalAmount,
        milestones,
      } = data;

      // Validate required fields
      if (!artistId || !title || !description || !type || !specs) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Missing required fields'
        );
      }

      // Get client and artist information
      const clientDoc = await db.collection('users').doc(context.auth.uid).get();
      const artistDoc = await db.collection('users').doc(artistId).get();

      if (!clientDoc.exists || !artistDoc.exists) {
        throw new functions.https.HttpsError(
          'not-found',
          'Client or artist not found'
        );
      }

      const clientData = clientDoc.data();
      const artistData = artistDoc.data();

      // Create commission document
      const commissionRef = db.collection('direct_commissions').doc();
      const commissionData: DirectCommissionData = {
        id: commissionRef.id,
        clientId: context.auth.uid,
        clientName: clientData?.name || clientData?.displayName || 'Unknown Client',
        artistId,
        artistName: artistData?.name || artistData?.displayName || 'Unknown Artist',
        title,
        description,
        type,
        specs,
        status: 'pending',
        basePrice: basePrice || 0,
        totalPrice: basePrice || 0,
        depositAmount: depositAmount || 0,
        finalAmount: finalAmount || 0,
        milestones: milestones || [],
        messages: [],
        files: [],
        metadata: {
          requestedAt: new Date().toISOString(),
        },
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };

      await commissionRef.set(commissionData);

      // Send notification to artist
      await sendCommissionNotification(artistId, 'new_request', {
        commissionId: commissionRef.id,
        clientName: commissionData.clientName,
        title,
      });

      return { commissionId: commissionRef.id };
    } catch (error) {
      console.error('Error creating commission request:', error);
      throw new functions.https.HttpsError(
        'internal',
        'Failed to create commission request'
      );
    }
  }
);

/**
 * Submit a quote for a commission
 */
export const submitCommissionQuote = functions.https.onCall(
  async (data, context) => {
    try {
      if (!context.auth) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'User must be authenticated'
        );
      }

      const { commissionId, totalPrice, depositAmount, finalAmount, milestones, message } = data;

      if (!commissionId || !totalPrice) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Missing required fields'
        );
      }

      const commissionRef = db.collection('direct_commissions').doc(commissionId);
      const commissionDoc = await commissionRef.get();

      if (!commissionDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Commission not found');
      }

      const commission = commissionDoc.data() as DirectCommissionData;

      // Verify the user is the artist
      if (commission.artistId !== context.auth.uid) {
        throw new functions.https.HttpsError(
          'permission-denied',
          'Only the artist can submit a quote'
        );
      }

      // Update commission with quote
      await commissionRef.update({
        status: 'quoted',
        totalPrice,
        depositAmount: depositAmount || totalPrice * 0.5, // Default 50% deposit
        finalAmount: finalAmount || totalPrice * 0.5,
        milestones: milestones || [],
        'metadata.quotedAt': new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      });

      // Add quote message
      if (message) {
        await addCommissionMessage(commissionId, context.auth.uid, message);
      }

      // Notify client
      await sendCommissionNotification(commission.clientId, 'quote_received', {
        commissionId,
        artistName: commission.artistName,
        totalPrice,
      });

      return { success: true };
    } catch (error) {
      console.error('Error submitting quote:', error);
      throw new functions.https.HttpsError('internal', 'Failed to submit quote');
    }
  }
);

/**
 * Accept a commission quote and create payment intent for deposit
 */
export const acceptCommissionQuote = functions.https.onCall(
  async (data, context) => {
    try {
      if (!context.auth) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'User must be authenticated'
        );
      }

      const { commissionId } = data;

      if (!commissionId) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Commission ID is required'
        );
      }

      const commissionRef = db.collection('direct_commissions').doc(commissionId);
      const commissionDoc = await commissionRef.get();

      if (!commissionDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Commission not found');
      }

      const commission = commissionDoc.data() as DirectCommissionData;

      // Verify the user is the client
      if (commission.clientId !== context.auth.uid) {
        throw new functions.https.HttpsError(
          'permission-denied',
          'Only the client can accept the quote'
        );
      }

      // Get client's Stripe customer ID
      const clientDoc = await db.collection('users').doc(context.auth.uid).get();
      const clientData = clientDoc.data();
      let customerId = clientData?.stripeCustomerId;

      if (!customerId) {
        // Create Stripe customer
        const customer = await stripe.customers.create({
          email: context.auth.token.email,
          name: commission.clientName,
          metadata: {
            userId: context.auth.uid,
          },
        });
        customerId = customer.id;

        // Save customer ID
        await db.collection('users').doc(context.auth.uid).update({
          stripeCustomerId: customerId,
        });
      }

      // Create payment intent for deposit
      const paymentIntent = await stripe.paymentIntents.create({
        amount: Math.round(commission.depositAmount * 100), // Convert to cents
        currency: 'usd',
        customer: customerId,
        metadata: {
          commissionId,
          type: 'deposit',
          clientId: commission.clientId,
          artistId: commission.artistId,
        },
        description: `Commission deposit for "${commission.title}"`,
      });

      // Update commission status
      await commissionRef.update({
        status: 'accepted',
        'metadata.acceptedAt': new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      });

      // Notify artist
      await sendCommissionNotification(commission.artistId, 'quote_accepted', {
        commissionId,
        clientName: commission.clientName,
      });

      return {
        success: true,
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
      };
    } catch (error) {
      console.error('Error accepting quote:', error);
      throw new functions.https.HttpsError('internal', 'Failed to accept quote');
    }
  }
);

/**
 * Handle successful deposit payment
 */
export const handleDepositPayment = functions.https.onCall(
  async (data, context) => {
    try {
      if (!context.auth) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'User must be authenticated'
        );
      }

      const { paymentIntentId } = data;

      if (!paymentIntentId) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Payment intent ID is required'
        );
      }

      // Retrieve payment intent from Stripe
      const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);

      if (paymentIntent.status !== 'succeeded') {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Payment has not succeeded'
        );
      }

      const commissionId = paymentIntent.metadata.commissionId;
      const commissionRef = db.collection('direct_commissions').doc(commissionId);
      const commissionDoc = await commissionRef.get();

      if (!commissionDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Commission not found');
      }

      const commission = commissionDoc.data() as DirectCommissionData;

      // Update commission status to in progress
      await commissionRef.update({
        status: 'inProgress',
        'metadata.startedAt': new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      });

      // Create earnings record for artist
      await createEarningsRecord({
        userId: commission.artistId,
        type: 'commission_deposit',
        amount: commission.depositAmount,
        commissionId,
        paymentIntentId,
        description: `Commission deposit for "${commission.title}"`,
      });

      // Notify artist that work can begin
      await sendCommissionNotification(commission.artistId, 'deposit_received', {
        commissionId,
        clientName: commission.clientName,
        amount: commission.depositAmount,
      });

      return { success: true };
    } catch (error) {
      console.error('Error handling deposit payment:', error);
      throw new functions.https.HttpsError(
        'internal',
        'Failed to handle deposit payment'
      );
    }
  }
);

/**
 * Complete commission and request final payment
 */
export const completeCommission = functions.https.onCall(
  async (data, context) => {
    try {
      if (!context.auth) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'User must be authenticated'
        );
      }

      const { commissionId, deliveryFiles } = data;

      if (!commissionId) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Commission ID is required'
        );
      }

      const commissionRef = db.collection('direct_commissions').doc(commissionId);
      const commissionDoc = await commissionRef.get();

      if (!commissionDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Commission not found');
      }

      const commission = commissionDoc.data() as DirectCommissionData;

      // Verify the user is the artist
      if (commission.artistId !== context.auth.uid) {
        throw new functions.https.HttpsError(
          'permission-denied',
          'Only the artist can complete the commission'
        );
      }

      // Update commission status
      await commissionRef.update({
        status: 'completed',
        'metadata.completedAt': new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      });

      // Add delivery files if provided
      if (deliveryFiles && deliveryFiles.length > 0) {
        await commissionRef.update({
          files: admin.firestore.FieldValue.arrayUnion(...deliveryFiles),
        });
      }

      // Create payment intent for final payment if there's a remaining balance
      let finalPaymentIntent = null;
      if (commission.finalAmount > 0) {
        const clientDoc = await db.collection('users').doc(commission.clientId).get();
        const clientData = clientDoc.data();
        const customerId = clientData?.stripeCustomerId;

        if (customerId) {
          finalPaymentIntent = await stripe.paymentIntents.create({
            amount: Math.round(commission.finalAmount * 100),
            currency: 'usd',
            customer: customerId,
            metadata: {
              commissionId,
              type: 'final_payment',
              clientId: commission.clientId,
              artistId: commission.artistId,
            },
            description: `Final payment for commission "${commission.title}"`,
          });
        }
      }

      // Notify client
      await sendCommissionNotification(commission.clientId, 'commission_completed', {
        commissionId,
        artistName: commission.artistName,
        finalAmount: commission.finalAmount,
      });

      return {
        success: true,
        finalPaymentClientSecret: finalPaymentIntent?.client_secret,
        finalPaymentIntentId: finalPaymentIntent?.id,
      };
    } catch (error) {
      console.error('Error completing commission:', error);
      throw new functions.https.HttpsError('internal', 'Failed to complete commission');
    }
  }
);

/**
 * Handle final payment and deliver commission
 */
export const handleFinalPayment = functions.https.onCall(
  async (data, context) => {
    try {
      if (!context.auth) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'User must be authenticated'
        );
      }

      const { paymentIntentId } = data;

      if (!paymentIntentId) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Payment intent ID is required'
        );
      }

      // Retrieve payment intent from Stripe
      const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);

      if (paymentIntent.status !== 'succeeded') {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Payment has not succeeded'
        );
      }

      const commissionId = paymentIntent.metadata.commissionId;
      const commissionRef = db.collection('direct_commissions').doc(commissionId);
      const commissionDoc = await commissionRef.get();

      if (!commissionDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Commission not found');
      }

      const commission = commissionDoc.data() as DirectCommissionData;

      // Update commission status to delivered
      await commissionRef.update({
        status: 'delivered',
        'metadata.deliveredAt': new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      });

      // Create earnings record for artist
      await createEarningsRecord({
        userId: commission.artistId,
        type: 'commission_final',
        amount: commission.finalAmount,
        commissionId,
        paymentIntentId,
        description: `Final payment for commission "${commission.title}"`,
      });

      // Notify both parties
      await sendCommissionNotification(commission.artistId, 'final_payment_received', {
        commissionId,
        clientName: commission.clientName,
        amount: commission.finalAmount,
      });

      await sendCommissionNotification(commission.clientId, 'commission_delivered', {
        commissionId,
        artistName: commission.artistName,
      });

      return { success: true };
    } catch (error) {
      console.error('Error handling final payment:', error);
      throw new functions.https.HttpsError(
        'internal',
        'Failed to handle final payment'
      );
    }
  }
);

/**
 * Add a message to a commission
 */
async function addCommissionMessage(
  commissionId: string,
  senderId: string,
  message: string
): Promise<void> {
  const senderDoc = await db.collection('users').doc(senderId).get();
  const senderData = senderDoc.data();
  const senderName = senderData?.name || senderData?.displayName || 'Unknown User';

  const messageObj = {
    id: db.collection('temp').doc().id,
    senderId,
    senderName,
    message,
    timestamp: new Date().toISOString(),
    attachments: [],
  };

  await db.collection('direct_commissions').doc(commissionId).update({
    messages: admin.firestore.FieldValue.arrayUnion(messageObj),
    updatedAt: new Date().toISOString(),
  });
}

/**
 * Create an earnings record
 */
async function createEarningsRecord(data: {
  userId: string;
  type: string;
  amount: number;
  commissionId: string;
  paymentIntentId: string;
  description: string;
}): Promise<void> {
  const earningsRef = db.collection('earnings').doc();
  
  await earningsRef.set({
    id: earningsRef.id,
    userId: data.userId,
    type: data.type,
    amount: data.amount,
    status: 'completed',
    source: 'commission',
    sourceId: data.commissionId,
    paymentIntentId: data.paymentIntentId,
    description: data.description,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  });

  // Update user's total earnings
  const userRef = db.collection('users').doc(data.userId);
  await userRef.update({
    totalEarnings: admin.firestore.FieldValue.increment(data.amount),
    availableBalance: admin.firestore.FieldValue.increment(data.amount),
  });
}

/**
 * Send commission notification
 */
async function sendCommissionNotification(
  userId: string,
  type: string,
  data: Record<string, any>
): Promise<void> {
  const notificationRef = db.collection('notifications').doc();
  
  await notificationRef.set({
    id: notificationRef.id,
    userId,
    type: `commission_${type}`,
    title: getNotificationTitle(type),
    message: getNotificationMessage(type, data),
    data,
    read: false,
    createdAt: new Date().toISOString(),
  });
}

function getNotificationTitle(type: string): string {
  switch (type) {
    case 'new_request':
      return 'New Commission Request';
    case 'quote_received':
      return 'Quote Received';
    case 'quote_accepted':
      return 'Quote Accepted';
    case 'deposit_received':
      return 'Deposit Received';
    case 'commission_completed':
      return 'Commission Completed';
    case 'final_payment_received':
      return 'Final Payment Received';
    case 'commission_delivered':
      return 'Commission Delivered';
    default:
      return 'Commission Update';
  }
}

function getNotificationMessage(type: string, data: Record<string, any>): string {
  switch (type) {
    case 'new_request':
      return `${data.clientName} has requested a commission: "${data.title}"`;
    case 'quote_received':
      return `${data.artistName} has sent you a quote for $${data.totalPrice}`;
    case 'quote_accepted':
      return `${data.clientName} has accepted your quote`;
    case 'deposit_received':
      return `Deposit of $${data.amount} received. You can now start work`;
    case 'commission_completed':
      return `${data.artistName} has completed your commission`;
    case 'final_payment_received':
      return `Final payment of $${data.amount} received`;
    case 'commission_delivered':
      return `Your commission from ${data.artistName} has been delivered`;
    default:
      return 'Commission update available';
  }
}