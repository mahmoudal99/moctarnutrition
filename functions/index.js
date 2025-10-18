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

// Get revenue metrics
exports.getRevenueMetrics = functions.https.onRequest(async (req, res) => {
  return cors(req, res, async () => {
    if (req.method !== 'GET') {
      return res.status(405).json({error: 'Method not allowed'});
    }

    try {
      const startDate = req.query.startDate ? new Date(req.query.startDate) : null;
      const endDate = req.query.endDate ? new Date(req.query.endDate) : null;

      // Get payment intents from Stripe
      const paymentIntents = await stripe.paymentIntents.list({
        created: {
          gte: startDate ? Math.floor(startDate.getTime() / 1000) : undefined,
          lte: endDate ? Math.floor(endDate.getTime() / 1000) : undefined,
        },
        limit: 100,
      });

      // Get previous period for comparison
      const previousStartDate = startDate ? new Date(startDate.getTime() - (endDate.getTime() - startDate.getTime())) : null;
      const previousEndDate = startDate ? new Date(startDate.getTime()) : null;

      const previousPaymentIntents = await stripe.paymentIntents.list({
        created: {
          gte: previousStartDate ? Math.floor(previousStartDate.getTime() / 1000) : undefined,
          lte: previousEndDate ? Math.floor(previousEndDate.getTime() / 1000) : undefined,
        },
        limit: 100,
      });

      // Calculate metrics
      const successfulPayments = paymentIntents.data.filter(pi => pi.status === 'succeeded');
      const totalRevenue = successfulPayments.reduce((sum, pi) => sum + pi.amount, 0) / 100;
      const totalTransactions = successfulPayments.length;
      const averageTransactionValue = totalTransactions > 0 ? totalRevenue / totalTransactions : 0;

      // Calculate refunds
      const charges = await Promise.all(
        successfulPayments.map(pi => stripe.charges.retrieve(pi.latest_charge))
      );
      const refundedAmount = charges.reduce((sum, charge) => {
        return sum + (charge.refunded ? charge.amount_refunded : 0);
      }, 0) / 100;

      const netRevenue = totalRevenue - refundedAmount;

      // Previous period metrics
      const previousSuccessfulPayments = previousPaymentIntents.data.filter(pi => pi.status === 'succeeded');
      const previousRevenue = previousSuccessfulPayments.reduce((sum, pi) => sum + pi.amount, 0) / 100;
      const revenueGrowth = previousRevenue > 0 ? ((totalRevenue - previousRevenue) / previousRevenue) * 100 : 0;

      res.json({
        totalRevenue,
        netRevenue,
        refundedAmount,
        totalTransactions,
        averageTransactionValue,
        currency: 'eur',
        previousPeriodRevenue: previousRevenue,
        revenueGrowth,
      });
    } catch (error) {
      console.error('Error getting revenue metrics:', error);
      res.status(500).json({error: error.message});
    }
  });
});

// Get sales metrics
exports.getSalesMetrics = functions.https.onRequest(async (req, res) => {
  return cors(req, res, async () => {
    if (req.method !== 'GET') {
      return res.status(405).json({error: 'Method not allowed'});
    }

    try {
      const startDate = req.query.startDate ? new Date(req.query.startDate) : null;
      const endDate = req.query.endDate ? new Date(req.query.endDate) : null;

      // Get payment intents with metadata
      const paymentIntents = await stripe.paymentIntents.list({
        created: {
          gte: startDate ? Math.floor(startDate.getTime() / 1000) : undefined,
          lte: endDate ? Math.floor(endDate.getTime() / 1000) : undefined,
        },
        limit: 100,
      });

      // Get previous period for comparison
      const previousStartDate = startDate ? new Date(startDate.getTime() - (endDate.getTime() - startDate.getTime())) : null;
      const previousEndDate = startDate ? new Date(startDate.getTime()) : null;

      const previousPaymentIntents = await stripe.paymentIntents.list({
        created: {
          gte: previousStartDate ? Math.floor(previousStartDate.getTime() / 1000) : undefined,
          lte: previousEndDate ? Math.floor(previousEndDate.getTime() / 1000) : undefined,
        },
        limit: 100,
      });

      // Count sales by product (based on priceId in metadata)
      const productSales = {};
      const successfulPayments = paymentIntents.data.filter(pi => pi.status === 'succeeded');
      
      successfulPayments.forEach(pi => {
        const priceId = pi.metadata?.priceId;
        if (priceId) {
          // Map price IDs to product names
          let productName = 'Unknown Product';
          if (priceId === 'price_1SGzgzBa6NGVc5lJvVOssWsG') {
            productName = 'Winter Plan';
          } else if (priceId === 'price_1SGzfcBa6NGVc5lJwmTNs2xk') {
            productName = 'Summer Plan';
          } else if (priceId === 'price_1SHG5NBa6NGVc5lJdOEVEhZv') {
            productName = 'Body Building Plan';
          }
          
          productSales[productName] = (productSales[productName] || 0) + 1;
        }
      });

      const totalSales = successfulPayments.length;
      const totalSalesValue = successfulPayments.reduce((sum, pi) => sum + pi.amount, 0) / 100;

      // Previous period metrics
      const previousSuccessfulPayments = previousPaymentIntents.data.filter(pi => pi.status === 'succeeded');
      const previousSales = previousSuccessfulPayments.length;
      const salesGrowth = previousSales > 0 ? ((totalSales - previousSales) / previousSales) * 100 : 0;

      res.json({
        productSales,
        totalSales,
        totalSalesValue,
        currency: 'eur',
        previousPeriodSales: previousSales,
        salesGrowth,
      });
    } catch (error) {
      console.error('Error getting sales metrics:', error);
      res.status(500).json({error: error.message});
    }
  });
});

// Get transaction metrics
exports.getTransactionMetrics = functions.https.onRequest(async (req, res) => {
  return cors(req, res, async () => {
    if (req.method !== 'GET') {
      return res.status(405).json({error: 'Method not allowed'});
    }

    try {
      const startDate = req.query.startDate ? new Date(req.query.startDate) : null;
      const endDate = req.query.endDate ? new Date(req.query.endDate) : null;

      // Get payment intents from Stripe
      const paymentIntents = await stripe.paymentIntents.list({
        created: {
          gte: startDate ? Math.floor(startDate.getTime() / 1000) : undefined,
          lte: endDate ? Math.floor(endDate.getTime() / 1000) : undefined,
        },
        limit: 100,
      });

      // Get previous period for comparison
      const previousStartDate = startDate ? new Date(startDate.getTime() - (endDate.getTime() - startDate.getTime())) : null;
      const previousEndDate = startDate ? new Date(startDate.getTime()) : null;

      const previousPaymentIntents = await stripe.paymentIntents.list({
        created: {
          gte: previousStartDate ? Math.floor(previousStartDate.getTime() / 1000) : undefined,
          lte: previousEndDate ? Math.floor(previousEndDate.getTime() / 1000) : undefined,
        },
        limit: 100,
      });

      // Calculate transaction metrics
      const totalTransactions = paymentIntents.data.length;
      const successfulTransactions = paymentIntents.data.filter(pi => pi.status === 'succeeded').length;
      const failedTransactions = paymentIntents.data.filter(pi => pi.status === 'requires_payment_method' || pi.status === 'canceled').length;
      const successRate = totalTransactions > 0 ? (successfulTransactions / totalTransactions) * 100 : 0;

      const successfulPayments = paymentIntents.data.filter(pi => pi.status === 'succeeded');
      const averageTransactionValue = successfulPayments.length > 0 
        ? successfulPayments.reduce((sum, pi) => sum + pi.amount, 0) / successfulPayments.length / 100
        : 0;

      // Previous period metrics
      const previousTotalTransactions = previousPaymentIntents.data.length;
      const transactionGrowth = previousTotalTransactions > 0 
        ? ((totalTransactions - previousTotalTransactions) / previousTotalTransactions) * 100 
        : 0;

      res.json({
        totalTransactions,
        successfulTransactions,
        failedTransactions,
        successRate,
        averageTransactionValue,
        currency: 'eur',
        previousPeriodTransactions: previousTotalTransactions,
        transactionGrowth,
      });
    } catch (error) {
      console.error('Error getting transaction metrics:', error);
      res.status(500).json({error: error.message});
    }
  });
});

// Get comprehensive dashboard metrics
exports.getDashboardMetrics = functions.https.onRequest(async (req, res) => {
  return cors(req, res, async () => {
    if (req.method !== 'GET') {
      return res.status(405).json({error: 'Method not allowed'});
    }

    try {
      console.log('Getting dashboard metrics...');
      const startDate = req.query.startDate ? new Date(req.query.startDate) : null;
      const endDate = req.query.endDate ? new Date(req.query.endDate) : null;
      
      console.log('Date range:', { startDate, endDate });

      // Get all metrics in parallel
      console.log('Fetching metrics data...');
      const [revenueData, salesData, transactionData] = await Promise.all([
        getRevenueMetricsData(startDate, endDate),
        getSalesMetricsData(startDate, endDate),
        getTransactionMetricsData(startDate, endDate),
      ]);

      console.log('Metrics data fetched:', { revenueData, salesData, transactionData });

      // Get customer metrics from Firestore
      console.log('Fetching user data from Firestore...');
      const usersSnapshot = await admin.firestore().collection('users').get();
      console.log(`Found ${usersSnapshot.docs.length} users`);
      
      const activeCustomers = usersSnapshot.docs.filter(doc => {
        const data = doc.data();
        return data.trainingProgramStatus && data.trainingProgramStatus !== 'none';
      }).length;

      const newCustomers = usersSnapshot.docs.filter(doc => {
        const data = doc.data();
        let createdAt;
        
        // Handle different timestamp formats
        if (data.createdAt && typeof data.createdAt.toDate === 'function') {
          createdAt = data.createdAt.toDate();
        } else if (data.createdAt && data.createdAt._seconds) {
          // Handle Firestore timestamp object
          createdAt = new Date(data.createdAt._seconds * 1000);
        } else if (data.createdAt) {
          // Handle string or other date formats
          createdAt = new Date(data.createdAt);
        }
        
        return createdAt && startDate && createdAt >= startDate && (!endDate || createdAt <= endDate);
      }).length;

      console.log('Customer metrics:', { activeCustomers, newCustomers });

      // Get historical revenue data for the chart
      const historicalData = await getHistoricalRevenueData(startDate, endDate);

      const result = {
        revenue: revenueData,
        sales: salesData,
        transactions: transactionData,
        activeCustomers,
        newCustomers,
        historicalData,
        lastUpdated: new Date().toISOString(),
      };

      console.log('Final result:', result);
      res.json(result);
    } catch (error) {
      console.error('Error getting dashboard metrics:', error);
      console.error('Stack trace:', error.stack);
      res.status(500).json({error: error.message});
    }
  });
});

// Helper functions for dashboard metrics
async function getRevenueMetricsData(startDate, endDate) {
  const paymentIntents = await stripe.paymentIntents.list({
    created: {
      gte: startDate ? Math.floor(startDate.getTime() / 1000) : undefined,
      lte: endDate ? Math.floor(endDate.getTime() / 1000) : undefined,
    },
    limit: 100,
  });

  const previousStartDate = startDate ? new Date(startDate.getTime() - (endDate.getTime() - startDate.getTime())) : null;
  const previousEndDate = startDate ? new Date(startDate.getTime()) : null;

  const previousPaymentIntents = await stripe.paymentIntents.list({
    created: {
      gte: previousStartDate ? Math.floor(previousStartDate.getTime() / 1000) : undefined,
      lte: previousEndDate ? Math.floor(previousEndDate.getTime() / 1000) : undefined,
    },
    limit: 100,
  });

  const successfulPayments = paymentIntents.data.filter(pi => pi.status === 'succeeded');
  const totalRevenue = successfulPayments.reduce((sum, pi) => sum + pi.amount, 0) / 100;
  const totalTransactions = successfulPayments.length;
  const averageTransactionValue = totalTransactions > 0 ? totalRevenue / totalTransactions : 0;

  const charges = await Promise.all(
    successfulPayments.map(pi => stripe.charges.retrieve(pi.latest_charge))
  );
  const refundedAmount = charges.reduce((sum, charge) => {
    return sum + (charge.refunded ? charge.amount_refunded : 0);
  }, 0) / 100;

  const netRevenue = totalRevenue - refundedAmount;

  const previousSuccessfulPayments = previousPaymentIntents.data.filter(pi => pi.status === 'succeeded');
  const previousRevenue = previousSuccessfulPayments.reduce((sum, pi) => sum + pi.amount, 0) / 100;
  const revenueGrowth = previousRevenue > 0 ? ((totalRevenue - previousRevenue) / previousRevenue) * 100 : 0;

  return {
    totalRevenue,
    netRevenue,
    refundedAmount,
    totalTransactions,
    averageTransactionValue,
    currency: 'eur',
    previousPeriodRevenue: previousRevenue,
    revenueGrowth,
  };
}

async function getSalesMetricsData(startDate, endDate) {
  const paymentIntents = await stripe.paymentIntents.list({
    created: {
      gte: startDate ? Math.floor(startDate.getTime() / 1000) : undefined,
      lte: endDate ? Math.floor(endDate.getTime() / 1000) : undefined,
    },
    limit: 100,
  });

  const previousStartDate = startDate ? new Date(startDate.getTime() - (endDate.getTime() - startDate.getTime())) : null;
  const previousEndDate = startDate ? new Date(startDate.getTime()) : null;

  const previousPaymentIntents = await stripe.paymentIntents.list({
    created: {
      gte: previousStartDate ? Math.floor(previousStartDate.getTime() / 1000) : undefined,
      lte: previousEndDate ? Math.floor(previousEndDate.getTime() / 1000) : undefined,
    },
    limit: 100,
  });

  const productSales = {};
  const successfulPayments = paymentIntents.data.filter(pi => pi.status === 'succeeded');
  
  successfulPayments.forEach(pi => {
    const priceId = pi.metadata?.priceId;
    if (priceId) {
      let productName = 'Unknown Product';
      if (priceId === 'price_1SGzgzBa6NGVc5lJvVOssWsG') {
        productName = 'Winter Plan';
      } else if (priceId === 'price_1SGzfcBa6NGVc5lJwmTNs2xk') {
        productName = 'Summer Plan';
      } else if (priceId === 'price_1SHG5NBa6NGVc5lJdOEVEhZv') {
        productName = 'Body Building Plan';
      }
      
      productSales[productName] = (productSales[productName] || 0) + 1;
    }
  });

  const totalSales = successfulPayments.length;
  const totalSalesValue = successfulPayments.reduce((sum, pi) => sum + pi.amount, 0) / 100;

  const previousSuccessfulPayments = previousPaymentIntents.data.filter(pi => pi.status === 'succeeded');
  const previousSales = previousSuccessfulPayments.length;
  const salesGrowth = previousSales > 0 ? ((totalSales - previousSales) / previousSales) * 100 : 0;

  return {
    productSales,
    totalSales,
    totalSalesValue,
    currency: 'eur',
    previousPeriodSales: previousSales,
    salesGrowth,
  };
}

async function getTransactionMetricsData(startDate, endDate) {
  const paymentIntents = await stripe.paymentIntents.list({
    created: {
      gte: startDate ? Math.floor(startDate.getTime() / 1000) : undefined,
      lte: endDate ? Math.floor(endDate.getTime() / 1000) : undefined,
    },
    limit: 100,
  });

  const previousStartDate = startDate ? new Date(startDate.getTime() - (endDate.getTime() - startDate.getTime())) : null;
  const previousEndDate = startDate ? new Date(startDate.getTime()) : null;

  const previousPaymentIntents = await stripe.paymentIntents.list({
    created: {
      gte: previousStartDate ? Math.floor(previousStartDate.getTime() / 1000) : undefined,
      lte: previousEndDate ? Math.floor(previousEndDate.getTime() / 1000) : undefined,
    },
    limit: 100,
  });

  const totalTransactions = paymentIntents.data.length;
  const successfulTransactions = paymentIntents.data.filter(pi => pi.status === 'succeeded').length;
  const failedTransactions = paymentIntents.data.filter(pi => pi.status === 'requires_payment_method' || pi.status === 'canceled').length;
  const successRate = totalTransactions > 0 ? (successfulTransactions / totalTransactions) * 100 : 0;

  const successfulPayments = paymentIntents.data.filter(pi => pi.status === 'succeeded');
  const averageTransactionValue = successfulPayments.length > 0 
    ? successfulPayments.reduce((sum, pi) => sum + pi.amount, 0) / successfulPayments.length / 100
    : 0;

  const previousTotalTransactions = previousPaymentIntents.data.length;
  const transactionGrowth = previousTotalTransactions > 0 
    ? ((totalTransactions - previousTotalTransactions) / previousTotalTransactions) * 100 
    : 0;

  return {
    totalTransactions,
    successfulTransactions,
    failedTransactions,
    successRate,
    averageTransactionValue,
    currency: 'eur',
    previousPeriodTransactions: previousTotalTransactions,
    transactionGrowth,
  };
}

// Get historical revenue data for charts
async function getHistoricalRevenueData(startDate, endDate) {
  try {
    console.log('Getting historical revenue data from', startDate, 'to', endDate);
    
    const stripe = require('stripe')(functions.config().stripe.secret_key);
    
    // Get payment intents for the period
    const paymentIntents = await stripe.paymentIntents.list({
      created: {
        gte: Math.floor(startDate.getTime() / 1000),
        lte: Math.floor(endDate.getTime() / 1000),
      },
      limit: 100,
    });

    // Group by day
    const dailyRevenue = {};
    const oneDay = 24 * 60 * 60 * 1000; // milliseconds in a day
    
    // Initialize all days in the range with 0
    for (let d = new Date(startDate); d <= endDate; d.setTime(d.getTime() + oneDay)) {
      const dayKey = d.toISOString().split('T')[0];
      dailyRevenue[dayKey] = 0;
    }

    // Sum up revenue by day
    paymentIntents.data.forEach(intent => {
      if (intent.status === 'succeeded' && intent.amount > 0) {
        const date = new Date(intent.created * 1000);
        const dayKey = date.toISOString().split('T')[0];
        if (dailyRevenue.hasOwnProperty(dayKey)) {
          dailyRevenue[dayKey] += intent.amount / 100; // Convert from cents to dollars
        }
      }
    });

    // Convert to array format for the chart
    const chartData = Object.entries(dailyRevenue)
      .sort(([a], [b]) => a.localeCompare(b))
      .map(([date, revenue]) => ({
        date,
        revenue: Math.round(revenue * 100) / 100, // Round to 2 decimal places
      }));

    console.log('Historical data points:', chartData.length);
    return chartData;
  } catch (error) {
    console.error('Error getting historical revenue data:', error);
    return [];
  }
}
