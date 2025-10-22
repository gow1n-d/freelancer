# Cloud Functions for Freelancer App

This directory contains Firebase Cloud Functions for handling backend operations like payment verification and subscription management.

## Setup

### 1. Install Dependencies

```bash
cd functions
npm install
```

### 2. Configure Razorpay Credentials

You need to set your Razorpay API credentials as environment variables:

```bash
firebase functions:config:set razorpay.key_id="YOUR_RAZORPAY_KEY_ID"
firebase functions:config:set razorpay.key_secret="YOUR_RAZORPAY_KEY_SECRET"
```

To get your Razorpay credentials:
1. Sign up at [Razorpay Dashboard](https://dashboard.razorpay.com/)
2. Go to Settings → API Keys
3. Generate Test/Live Keys
4. Copy Key ID and Key Secret

### 3. View Current Configuration

```bash
firebase functions:config:get
```

## Available Functions

### 1. createRazorpayOrder

Creates a Razorpay order for subscription payment.

**Trigger**: HTTPS Callable
**Authentication**: Required
**Parameters**:
- `userId` (string): User's Firebase UID
- `planType` (string): 'monthly' or 'yearly'
- `amount` (number): Amount in paise (₹299 = 29900 paise)

**Returns**:
```json
{
  "success": true,
  "orderId": "order_xyz123",
  "amount": 29900,
  "currency": "INR"
}
```

### 2. verifyPayment

Verifies Razorpay payment signature and activates subscription.

**Trigger**: HTTPS Callable
**Authentication**: Required
**Parameters**:
- `orderId` (string): Razorpay order ID
- `paymentId` (string): Razorpay payment ID
- `signature` (string): Razorpay signature
- `userId` (string): User's Firebase UID
- `planType` (string): 'monthly' or 'yearly'

**Returns**:
```json
{
  "success": true,
  "message": "Payment verified successfully"
}
```

### 3. checkExpiredSubscriptions

Background function that runs daily to check and expire subscriptions.

**Trigger**: Scheduled (Daily at 12:00 AM IST)
**Authentication**: Not required (background function)

## Development

### Build TypeScript

```bash
npm run build
```

### Watch Mode (Auto-rebuild)

```bash
npm run build:watch
```

### Run Functions Locally

```bash
# Start Firebase emulator
npm run serve

# Or use Firebase CLI directly
firebase emulators:start --only functions
```

### Lint Code

```bash
npm run lint
```

## Deployment

### Deploy All Functions

```bash
npm run deploy
```

### Deploy Specific Function

```bash
firebase deploy --only functions:createRazorpayOrder
firebase deploy --only functions:verifyPayment
firebase deploy --only functions:checkExpiredSubscriptions
```

## View Logs

```bash
# View all logs
npm run logs

# View specific function logs
firebase functions:log --only createRazorpayOrder

# View logs in real-time
firebase functions:log --follow
```

## Testing

### Test with Firebase Emulator

1. Start the emulator:
```bash
npm run serve
```

2. The functions will be available at:
```
http://localhost:5001/YOUR_PROJECT_ID/us-central1/createRazorpayOrder
http://localhost:5001/YOUR_PROJECT_ID/us-central1/verifyPayment
```

### Test with Razorpay Test Mode

1. Use Razorpay Test API Keys during development
2. Use test card details from [Razorpay Test Cards](https://razorpay.com/docs/payments/payments/test-card-details/)

## Security Notes

1. **API Keys**: Never commit Razorpay API keys to version control
2. **Authentication**: All callable functions verify user authentication
3. **Authorization**: Users can only create orders and verify payments for themselves
4. **Signature Verification**: Payment signatures are verified using HMAC SHA256
5. **Firestore Rules**: Ensure Firestore security rules are properly configured

## Firestore Collections Used

- `subscriptions` - Subscription records
- `users` - User documents (updated with subscription status)
- `payments` - Payment history (written by client app)

## Environment Variables

Required environment variables (set via Firebase Functions Config):

```
razorpay.key_id = "YOUR_RAZORPAY_KEY_ID"
razorpay.key_secret = "YOUR_RAZORPAY_KEY_SECRET"
```

## Troubleshooting

### Function deployment fails

```bash
# Make sure you're logged in
firebase login

# Make sure you're using the correct project
firebase use YOUR_PROJECT_ID

# Check your Firebase plan (Cloud Functions require Blaze plan)
```

### Razorpay credentials not found

```bash
# Verify config is set
firebase functions:config:get

# If missing, set them:
firebase functions:config:set razorpay.key_id="YOUR_KEY"
firebase functions:config:set razorpay.key_secret="YOUR_SECRET"

# Redeploy functions
npm run deploy
```

### Payment verification fails

- Check that Razorpay webhook is not enabled (we use client-side verification)
- Verify the signature format matches Razorpay's documentation
- Check Cloud Functions logs for detailed error messages

## Cost Considerations

- Cloud Functions are billed based on invocations and compute time
- Scheduled functions (checkExpiredSubscriptions) run once daily
- Callable functions only run when invoked by the app
- Monitor usage in Firebase Console → Functions → Usage

## Next Steps

1. Set up Razorpay account and get API credentials
2. Configure environment variables
3. Deploy functions to Firebase
4. Test payment flow end-to-end
5. Set up monitoring and alerts in Firebase Console
