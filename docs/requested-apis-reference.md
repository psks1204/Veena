# Requested APIs Reference

## Scope

This document covers the requested controllers:

- `WebhookController`
- `UserSubscriptionController`
- `PaymentController`
- `InvoiceController`

The content below is based on the current implementation in controller, DTO, service, and security classes.

## Source Files Analysed

Controllers:

- `src/main/java/com/veena/veenabackend/controller/WebhookController.java`
- `src/main/java/com/veena/veenabackend/controller/UserSubscriptionController.java`
- `src/main/java/com/veena/veenabackend/controller/PaymentController.java`
- `src/main/java/com/veena/veenabackend/controller/InvoiceController.java`

Support classes:

- `src/main/java/com/veena/veenabackend/service/RazorpayService.java`
- `src/main/java/com/veena/veenabackend/service/SubscriptionService.java`
- `src/main/java/com/veena/veenabackend/service/InvoiceService.java`
- `src/main/java/com/veena/veenabackend/service/ProfileService.java`
- `src/main/java/com/veena/veenabackend/config/SecurityConfig.java`
- Relevant DTO classes under `src/main/java/com/veena/veenabackend/dto/subscription` and `src/main/java/com/veena/veenabackend/dto/ecom`

## Authentication and Access Rules

### Public Endpoints (PermitAll)

From `SecurityConfig`:

- `/api/subscriptions/plans`
- `/api/webhooks/**` (secured via signature verification)

### Admin Endpoints

- `/api/admin/**` (requires `ROLE_ADMIN`)

### Authenticated Endpoints

- All other `/api/**` endpoints require a valid JWT token.
- This includes all payment, subscription (except plans), and user invoice endpoints.

---

## Common Request and Response Conventions

### Content types

- Standard JSON endpoints: `application/json`
- Webhook payloads:
  - Razorpay: Raw body (`String`)
  - Shiprocket: `application/json` (mapped to `Map<String, Object>`)

### Standard error envelope

Most endpoints return this structure on errors:

```json
{
  "timestamp": "2026-04-26 14:10:21",
  "status": 400,
  "error": "Bad Request",
  "message": "Validation failed",
  "path": "/api/...",
  "traceId": "AB12CD34",
  "fieldErrors": [
    {
      "field": "planId",
      "message": "must not be null",
      "rejectedValue": null
    }
  ]
}
```

---

## Shared DTO Schemas

### `SubscriptionPlanResponse`

```json
{
  "id": 1,
  "name": "Premium Monthly",
  "planType": "MONTHLY",
  "durationMonths": 1,
  "price": 299.00,
  "currency": "INR",
  "description": "Premium access for 1 month",
  "isActive": true
}
```

### `SubscribeRequest`

```json
{
  "planId": 1,
  "autoRenew": true
}
```

### `UserSubscriptionResponse`

```json
{
  "id": 10,
  "userId": "uuid",
  "userName": "John Doe",
  "userEmail": "john@example.com",
  "plan": {
    "id": 1,
    "name": "Premium Monthly",
    "planType": "MONTHLY",
    "durationMonths": 1,
    "price": 299.00,
    "currency": "INR"
  },
  "status": "ACTIVE",
  "startDate": "2026-04-26T10:00:00Z",
  "endDate": "2026-05-26T10:00:00Z",
  "autoRenew": true,
  "razorpayOrderId": "order_abc123",
  "razorpayPaymentId": "pay_xyz789",
  "paymentAmount": 299.00,
  "paymentCurrency": "INR",
  "cancelledAt": null,
  "cancelReason": null,
  "createdAt": "2026-04-26T10:00:00Z",
  "updatedAt": "2026-04-26T10:00:00Z"
}
```

### `SubscriptionPaymentVerifyRequest`

```json
{
  "subscriptionId": 10,
  "razorpayOrderId": "order_abc123",
  "razorpayPaymentId": "pay_xyz789",
  "razorpaySignature": "sig_123"
}
```

### `SubscriptionStatusResponse`

```json
{
  "isSubscribed": true,
  "showAds": false,
  "activeSubscription": { "..." : "UserSubscriptionResponse" }
}
```

### `PaymentResponse`

```json
{
  "id": 1,
  "razorpayOrderId": "order_abc123",
  "razorpayPaymentId": "pay_xyz789",
  "amount": 1177.64,
  "currency": "INR",
  "status": "CAPTURED",
  "method": "card",
  "createdAt": "2026-04-26T10:00:00Z"
}
```

### `PaymentVerifyRequest`

```json
{
  "razorpayOrderId": "order_abc123",
  "razorpayPaymentId": "pay_xyz789",
  "razorpaySignature": "sig_123"
}
```

### `InvoiceResponse`

```json
{
  "id": 1,
  "invoiceNumber": "INV-2026-001",
  "userId": "uuid",
  "userName": "John Doe",
  "userEmail": "john@example.com",
  "invoiceType": "ECOM_ORDER",
  "referenceId": 100,
  "subtotal": 1000.00,
  "taxAmount": 180.00,
  "discountAmount": 0.00,
  "totalAmount": 1180.00,
  "currency": "INR",
  "paymentMethod": "RAZORPAY",
  "paymentId": "pay_abc123",
  "billingName": "John Doe",
  "billingEmail": "john@example.com",
  "billingPhone": "9876543210",
  "billingAddress": "123 Street, City",
  "notes": "Optional notes",
  "pdfUrl": "https://...",
  "status": "PAID",
  "createdAt": "2026-04-26T10:00:00Z"
}
```

---

## Controller-by-Controller API List

---

## 1. WebhookController

Base path: `/api/webhooks`

Auth:
- Public (permitAll).
- Security via signature verification.

### 1.1 Razorpay Webhook

- Method: `POST`
- Path: `/api/webhooks/razorpay`
- Headers:
  - `X-Razorpay-Signature`: signature for verification
- Body: `String` (Raw payload)
- Success response: `200 OK`

### 1.2 Shiprocket Webhook

- Method: `POST`
- Path: `/api/webhooks/shiprocket`
- Body: `JSON` (Map of fields)
- Success response: `200 OK`

---

## 2. UserSubscriptionController

Base path: `/api/subscriptions`

Auth:
- `/plans` is Public.
- Others require Authentication.

### 2.1 Get Subscription Plans

- Method: `GET`
- Path: `/api/subscriptions/plans`
- Success response: `200 OK` with `List<SubscriptionPlanResponse>`

### 2.2 Subscribe to Plan

- Method: `POST`
- Path: `/api/subscriptions/subscribe`
- Body: `SubscribeRequest`
- Success response: `201 Created` with `UserSubscriptionResponse`
- Behavior:
  - Returns a `UserSubscriptionResponse` which includes the `razorpayOrderId` to be used in the frontend.

### 2.3 Verify Subscription Payment

- Method: `POST`
- Path: `/api/subscriptions/verify-payment`
- Body: `SubscriptionPaymentVerifyRequest`
- Success response: `200 OK` with activated `UserSubscriptionResponse`

### 2.4 Get Current Status

- Method: `GET`
- Path: `/api/subscriptions/status`
- Success response: `200 OK` with `SubscriptionStatusResponse`
- Behavior:
  - Indicates if user is currently subscribed and if ads should be shown.

### 2.5 Get Subscription History

- Method: `GET`
- Path: `/api/subscriptions/history`
- Success response: `200 OK` with `List<UserSubscriptionResponse>`

### 2.6 Cancel Subscription

- Method: `POST`
- Path: `/api/subscriptions/{id}/cancel`
- Path params:
  - `id`: `Long`, required (Subscription ID)
- Query params:
  - `reason`: `String`, optional
- Success response: `200 OK` with updated `UserSubscriptionResponse`

---

## 3. PaymentController

Base path: `/api/ecom/payments`

Auth:
- Authentication required.

### 3.1 Create Payment Order for E-commerce

- Method: `POST`
- Path: `/api/ecom/payments/create-order/{orderId}`
- Path params:
  - `orderId`: `Long`, required
- Success response: `200 OK` with `PaymentResponse`
- Behavior:
  - Creates/retrieves a Razorpay order for an existing E-commerce order.

### 3.2 Verify E-commerce Payment

- Method: `POST`
- Path: `/api/ecom/payments/verify`
- Body: `PaymentVerifyRequest`
- Success response: `200 OK` with `PaymentResponse`

---

## 4. InvoiceController

Base path: `/api`

Auth:
- User endpoints: Authentication required.
- Admin endpoints: `ROLE_ADMIN` required.

### 4.1 Get My Invoices

- Method: `GET`
- Path: `/api/invoices`
- Success response: `200 OK` with `List<InvoiceResponse>`

### 4.2 Get Invoice Details

- Method: `GET`
- Path: `/api/invoices/{id}`
- Path params:
  - `id`: `Long`, required
- Success response: `200 OK` with `InvoiceResponse`

### 4.3 Get Invoice for Order

- Method: `GET`
- Path: `/api/ecom/orders/{orderId}/invoice`
- Path params:
  - `orderId`: `Long`, required
- Success response: `200 OK` with `InvoiceResponse`

### 4.4 Generate Invoice for Order (On-demand)

- Method: `POST`
- Path: `/api/ecom/orders/{orderId}/invoice/generate`
- Path params:
  - `orderId`: `Long`, required
- Success response: `200 OK` with `InvoiceResponse`

### 4.5 Download Invoice PDF

- Method: `GET`
- Path: `/api/invoices/{id}/pdf`
- Path params:
  - `id`: `Long`, required
- Success response: `200 OK` with `byte[]` (PDF file)
- Response headers:
  - `Content-Type`: `application/pdf`
  - `Content-Disposition`: `attachment; filename=invoice-{id}.pdf`

### 4.6 Get Invoice for Subscription

- Method: `GET`
- Path: `/api/subscriptions/{subscriptionId}/invoice`
- Path params:
  - `subscriptionId`: `Long`, required
- Success response: `200 OK` with `InvoiceResponse`

### 4.7 Admin: Generate Order Invoice

- Method: `POST`
- Path: `/api/admin/ecom/orders/{orderId}/invoice/generate`
- Path params:
  - `orderId`: `Long`, required
- Success response: `200 OK` with `InvoiceResponse`

### 4.8 Admin: Download Any Invoice PDF

- Method: `GET`
- Path: `/api/admin/invoices/{id}/pdf`
- Path params:
  - `id`: `Long`, required
- Success response: `200 OK` with `byte[]` (PDF file)
