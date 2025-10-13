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
    event = stripe.webhooks.constructEvent(req.body, sig, webhookSecret);
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  console.log('Received webhook event:', event.type);

  try {
    switch (event.type) {
      case 'checkout.session.completed':
        await handleCheckoutCompleted(event.data.object);
        break;
      
      case 'customer.subscription.created':
        await handleSubscriptionCreated(event.data.object);
        break;
      
      case 'customer.subscription.updated':
        await handleSubscriptionUpdated(event.data.object);
        break;
      
      case 'customer.subscription.deleted':
        await handleSubscriptionDeleted(event.data.object);
        break;
      
      case 'invoice.payment_succeeded':
        await handlePaymentSucceeded(event.data.object);
        break;
      
      case 'invoice.payment_failed':
        await handlePaymentFailed(event.data.object);
        break;
      
      case 'payment_intent.succeeded':
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
  
  const userId = paymentIntent.metadata?.userId;
  const priceId = paymentIntent.metadata?.priceId;
  
  if (!userId) {
    console.error('No userId found in payment intent metadata');
    return;
  }
  
  try {
    // Update user subscription status in Firebase
    await admin.firestore().collection('users').doc(userId).update({
      subscriptionStatus: 'premium', // or determine based on priceId
      subscriptionExpiry: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days from now
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    console.log(`Updated user ${userId} subscription status to premium`);
  } catch (error) {
    console.error('Error updating user subscription:', error);
  }
}

async function handleCheckoutCompleted(session) {
  const userId = session.client_reference_id;
  const customerId = session.customer;

  if (!userId || !customerId) {
    console.error('Missing userId or customerId in checkout session');
    return;
  }

  console.log(`Checkout completed for user: ${userId}, customer: ${customerId}`);

  // Update user document with Stripe customer ID
  await admin.firestore().collection('users').doc(userId).update({
    stripeCustomerId: customerId,
    subscriptionStatus: 'premium',
    subscriptionExpiry: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

async function handleSubscriptionCreated(subscription) {
  const customerId = subscription.customer;
  console.log(`Subscription created for customer: ${customerId}`);
  
  // Find user by customer ID and update subscription status
  const usersSnapshot = await admin.firestore()
    .collection('users')
    .where('stripeCustomerId', '==', customerId)
    .limit(1)
    .get();

  if (!usersSnapshot.empty) {
    const userDoc = usersSnapshot.docs[0];
    await userDoc.ref.update({
      subscriptionStatus: 'premium',
      subscriptionExpiry: new Date(subscription.current_period_end * 1000),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
}

async function handleSubscriptionUpdated(subscription) {
  const customerId = subscription.customer;
  console.log(`Subscription updated for customer: ${customerId}`);
  
  // Find user by customer ID and update subscription status
  const usersSnapshot = await admin.firestore()
    .collection('users')
    .where('stripeCustomerId', '==', customerId)
    .limit(1)
    .get();

  if (!usersSnapshot.empty) {
    const userDoc = usersSnapshot.docs[0];
    await userDoc.ref.update({
      subscriptionStatus: subscription.status === 'active' ? 'premium' : 'free',
      subscriptionExpiry: subscription.current_period_end ? 
        new Date(subscription.current_period_end * 1000) : null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
}

async function handleSubscriptionDeleted(subscription) {
  const customerId = subscription.customer;
  console.log(`Subscription deleted for customer: ${customerId}`);
  
  // Find user by customer ID and update subscription status
  const usersSnapshot = await admin.firestore()
    .collection('users')
    .where('stripeCustomerId', '==', customerId)
    .limit(1)
    .get();

  if (!usersSnapshot.empty) {
    const userDoc = usersSnapshot.docs[0];
    await userDoc.ref.update({
      subscriptionStatus: 'free',
      subscriptionExpiry: null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
}

async function handlePaymentSucceeded(invoice) {
  const customerId = invoice.customer;
  console.log(`Payment succeeded for customer: ${customerId}`);
  
  // Find user by customer ID and extend subscription
  const usersSnapshot = await admin.firestore()
    .collection('users')
    .where('stripeCustomerId', '==', customerId)
    .limit(1)
    .get();

  if (!usersSnapshot.empty) {
    const userDoc = usersSnapshot.docs[0];
    await userDoc.ref.update({
      subscriptionStatus: 'premium',
      subscriptionExpiry: new Date(invoice.period_end * 1000),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
}

async function handlePaymentFailed(invoice) {
  const customerId = invoice.customer;
  console.log(`Payment failed for customer: ${customerId}`);
  
  // You might want to send a notification to the user here
  // For now, just log the event
}
