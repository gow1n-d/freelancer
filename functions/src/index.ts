import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import Razorpay from "razorpay";
import * as crypto from "crypto";

// Initialize Firebase Admin
admin.initializeApp();

// Initialize Razorpay
// Note: Set these environment variables using:
// firebase functions:config:set razorpay.key_id="YOUR_KEY_ID" razorpay.key_secret="YOUR_KEY_SECRET"
const getRazorpayInstance = () => {
  const keyId = functions.config().razorpay?.key_id;
  const keySecret = functions.config().razorpay?.key_secret;

  if (!keyId || !keySecret) {
    throw new Error("Razorpay credentials not configured. Run: firebase functions:config:set razorpay.key_id='YOUR_KEY' razorpay.key_secret='YOUR_SECRET'");
  }

  return new Razorpay({
    key_id: keyId,
    key_secret: keySecret,
  });
};

/**
 * Create Razorpay order for subscription payment
 */
export const createRazorpayOrder = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated to create an order"
    );
  }

  const {userId, planType, amount} = data;

  // Validate input
  if (!userId || !planType || !amount) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Missing required fields: userId, planType, amount"
    );
  }

  // Verify user is requesting order for themselves
  if (context.auth.uid !== userId) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "User can only create orders for themselves"
    );
  }

  // Validate plan type
  if (planType !== "monthly" && planType !== "yearly") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Invalid plan type. Must be 'monthly' or 'yearly'"
    );
  }

  // Validate amount (must be positive)
  if (typeof amount !== "number" || amount <= 0) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Amount must be a positive number"
    );
  }

  try {
    const razorpay = getRazorpayInstance();

    // Create Razorpay order
    const order = await razorpay.orders.create({
      amount: amount, // Amount in paise
      currency: "INR",
      receipt: `sub_${userId}_${Date.now()}`,
      notes: {
        userId: userId,
        planType: planType,
        type: "subscription",
      },
    });

    functions.logger.info("Razorpay order created", {
      orderId: order.id,
      userId: userId,
      planType: planType,
      amount: amount,
    });

    return {
      success: true,
      orderId: order.id,
      amount: order.amount,
      currency: order.currency,
    };
  } catch (error: unknown) {
    functions.logger.error("Failed to create Razorpay order", {
      error: error,
      userId: userId,
      planType: planType,
    });

    throw new functions.https.HttpsError(
      "internal",
      "Failed to create payment order",
      error
    );
  }
});

/**
 * Verify Razorpay payment signature and update subscription
 */
export const verifyPayment = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated to verify payment"
    );
  }

  const {orderId, paymentId, signature, userId, planType} = data;

  // Validate input
  if (!orderId || !paymentId || !signature || !userId || !planType) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Missing required fields"
    );
  }

  // Verify user is verifying their own payment
  if (context.auth.uid !== userId) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "User can only verify their own payments"
    );
  }

  try {
    const keySecret = functions.config().razorpay?.key_secret;

    if (!keySecret) {
      throw new Error("Razorpay key secret not configured");
    }

    // Verify signature
    const expectedSignature = crypto
      .createHmac("sha256", keySecret)
      .update(`${orderId}|${paymentId}`)
      .digest("hex");

    if (expectedSignature !== signature) {
      functions.logger.error("Payment signature verification failed", {
        orderId: orderId,
        paymentId: paymentId,
        userId: userId,
      });

      throw new functions.https.HttpsError(
        "permission-denied",
        "Payment signature verification failed"
      );
    }

    // Signature verified, update Firestore
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();

    // Calculate subscription end date
    const startDate = admin.firestore.Timestamp.now();
    let endDate: admin.firestore.Timestamp;

    if (planType === "monthly") {
      const date = new Date();
      date.setMonth(date.getMonth() + 1);
      endDate = admin.firestore.Timestamp.fromDate(date);
    } else {
      // yearly
      const date = new Date();
      date.setFullYear(date.getFullYear() + 1);
      endDate = admin.firestore.Timestamp.fromDate(date);
    }

    // Update subscription document
    await db.collection("subscriptions").doc(userId).set({
      userId: userId,
      status: "active",
      plan: planType,
      startDate: startDate,
      endDate: endDate,
      autoRenewal: true,
      createdAt: now,
      updatedAt: now,
    });

    // Update user document
    await db.collection("users").doc(userId).update({
      subscriptionStatus: "active",
      subscriptionPlan: planType,
      subscriptionStartDate: startDate,
      subscriptionEndDate: endDate,
      autoRenewal: true,
      updatedAt: now,
    });

    functions.logger.info("Payment verified and subscription activated", {
      orderId: orderId,
      paymentId: paymentId,
      userId: userId,
      planType: planType,
    });

    return {
      success: true,
      message: "Payment verified successfully",
    };
  } catch (error: unknown) {
    functions.logger.error("Payment verification failed", {
      error: error,
      orderId: orderId,
      paymentId: paymentId,
      userId: userId,
    });

    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError(
      "internal",
      "Failed to verify payment",
      error
    );
  }
});

/**
 * Background function to check and expire subscriptions
 * Runs daily at midnight IST (18:30 UTC)
 */
export const checkExpiredSubscriptions = functions.pubsub
  .schedule("30 18 * * *")
  .timeZone("Asia/Kolkata")
  .onRun(async (context) => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();

    try {
      // Find active subscriptions that have expired
      const expiredSubscriptions = await db
        .collection("subscriptions")
        .where("status", "in", ["active", "trial"])
        .where("endDate", "<=", now)
        .get();

      if (expiredSubscriptions.empty) {
        functions.logger.info("No expired subscriptions found");
        return null;
      }

      const batch = db.batch();

      expiredSubscriptions.forEach((doc) => {
        const subscriptionRef = db.collection("subscriptions").doc(doc.id);
        const userRef = db.collection("users").doc(doc.id);

        batch.update(subscriptionRef, {
          status: "expired",
          updatedAt: now,
        });

        batch.update(userRef, {
          subscriptionStatus: "expired",
          updatedAt: now,
        });
      });

      await batch.commit();

      functions.logger.info("Expired subscriptions updated", {
        count: expiredSubscriptions.size,
      });

      return null;
    } catch (error) {
      functions.logger.error("Failed to check expired subscriptions", error);
      throw error;
    }
  });
