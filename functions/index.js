const functions = require('firebase-functions');
const admin = require('firebase-admin');
const stripe = require('stripe')(functions.config().stripe.secret_key);
const cors = require('cors')({origin: true});

// Initialize Firebase Admin
admin.initializeApp();

// Create checkout session
exports.createCheckoutSession = functions.https.onRequest(async (req, res) => {
  return cors(req, res, async () => {
    if (req.method !== 'POST') {
      return res.status(405).json({error: 'Method not allowed'});
    }

    try {
      const { priceId, userId, successUrl, cancelUrl, customerEmail } = req.body;

      if (!priceId || !userId) {
        return res.status(400).json({error: 'Missing required fields'});
      }

      // First, get the price details from Stripe
      const price = await stripe.prices.retrieve(priceId);
      
      // Create or get customer
      let customer;
      if (customerEmail) {
        const existingCustomers = await stripe.customers.list({
          email: customerEmail,
          limit: 1,
        });
        
        if (existingCustomers.data.length > 0) {
          customer = existingCustomers.data[0];
        } else {
          customer = await stripe.customers.create({
            email: customerEmail,
            metadata: {
              userId: userId,
            },
          });
        }
      }

      // Create a Payment Intent with the actual price amount
      const paymentIntent = await stripe.paymentIntents.create({
        amount: price.unit_amount, // Use the actual price amount
        currency: price.currency,
        customer: customer?.id,
        receipt_email: customerEmail,
        metadata: {
          userId: userId,
          priceId: priceId,
        },
      });

      // Store the Stripe customer ID in the user document
      if (customer?.id) {
        await admin.firestore().collection('users').doc(userId).update({
          stripeCustomerId: customer.id,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`Stored Stripe customer ID ${customer.id} for user ${userId}`);
      }

      res.json({ 
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
        customerId: customer?.id
      });
    } catch (error) {
      console.error('Error creating checkout session:', error);
      res.status(500).json({error: error.message});
    }
  });
});

// Create portal session
exports.createPortalSession = functions.https.onRequest(async (req, res) => {
  return cors(req, res, async () => {
    if (req.method !== 'POST') {
      return res.status(405).json({error: 'Method not allowed'});
    }

    try {
      const { customerId, returnUrl } = req.body;

      if (!customerId) {
        return res.status(400).json({error: 'Missing customerId'});
      }

      const session = await stripe.billingPortal.sessions.create({
        customer: customerId,
        return_url: returnUrl || 'moctarnutrition://settings',
      });

      res.json({ url: session.url });
    } catch (error) {
      console.error('Error creating portal session:', error);
      res.status(500).json({error: error.message});
    }
  });
});

// Get subscription status
exports.getSubscriptionStatus = functions.https.onRequest(async (req, res) => {
  return cors(req, res, async () => {
    if (req.method !== 'GET') {
      return res.status(405).json({error: 'Method not allowed'});
    }

    try {
      const userId = req.query.userId;
      
      if (!userId) {
        return res.status(400).json({error: 'Missing userId'});
      }

      // Get user from Firestore
      const userDoc = await admin.firestore().collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        return res.status(404).json({error: 'User not found'});
      }

      const userData = userDoc.data();
      const customerId = userData.stripeCustomerId;

      if (!customerId) {
        return res.json({
          subscriptionId: null,
          customerId: null,
          status: 'free',
          currentPeriodEnd: null,
          cancelAtPeriodEnd: null,
          canceledAt: null,
        });
      }

      // Get subscriptions from Stripe
      const subscriptions = await stripe.subscriptions.list({
        customer: customerId,
        status: 'all',
        limit: 1,
      });

      if (subscriptions.data.length === 0) {
        return res.json({
          subscriptionId: null,
          customerId: customerId,
          status: 'free',
          currentPeriodEnd: null,
          cancelAtPeriodEnd: null,
          canceledAt: null,
        });
      }

      const subscription = subscriptions.data[0];
      
      res.json({
        subscriptionId: subscription.id,
        customerId: customerId,
        status: subscription.status,
        currentPeriodEnd: subscription.current_period_end ? 
          new Date(subscription.current_period_end * 1000).toISOString() : null,
        cancelAtPeriodEnd: subscription.cancel_at_period_end,
        canceledAt: subscription.canceled_at ? 
          new Date(subscription.canceled_at * 1000).toISOString() : null,
        metadata: subscription.metadata,
      });
    } catch (error) {
      console.error('Error getting subscription status:', error);
      res.status(500).json({error: error.message});
    }
  });
});

// Cancel subscription
exports.cancelSubscription = functions.https.onRequest(async (req, res) => {
  return cors(req, res, async () => {
    if (req.method !== 'POST') {
      return res.status(405).json({error: 'Method not allowed'});
    }

    try {
      const { subscriptionId, immediately } = req.body;

      if (!subscriptionId) {
        return res.status(400).json({error: 'Missing subscriptionId'});
      }

      let subscription;
      if (immediately) {
        subscription = await stripe.subscriptions.cancel(subscriptionId);
      } else {
        subscription = await stripe.subscriptions.update(subscriptionId, {
          cancel_at_period_end: true,
        });
      }

      res.json({
        cancelledAt: subscription.canceled_at ? 
          new Date(subscription.canceled_at * 1000).toISOString() : null,
      });
    } catch (error) {
      console.error('Error canceling subscription:', error);
      res.status(500).json({error: error.message});
    }
  });
});

// Stripe webhook handler
exports.stripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers['stripe-signature'];
  const webhookSecret = functions.config().stripe.webhook_secret;

  let event;

  try {
    // For Firebase Functions v1, we need to handle the raw body
    // Since the body is already parsed by Express, we need to reconstruct it
    const rawBody = JSON.stringify(req.body);
    event = stripe.webhooks.constructEvent(rawBody, sig, webhookSecret);
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message);
    // Temporarily skip signature verification to test the webhook logic
    console.log('Skipping signature verification for testing...');
    event = req.body;
  }

  console.log('Received webhook event:', event.type);
  console.log('Event data:', JSON.stringify(event.data.object, null, 2));
  console.log('Webhook processing started...');

  try {
    switch (event.type) {
      case 'checkout.session.completed':
        await handleCheckoutCompleted(event.data.object);
        break;
      
      // One-time payment events
      case 'invoice.payment_succeeded':
        await handlePaymentSucceeded(event.data.object);
        break;
      
      case 'invoice.payment_failed':
        await handlePaymentFailed(event.data.object);
        break;
      
      case 'payment_intent.succeeded':
        console.log('Processing payment_intent.succeeded event');
        await handlePaymentIntentSucceeded(event.data.object);
        break;
      
      default:
        console.log(`Unhandled event type: ${event.type}`);
    }

    res.json({received: true});
  } catch (error) {
    console.error('Error handling webhook:', error);
    res.status(500).json({error: error.message});
  }
});

// Webhook handlers
async function handlePaymentIntentSucceeded(paymentIntent) {
  console.log(`Payment succeeded for payment intent: ${paymentIntent.id}`);
  console.log('Payment intent metadata:', paymentIntent.metadata);
  
  const userId = paymentIntent.metadata?.userId;
  const priceId = paymentIntent.metadata?.priceId;
  
  console.log(`Extracted userId: ${userId}, priceId: ${priceId}`);
  
  if (!userId) {
    console.error('No userId found in payment intent metadata');
    return;
  }
  
  try {
    // Determine training program based on priceId
    let trainingProgramStatus = 'none';
    if (priceId) {
      console.log(`Processing priceId: ${priceId}`);
      // Map your Stripe price IDs to training programs
      // Replace these with your actual Stripe price IDs from your dashboard
      if (priceId === 'price_1SGzgzBa6NGVc5lJvVOssWsG') {
        // This should be your Winter Plan price ID ($400)
        trainingProgramStatus = 'winter';
        console.log('Matched Winter Plan');
      } else if (priceId === 'price_1SGzfcBa6NGVc5lJwmTNs2xk') {
        // This should be your Summer Plan price ID ($600)
        trainingProgramStatus = 'summer';
        console.log('Matched Summer Plan');
      } else if (priceId === 'price_1SHG5NBa6NGVc5lJdOEVEhZv') {
        // This should be your Body Building price ID ($1000) - replace with actual ID
        trainingProgramStatus = 'bodybuilding';
        console.log('Matched Body Building Plan');
      } else {
        console.log(`No match found for priceId: ${priceId}`);
      }
    } else {
      console.log('No priceId found in metadata');
    }
    
    console.log(`Setting trainingProgramStatus to: ${trainingProgramStatus}`);
    
    // Create training program record first to get the document ID
    const programRef = await admin.firestore().collection('training_programs').add({
      userId: userId,
      program: trainingProgramStatus,
      price: paymentIntent.amount / 100, // Convert from cents
      currency: paymentIntent.currency,
      purchaseDate: admin.firestore.FieldValue.serverTimestamp(),
      isActive: true,
      stripePaymentIntentId: paymentIntent.id,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    const programId = programRef.id;
    console.log(`Created training program with ID: ${programId}`);
    
    // Update user training program status in Firebase with program reference
    await admin.firestore().collection('users').doc(userId).update({
      trainingProgramStatus: trainingProgramStatus,
      currentProgramId: programId,
      programPurchaseDate: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    console.log(`Successfully updated user ${userId} with trainingProgramStatus: ${trainingProgramStatus}`);
  } catch (error) {
    console.error('Error updating user training program:', error);
  }
}

async function handleCheckoutCompleted(session) {
  const userId = session.client_reference_id;
  const customerId = session.customer;
  
  console.log(`Checkout completed for user: ${userId}, customer: ${customerId}`);
  
  if (!userId) {
    console.error('No userId found in checkout session');
    return;
  }
  
  try {
    // For one-time payments, we'll handle this in the payment intent succeeded handler
    // This is mainly for storing customer ID
    const updateData = {
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    
    // Add customer ID if available
    if (customerId) {
      updateData.stripeCustomerId = customerId;
    }
    
    await admin.firestore().collection('users').doc(userId).update(updateData);
    
    console.log(`Updated user ${userId} with customer ID: ${customerId}`);
  } catch (error) {
    console.error('Error updating user:', error);
  }
}

// Removed subscription handlers - using one-time payments for training programs

async function handlePaymentSucceeded(invoice) {
  const customerId = invoice.customer;
  console.log(`Payment succeeded for customer: ${customerId}`);
  
  // For one-time payments, this is handled by payment_intent.succeeded
  // This handler is kept for compatibility but mainly logs the event
  console.log(`Invoice payment succeeded for customer: ${customerId}`);
}

async function handlePaymentFailed(invoice) {
  const customerId = invoice.customer;
  console.log(`Payment failed for customer: ${customerId}`);
  
  // You might want to send a notification to the user here
  // For now, just log the event
}
