# User Subscription APIs Reference

## Scope

This document details the user-facing subscription management APIs, including plan discovery, Razorpay order initialization, payment verification, subscription status checks, historical subscriptions, and cancellation/re-verification processes.

## Source Files Analysed

Controller:
- `src/main/java/com/veena/veenabackend/controller/UserSubscriptionController.java`

DTOs:
- `src/main/java/com/veena/veenabackend/dto/subscription/SubscribeRequest.java`
- `src/main/java/com/veena/veenabackend/dto/subscription/SubscriptionPaymentVerifyRequest.java`
- `src/main/java/com/veena/veenabackend/dto/subscription/SubscriptionPlanResponse.java`
- `src/main/java/com/veena/veenabackend/dto/subscription/SubscriptionStatusResponse.java`
- `src/main/java/com/veena/veenabackend/dto/subscription/UserSubscriptionResponse.java`

Enums:
- `src/main/java/com/veena/veenabackend/enums/SubscriptionPlanType.java`
- `src/main/java/com/veena/veenabackend/enums/SubscriptionStatus.java`

---

## Base Path: `/api/subscriptions`

All routes require user authentication. The current user ID is automatically extracted from the secure context.

---

## 1. Endpoints

### 1.1 Get Active Plans
Get all active subscription plans available for purchase.

- **Method**: `GET`
- **Path**: `/api/subscriptions/plans`
- **Request Headers**: `Authorization: Bearer <token>`
- **Request Payload**: None (Empty)
- **Response**: `200 OK`
- **Response Payload**: `List<SubscriptionPlanResponse>`
  ```json
  [
    {
      "id": 1,
      "name": "Premium Monthly",
      "planType": "MONTHLY",
      "durationMonths": 1,
      "price": 199.00,
      "currency": "INR",
      "description": "Ad-free streaming and premium content access",
      "isActive": true
    }
  ]
  ```

---

### 1.2 Subscribe to Plan
Initialize a subscription to a plan. Returns a Razorpay order entity for completing the payment on the client side.

- **Method**: `POST`
- **Path**: `/api/subscriptions/subscribe`
- **Request Headers**: `Authorization: Bearer <token>`
- **Request Payload**: `SubscribeRequest`
  ```json
  {
    "planId": 1,
    "autoRenew": false
  }
  ```
- **Response**: `201 Created`
- **Response Payload**: `UserSubscriptionResponse`
  ```json
  {
    "id": 101,
    "userId": "d3b07384-d113-4a1b-a5b8-7a91550236c1",
    "userName": "John Doe",
    "userEmail": "john.doe@example.com",
    "plan": {
      "id": 1,
      "name": "Premium Monthly",
      "planType": "MONTHLY",
      "durationMonths": 1,
      "price": 199.00,
      "currency": "INR",
      "description": "Ad-free streaming and premium content access",
      "isActive": true
    },
    "status": "PENDING",
    "startDate": null,
    "endDate": null,
    "autoRenew": false,
    "razorpayOrderId": "order_OPd9283JD912",
    "razorpayPaymentId": null,
    "paymentAmount": 199.00,
    "paymentCurrency": "INR",
    "createdAt": "2026-05-17T14:14:32Z",
    "updatedAt": "2026-05-17T14:14:32Z"
  }
  ```

---

### 1.3 Verify Payment
Verify payment signature and activate the subscription after successful payment on Razorpay.

- **Method**: `POST`
- **Path**: `/api/subscriptions/verify-payment`
- **Request Headers**: `Authorization: Bearer <token>`
- **Request Payload**: `SubscriptionPaymentVerifyRequest`
  ```json
  {
    "subscriptionId": 101,
    "razorpayOrderId": "order_OPd9283JD912",
    "razorpayPaymentId": "pay_PJ82103JS89A",
    "razorpaySignature": "827cb962ac59075b964b07152d234b70b2345672ab893de4568abcd23674ff21"
  }
  ```
- **Response**: `200 OK`
- **Response Payload**: `UserSubscriptionResponse`
  ```json
  {
    "id": 101,
    "userId": "d3b07384-d113-4a1b-a5b8-7a91550236c1",
    "userName": "John Doe",
    "userEmail": "john.doe@example.com",
    "plan": {
      "id": 1,
      "name": "Premium Monthly",
      "planType": "MONTHLY",
      "durationMonths": 1,
      "price": 199.00,
      "currency": "INR",
      "description": "Ad-free streaming and premium content access",
      "isActive": true
    },
    "status": "ACTIVE",
    "startDate": "2026-05-17T14:14:32Z",
    "endDate": "2026-06-17T14:14:32Z",
    "autoRenew": false,
    "razorpayOrderId": "order_OPd9283JD912",
    "razorpayPaymentId": "pay_PJ82103JS89A",
    "paymentAmount": 199.00,
    "paymentCurrency": "INR",
    "createdAt": "2026-05-17T14:14:32Z",
    "updatedAt": "2026-05-17T14:15:10Z"
  }
  ```

---

### 1.4 Check Subscription Status
Check whether the authenticated user has an active subscription and whether ads should be displayed to them.

- **Method**: `GET`
- **Path**: `/api/subscriptions/status`
- **Request Headers**: `Authorization: Bearer <token>`
- **Request Payload**: None (Empty)
- **Response**: `200 OK`
- **Response Payload**: `SubscriptionStatusResponse`
  ```json
  {
    "isSubscribed": true,
    "showAds": false,
    "activeSubscription": {
      "id": 101,
      "userId": "d3b07384-d113-4a1b-a5b8-7a91550236c1",
      "userName": "John Doe",
      "userEmail": "john.doe@example.com",
      "plan": {
        "id": 1,
        "name": "Premium Monthly",
        "planType": "MONTHLY",
        "durationMonths": 1,
        "price": 199.00,
        "currency": "INR",
        "description": "Ad-free streaming and premium content access",
        "isActive": true
      },
      "status": "ACTIVE",
      "startDate": "2026-05-17T14:14:32Z",
      "endDate": "2026-06-17T14:14:32Z",
      "autoRenew": false,
      "razorpayOrderId": "order_OPd9283JD912",
      "razorpayPaymentId": "pay_PJ82103JS89A",
      "paymentAmount": 199.00,
      "paymentCurrency": "INR",
      "createdAt": "2026-05-17T14:14:32Z",
      "updatedAt": "2026-05-17T14:15:10Z"
    }
  }
  ```

---

### 1.5 Get Subscription History
Retrieve all past subscriptions purchased by the authenticated user.

- **Method**: `GET`
- **Path**: `/api/subscriptions/history`
- **Request Headers**: `Authorization: Bearer <token>`
- **Request Payload**: None (Empty)
- **Response**: `200 OK`
- **Response Payload**: `List<UserSubscriptionResponse>`
  ```json
  [
    {
      "id": 101,
      "userId": "d3b07384-d113-4a1b-a5b8-7a91550236c1",
      "userName": "John Doe",
      "userEmail": "john.doe@example.com",
      "plan": {
        "id": 1,
        "name": "Premium Monthly",
        "planType": "MONTHLY",
        "durationMonths": 1,
        "price": 199.00,
        "currency": "INR",
        "description": "Ad-free streaming and premium content access",
        "isActive": true
      },
      "status": "ACTIVE",
      "startDate": "2026-05-17T14:14:32Z",
      "endDate": "2026-06-17T14:14:32Z",
      "autoRenew": false,
      "razorpayOrderId": "order_OPd9283JD912",
      "razorpayPaymentId": "pay_PJ82103JS89A",
      "paymentAmount": 199.00,
      "paymentCurrency": "INR",
      "createdAt": "2026-05-17T14:14:32Z",
      "updatedAt": "2026-05-17T14:15:10Z"
    }
  ]
  ```

---

### 1.6 Cancel Subscription
Cancel an active subscription.

- **Method**: `POST`
- **Path**: `/api/subscriptions/{id}/cancel`
- **Request Headers**: `Authorization: Bearer <token>`
- **Path Parameters**:
  - `id` (Long, required): The ID of the subscription to cancel.
- **Query Parameters**:
  - `reason` (String, optional): The cancellation reason.
- **Request Payload**: None (Empty)
- **Response**: `200 OK`
- **Response Payload**: `UserSubscriptionResponse`
  ```json
  {
    "id": 101,
    "userId": "d3b07384-d113-4a1b-a5b8-7a91550236c1",
    "userName": "John Doe",
    "userEmail": "john.doe@example.com",
    "plan": {
      "id": 1,
      "name": "Premium Monthly",
      "planType": "MONTHLY",
      "durationMonths": 1,
      "price": 199.00,
      "currency": "INR",
      "description": "Ad-free streaming and premium content access",
      "isActive": true
    },
    "status": "CANCELLED",
    "startDate": "2026-05-17T14:14:32Z",
    "endDate": "2026-06-17T14:14:32Z",
    "autoRenew": false,
    "razorpayOrderId": "order_OPd9283JD912",
    "razorpayPaymentId": "pay_PJ82103JS89A",
    "paymentAmount": 199.00,
    "paymentCurrency": "INR",
    "cancelledAt": "2026-05-17T14:20:00Z",
    "cancelReason": "No longer needed",
    "createdAt": "2026-05-17T14:14:32Z",
    "updatedAt": "2026-05-17T14:20:00Z"
  }
  ```

---

### 1.7 Re-verify Payment
Re-verify a `PENDING` subscription by checking its payment status directly with the Razorpay API. Use this when the user made a successful payment but the initial client-side `verify-payment` call failed (e.g. due to network issues, device crash, or closing the application prematurely).

- **Method**: `POST`
- **Path**: `/api/subscriptions/{id}/re-verify`
- **Request Headers**: `Authorization: Bearer <token>`
- **Path Parameters**:
  - `id` (Long, required): The ID of the subscription to re-verify.
- **Request Payload**: None (Empty)
- **Response**: `200 OK`
- **Response Payload**: `UserSubscriptionResponse`
  ```json
  {
    "id": 101,
    "userId": "d3b07384-d113-4a1b-a5b8-7a91550236c1",
    "userName": "John Doe",
    "userEmail": "john.doe@example.com",
    "plan": {
      "id": 1,
      "name": "Premium Monthly",
      "planType": "MONTHLY",
      "durationMonths": 1,
      "price": 199.00,
      "currency": "INR",
      "description": "Ad-free streaming and premium content access",
      "isActive": true
    },
    "status": "ACTIVE",
    "startDate": "2026-05-17T14:14:32Z",
    "endDate": "2026-06-17T14:14:32Z",
    "autoRenew": false,
    "razorpayOrderId": "order_OPd9283JD912",
    "razorpayPaymentId": "pay_PJ82103JS89A",
    "paymentAmount": 199.00,
    "paymentCurrency": "INR",
    "createdAt": "2026-05-17T14:14:32Z",
    "updatedAt": "2026-05-17T14:22:15Z"
  }
  ```

---

## 2. Models & Enums

### 2.1 Enums

#### SubscriptionPlanType
Represents the length and billing frequency of a plan.
- `MONTHLY` (1 Month)
- `QUARTERLY` (3 Months)
- `YEARLY` (12 Months)

#### SubscriptionStatus
Represents the current state of a user's subscription.
- `PENDING`: Order initiated, payment not yet completed or verified.
- `ACTIVE`: Payment verified, subscription is active.
- `EXPIRED`: Subscription validity period has passed.
- `CANCELLED`: Subscription has been cancelled by the user.
- `PAYMENT_FAILED`: Payment verification explicitly failed or rejected.
