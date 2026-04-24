# User Channel and E-Commerce API Reference

## Scope

This document covers the requested controllers:

- `UserEcomCatalogController`
- `UserOrderController`
- `PaymentController`
- `WebhookController`
- `UserCartController`
- `UserChannelController`

It also includes an additional user-facing e-commerce controller found during analysis:

- `UserAddressController`

The content below is based on the current implementation in controller, DTO, service, security, and exception-handling classes.

## Source Files Analysed

Controllers:

- `src/main/java/com/veena/veenabackend/controller/UserEcomCatalogController.java`
- `src/main/java/com/veena/veenabackend/controller/UserOrderController.java`
- `src/main/java/com/veena/veenabackend/controller/PaymentController.java`
- `src/main/java/com/veena/veenabackend/controller/WebhookController.java`
- `src/main/java/com/veena/veenabackend/controller/UserCartController.java`
- `src/main/java/com/veena/veenabackend/controller/UserChannelController.java`
- `src/main/java/com/veena/veenabackend/controller/UserAddressController.java`

Support classes:

- `src/main/java/com/veena/veenabackend/service/CategoryService.java`
- `src/main/java/com/veena/veenabackend/service/ProductService.java`
- `src/main/java/com/veena/veenabackend/service/CartService.java`
- `src/main/java/com/veena/veenabackend/service/OrderService.java`
- `src/main/java/com/veena/veenabackend/service/AddressService.java`
- `src/main/java/com/veena/veenabackend/service/RazorpayService.java`
- `src/main/java/com/veena/veenabackend/service/ShiprocketService.java`
- `src/main/java/com/veena/veenabackend/service/ChannelService.java`
- `src/main/java/com/veena/veenabackend/config/SecurityConfig.java`
- `src/main/java/com/veena/veenabackend/exception/GlobalExceptionHandler.java`
- Relevant DTO and enum classes under `src/main/java/com/veena/veenabackend/dto` and `src/main/java/com/veena/veenabackend/enums`

## Authentication and Access Rules

### Non-local profiles

From `SecurityConfig`:

- Public without JWT:
  - `/api/ecom/categories/**`
  - `/api/ecom/products/**`
  - `/api/webhooks/**`
- Admin only:
  - `/api/admin/**`
- All other `/api/**` endpoints require authentication.

### Local profile

When the `local` Spring profile is active, all endpoints are permitted and a synthetic `local-admin` authentication is injected.

### Important auth nuance

Some controller comments describe an endpoint as public, but the actual security rules still require authentication unless the path is explicitly permitted in `SecurityConfig`.

Examples:

- `GET /api/user/channel/public/{channelId}` is not anonymous in non-local environments because it still matches `/api/**`.
- All cart, address, order, payment, and channel management endpoints require authentication in non-local environments.

## Common Request and Response Conventions

### Content types

- Standard JSON endpoints: `application/json`
- File upload endpoints: `multipart/form-data`
- Webhook payloads:
  - Razorpay webhook: raw request body as `String`
  - Shiprocket webhook: JSON object mapped as `Map<String, Object>`

### Pagination

Endpoints that accept `Pageable` use standard Spring Data query params:

- `page`
- `size`
- `sort`

Typical paginated response shape is Spring Page JSON, with fields such as:

```json
{
  "content": [],
  "pageable": {},
  "totalElements": 0,
  "totalPages": 0,
  "size": 20,
  "number": 0,
  "first": true,
  "last": true,
  "sort": {},
  "numberOfElements": 0,
  "empty": true
}
```

### Standard error envelope

Most endpoints rely on `GlobalExceptionHandler` and return this structure on errors:

```json
{
  "timestamp": "2026-04-24 14:10:21",
  "status": 400,
  "error": "Bad Request",
  "message": "Validation failed",
  "path": "/api/ecom/cart/items",
  "traceId": "AB12CD34",
  "fieldErrors": [
    {
      "field": "quantity",
      "message": "Quantity must be at least 1",
      "rejectedValue": 0
    }
  ]
}
```

### Exception to the standard error envelope

`UserChannelController` catches several exceptions locally and sometimes returns non-standard responses:

- `400` with body like `{ "error": "...message..." }`
- `500` with body like `{ "error": "Failed to ..." }`
- `500` with `null` body for some methods
- `404` with empty body for `GET /api/user/channel/public/{channelId}`

## Shared DTO Schemas

### `ChannelRequest`

```json
{
  "channelName": "My Channel",
  "channelHandle": "my-channel",
  "description": "Optional description"
}
```

Fields:

- `channelName`: `String`, optional
- `channelHandle`: `String`, optional, sanitized to lowercase kebab-like text
- `description`: `String`, optional

### `ChannelResponse`

```json
{
  "id": "uuid",
  "userId": "uuid",
  "userName": "User Name",
  "userEmail": "user@example.com",
  "channelName": "My Channel",
  "channelHandle": "my-channel",
  "description": "Optional description",
  "imageUrl": "https://...",
  "active": true,
  "subscriberCount": 0,
  "totalViews": 0,
  "createdAt": "2026-04-24T10:00:00Z",
  "updatedAt": "2026-04-24T10:00:00Z",
  "totalMedia": 0,
  "pendingMedia": 0,
  "approvedMedia": 0
}
```

### `UserMediaResponse`

```json
{
  "id": "uuid",
  "title": "Song Title",
  "description": "Optional description",
  "mediaType": "AUDIO",
  "status": "UPLOADING",
  "approvalStatus": "PENDING",
  "rejectionReason": null,
  "hlsUrl": "https://...m3u8",
  "thumbnailUrl": "https://...",
  "fileSize": 123456,
  "fileExtension": "mp3",
  "playCount": 0,
  "durationSeconds": null,
  "createdAt": "2026-04-24T10:00:00Z",
  "updatedAt": "2026-04-24T10:00:00Z",
  "reviewedAt": null,
  "channelId": "uuid",
  "channelName": "My Channel",
  "uploadedById": "uuid",
  "uploadedByName": "Uploader Name",
  "uploadedByEmail": "uploader@example.com"
}
```

Enum values used here:

- `mediaType`: `VIDEO`, `AUDIO`
- `status`: `UPLOADING`, `PROCESSING`, `READY`, `FAILED`
- `approvalStatus`: `PENDING`, `APPROVED`, `REJECTED`

### `AddressRequest`

```json
{
  "fullName": "John Doe",
  "phone": "9876543210",
  "addressLine1": "Flat 2A, Main Road",
  "addressLine2": "Near Temple",
  "city": "Chennai",
  "state": "Tamil Nadu",
  "pincode": "600001",
  "country": "India",
  "isDefault": true
}
```

Validation:

- `fullName`: required, max 255
- `phone`: required, max 20
- `addressLine1`: required, max 500
- `addressLine2`: optional, max 500
- `city`: required, max 100
- `state`: required, max 100
- `pincode`: required, max 10
- `country`: optional, max 100
- `isDefault`: optional `Boolean`

### `AddressResponse`

```json
{
  "id": 1,
  "fullName": "John Doe",
  "phone": "9876543210",
  "addressLine1": "Flat 2A, Main Road",
  "addressLine2": "Near Temple",
  "city": "Chennai",
  "state": "Tamil Nadu",
  "pincode": "600001",
  "country": "India",
  "isDefault": true,
  "createdAt": "2026-04-24T10:00:00Z"
}
```

### `AddToCartRequest`

```json
{
  "productId": 100,
  "variantId": 200,
  "quantity": 2
}
```

Validation:

- `productId`: required
- `variantId`: optional
- `quantity`: required, minimum `1`

### `UpdateCartItemRequest`

```json
{
  "quantity": 3
}
```

Validation:

- `quantity`: required, minimum `1`

### `CartResponse`

```json
{
  "id": 1,
  "items": [
    {
      "id": 1,
      "productId": 100,
      "productName": "Product Name",
      "productImage": "https://...",
      "variantId": 200,
      "variantName": "Red / Large",
      "unitPrice": 499.00,
      "quantity": 2,
      "totalPrice": 998.00,
      "inStock": true,
      "availableQuantity": 10
    }
  ],
  "totalItems": 2,
  "subtotal": 998.00,
  "taxAmount": 179.64,
  "totalAmount": 1177.64
}
```

### `PlaceOrderRequest`

```json
{
  "addressId": 1,
  "notes": "Leave at the front desk"
}
```

Validation:

- `addressId`: required
- `notes`: optional

### `CancelOrderRequest`

```json
{
  "reason": "Ordered by mistake"
}
```

### `OrderResponse`

```json
{
  "id": 10,
  "orderNumber": "VN202604241234",
  "status": "PENDING",
  "subtotal": 998.00,
  "taxAmount": 179.64,
  "shippingCharge": 0.00,
  "discountAmount": 0.00,
  "totalAmount": 1177.64,
  "currency": "INR",
  "shippingName": "John Doe",
  "shippingPhone": "9876543210",
  "shippingAddress1": "Flat 2A, Main Road",
  "shippingAddress2": "Near Temple",
  "shippingCity": "Chennai",
  "shippingState": "Tamil Nadu",
  "shippingPincode": "600001",
  "shippingCountry": "India",
  "notes": "Leave at the front desk",
  "cancelReason": null,
  "items": [
    {
      "id": 1,
      "productId": 100,
      "variantId": 200,
      "productName": "Product Name",
      "variantName": "Red / Large",
      "sku": "SKU-100",
      "quantity": 2,
      "unitPrice": 499.00,
      "taxPercent": 18.00,
      "taxAmount": 179.64,
      "totalPrice": 1177.64
    }
  ],
  "payment": {
    "id": 1,
    "razorpayOrderId": "order_abc",
    "razorpayPaymentId": null,
    "amount": 1177.64,
    "currency": "INR",
    "status": "CREATED",
    "method": null,
    "createdAt": "2026-04-24T10:00:00Z"
  },
  "shipment": {
    "id": 1,
    "shiprocketOrderId": "12345",
    "shiprocketShipmentId": "67890",
    "awbCode": "AWB123",
    "courierName": "Courier",
    "status": "IN_TRANSIT",
    "trackingUrl": "https://...",
    "estimatedDelivery": null,
    "shippedAt": "2026-04-24T10:00:00Z",
    "deliveredAt": null
  },
  "userName": "John Doe",
  "userEmail": "john@example.com",
  "cancelledAt": null,
  "createdAt": "2026-04-24T10:00:00Z",
  "updatedAt": "2026-04-24T10:00:00Z"
}
```

Order status enum values:

- `PENDING`
- `CONFIRMED`
- `PROCESSING`
- `SHIPPED`
- `OUT_FOR_DELIVERY`
- `DELIVERED`
- `CANCELLED`
- `RETURN_REQUESTED`
- `RETURNED`
- `REFUNDED`

Shipment status enum values:

- `PENDING`
- `PICKUP_SCHEDULED`
- `PICKED_UP`
- `IN_TRANSIT`
- `OUT_FOR_DELIVERY`
- `DELIVERED`
- `RTO_INITIATED`
- `RTO_DELIVERED`
- `CANCELLED`

### `CategoryResponse`

```json
{
  "id": 1,
  "name": "Books",
  "slug": "books",
  "description": "Category description",
  "imageUrl": "https://...",
  "parentId": null,
  "parentName": null,
  "displayOrder": 0,
  "isActive": true,
  "children": [],
  "productCount": 20,
  "createdAt": "2026-04-24T10:00:00Z",
  "updatedAt": "2026-04-24T10:00:00Z"
}
```

### `ProductResponse`

```json
{
  "id": 100,
  "name": "Product Name",
  "slug": "product-name",
  "description": "Full description",
  "shortDescription": "Short description",
  "sku": "SKU-100",
  "price": 499.00,
  "compareAtPrice": 599.00,
  "costPrice": 300.00,
  "quantity": 10,
  "lowStockThreshold": 5,
  "weightGrams": 500,
  "lengthCm": 10.00,
  "breadthCm": 5.00,
  "heightCm": 3.00,
  "isActive": true,
  "isFeatured": false,
  "hsnCode": "1234",
  "taxPercent": 18.00,
  "inStock": true,
  "discountPercent": 16.69,
  "categoryId": 1,
  "categoryName": "Books",
  "images": [
    {
      "id": 1,
      "imageUrl": "https://...",
      "altText": "Front image",
      "displayOrder": 0,
      "isPrimary": true
    }
  ],
  "variants": [
    {
      "id": 200,
      "name": "Red / Large",
      "sku": "SKU-100-RED-L",
      "price": 549.00,
      "quantity": 5,
      "attributes": {
        "color": "red",
        "size": "large"
      },
      "isActive": true,
      "inStock": true
    }
  ],
  "createdAt": "2026-04-24T10:00:00Z",
  "updatedAt": "2026-04-24T10:00:00Z"
}
```

### `PaymentVerifyRequest`

```json
{
  "razorpayOrderId": "order_abc",
  "razorpayPaymentId": "pay_xyz",
  "razorpaySignature": "signature_string"
}
```

Validation:

- `razorpayOrderId`: required, non-blank
- `razorpayPaymentId`: required, non-blank
- `razorpaySignature`: required, non-blank

### `PaymentResponse`

```json
{
  "id": 1,
  "razorpayOrderId": "order_abc",
  "razorpayPaymentId": "pay_xyz",
  "amount": 1177.64,
  "currency": "INR",
  "status": "CAPTURED",
  "method": null,
  "createdAt": "2026-04-24T10:00:00Z"
}
```

Payment status enum values:

- `CREATED`
- `AUTHORIZED`
- `CAPTURED`
- `FAILED`
- `REFUND_INITIATED`
- `REFUNDED`

## Controller-by-Controller API List

---

## 1. UserEcomCatalogController

Base path: `/api/ecom`

Auth:

- Public in non-local environments for category and product browsing paths.

### 1.1 Get Categories

- Method: `GET`
- Path: `/api/ecom/categories`
- Request type: `application/json`
- Path params: none
- Query params: none
- Body: none
- Success response: `200 OK` with `List<CategoryResponse>`
- Behavior:
  - Returns active root categories.
  - Each category may include nested `children` recursively.

### 1.2 Get Category By ID

- Method: `GET`
- Path: `/api/ecom/categories/{id}`
- Request type: `application/json`
- Path params:
  - `id`: `Long`, required
- Query params: none
- Body: none
- Success response: `200 OK` with `CategoryResponse`
- Error cases:
  - `404` if category does not exist

### 1.3 Get Products By Category

- Method: `GET`
- Path: `/api/ecom/categories/{categoryId}/products`
- Request type: `application/json`
- Path params:
  - `categoryId`: `Long`, required
- Query params:
  - `page`: optional
  - `size`: optional
  - `sort`: optional
- Body: none
- Success response: `200 OK` with `Page<ProductResponse>`
- Behavior:
  - Returns only active products in the category.

### 1.4 Browse Products

- Method: `GET`
- Path: `/api/ecom/products`
- Request type: `application/json`
- Path params: none
- Query params:
  - `page`: optional
  - `size`: optional
  - `sort`: optional
- Body: none
- Success response: `200 OK` with `Page<ProductResponse>`
- Behavior:
  - Returns active products only.

### 1.5 Search Products

- Method: `GET`
- Path: `/api/ecom/products/search`
- Request type: `application/json`
- Path params: none
- Query params:
  - `query`: `String`, required
  - `page`: optional
  - `size`: optional
  - `sort`: optional
- Body: none
- Success response: `200 OK` with `Page<ProductResponse>`

### 1.6 Get Featured Products

- Method: `GET`
- Path: `/api/ecom/products/featured`
- Request type: `application/json`
- Path params: none
- Query params:
  - `page`: optional
  - `size`: optional
  - `sort`: optional
- Body: none
- Success response: `200 OK` with `Page<ProductResponse>`
- Behavior:
  - Returns active products where `isFeatured = true`.

### 1.7 Get Product By ID

- Method: `GET`
- Path: `/api/ecom/products/{id}`
- Request type: `application/json`
- Path params:
  - `id`: `Long`, required
- Query params: none
- Body: none
- Success response: `200 OK` with `ProductResponse`
- Error cases:
  - `404` if product does not exist
  - `404` if product exists but is inactive

---

## 2. UserCartController

Base path: `/api/ecom/cart`

Auth:

- Auth required in non-local environments.

### 2.1 Get Cart

- Method: `GET`
- Path: `/api/ecom/cart`
- Request type: `application/json`
- Path params: none
- Query params: none
- Body: none
- Success response: `200 OK` with `CartResponse`
- Behavior:
  - Auto-creates a cart if the current user does not already have one.

### 2.2 Add Item To Cart

- Method: `POST`
- Path: `/api/ecom/cart/items`
- Request type: `application/json`
- Path params: none
- Query params: none
- Body: `AddToCartRequest`
- Success response: `200 OK` with updated `CartResponse`
- Validation and rules:
  - Product must exist.
  - Product must be active.
  - If `variantId` is supplied, that variant must exist, belong to the product, and be active.
  - Requested quantity must not exceed available stock.
  - If the same product and variant already exist in the cart, quantity is increased instead of inserting a duplicate item.
- Error cases:
  - `400` for inactive product, inactive variant, wrong variant/product pair, or stock overflow
  - `404` for missing product or variant

Example body:

```json
{
  "productId": 100,
  "variantId": 200,
  "quantity": 2
}
```

### 2.3 Update Cart Item Quantity

- Method: `PUT`
- Path: `/api/ecom/cart/items/{itemId}`
- Request type: `application/json`
- Path params:
  - `itemId`: `Long`, required
- Query params: none
- Body: `UpdateCartItemRequest`
- Success response: `200 OK` with updated `CartResponse`
- Validation and rules:
  - Cart item must belong to the current user's cart.
  - New quantity must not exceed available stock.
- Error cases:
  - `400` if cart item belongs to another user or quantity exceeds stock
  - `404` if cart item does not exist

### 2.4 Remove Cart Item

- Method: `DELETE`
- Path: `/api/ecom/cart/items/{itemId}`
- Request type: `application/json`
- Path params:
  - `itemId`: `Long`, required
- Query params: none
- Body: none
- Success response: `200 OK` with updated `CartResponse`
- Validation and rules:
  - Cart item must belong to the current user's cart.
- Error cases:
  - `400` if cart item belongs to another user
  - `404` if cart item does not exist

### 2.5 Clear Cart

- Method: `DELETE`
- Path: `/api/ecom/cart`
- Request type: `application/json`
- Path params: none
- Query params: none
- Body: none
- Success response: `204 No Content`

---

## 3. UserAddressController

Base path: `/api/ecom/addresses`

Why included:

- This is a user-facing e-commerce API required to support order placement because `PlaceOrderRequest` needs an `addressId`.

Auth:

- Auth required in non-local environments.

### 3.1 Get My Addresses

- Method: `GET`
- Path: `/api/ecom/addresses`
- Request type: `application/json`
- Path params: none
- Query params: none
- Body: none
- Success response: `200 OK` with `List<AddressResponse>`
- Behavior:
  - Addresses are returned ordered by default flag first, then most recent.

### 3.2 Get Address By ID

- Method: `GET`
- Path: `/api/ecom/addresses/{id}`
- Request type: `application/json`
- Path params:
  - `id`: `Long`, required
- Query params: none
- Body: none
- Success response: `200 OK` with `AddressResponse`
- Error cases:
  - `404` if address does not exist or does not belong to current user

### 3.3 Create Address

- Method: `POST`
- Path: `/api/ecom/addresses`
- Request type: `application/json`
- Path params: none
- Query params: none
- Body: `AddressRequest`
- Success response: `201 Created` with `AddressResponse`
- Validation and rules:
  - Maximum `10` addresses per user.
  - The first address automatically becomes default.
  - If `isDefault = true`, any existing default address is cleared.
  - If `country` is omitted, it defaults to `India`.
- Error cases:
  - `400` for validation failures or if address limit is exceeded

### 3.4 Update Address

- Method: `PUT`
- Path: `/api/ecom/addresses/{id}`
- Request type: `application/json`
- Path params:
  - `id`: `Long`, required
- Query params: none
- Body: `AddressRequest`
- Success response: `200 OK` with `AddressResponse`
- Validation and rules:
  - If `isDefault = true`, current default is cleared and this address becomes default.
  - Only user-owned addresses can be updated.
- Error cases:
  - `404` if address does not exist or does not belong to current user

### 3.5 Delete Address

- Method: `DELETE`
- Path: `/api/ecom/addresses/{id}`
- Request type: `application/json`
- Path params:
  - `id`: `Long`, required
- Query params: none
- Body: none
- Success response: `204 No Content`
- Validation and rules:
  - Only user-owned addresses can be deleted.
  - If the deleted address was default, the first remaining address becomes default automatically.
- Error cases:
  - `404` if address does not exist or does not belong to current user

---

## 4. UserOrderController

Base path: `/api/ecom/orders`

Auth:

- Auth required in non-local environments.

### 4.1 Place Order

- Method: `POST`
- Path: `/api/ecom/orders`
- Request type: `application/json`
- Path params: none
- Query params: none
- Body: `PlaceOrderRequest`
- Success response: `201 Created` with full `OrderResponse`
- Validation and rules:
  - `addressId` must belong to the current user.
  - Cart must not be empty.
  - Every cart item is validated again at order time.
  - Product must still be active.
  - Requested quantity must still be available.
  - Tax is recalculated from each product's `taxPercent`.
  - Shipping charge is `0` when subtotal is at least `499`; otherwise shipping is `49`.
  - Order is created in `PENDING` status.
  - Stock is deducted immediately on order placement.
  - Cart is cleared after successful order placement.
- Error cases:
  - `400` if cart is empty, product is no longer available, or stock is insufficient
  - `404` if address does not belong to current user

Example body:

```json
{
  "addressId": 1,
  "notes": "Leave at reception"
}
```

### 4.2 Get My Orders

- Method: `GET`
- Path: `/api/ecom/orders`
- Request type: `application/json`
- Path params: none
- Query params:
  - `page`: optional
  - `size`: optional
  - `sort`: optional
- Body: none
- Success response: `200 OK` with `Page<OrderResponse>`
- Behavior:
  - Returns current user's orders ordered by newest first.
  - The paged list uses the lighter mapped response and may not contain all nested details populated on the single-order endpoint.

### 4.3 Get Order By ID

- Method: `GET`
- Path: `/api/ecom/orders/{id}`
- Request type: `application/json`
- Path params:
  - `id`: `Long`, required
- Query params: none
- Body: none
- Success response: `200 OK` with full `OrderResponse`
- Error cases:
  - `404` if order does not exist or does not belong to current user

### 4.4 Cancel Order

- Method: `POST`
- Path: `/api/ecom/orders/{id}/cancel`
- Request type: `application/json`
- Path params:
  - `id`: `Long`, required
- Query params: none
- Body: optional `CancelOrderRequest`
- Success response: `200 OK` with full `OrderResponse`
- Validation and rules:
  - Order must belong to the current user.
  - Only `PENDING` and `CONFIRMED` orders can be cancelled.
  - Status becomes `CANCELLED`.
  - `cancelledAt` is set.
  - `cancelReason` uses body `reason` if provided; otherwise defaults to `Cancelled by user`.
  - Stock is restored when the order is cancelled.
- Error cases:
  - `400` for invalid status transition
  - `404` if order does not exist or does not belong to current user

Example body:

```json
{
  "reason": "Ordered by mistake"
}
```

---

## 5. PaymentController

Base path: `/api/ecom/payments`

Auth:

- Auth required in non-local environments.

Important implementation note:

- The security layer requires authentication, but the current `RazorpayService` implementation only checks the order by `orderId` and order status. It does not verify that the authenticated user owns that order.

### 5.1 Create Razorpay Order

- Method: `POST`
- Path: `/api/ecom/payments/create-order/{orderId}`
- Request type: `application/json`
- Path params:
  - `orderId`: `Long`, required
- Query params: none
- Body: none
- Success response: `200 OK` with `PaymentResponse`
- Validation and rules:
  - Target order must exist.
  - Order status must be `PENDING`.
  - If a `CREATED` payment record already exists for the order, that existing payment is returned.
  - Razorpay order amount is sent in paise.
  - Payment record is stored with status `CREATED`.
- Error cases:
  - `400` if order is not in `PENDING`
  - `404` if order does not exist
  - `5xx` if Razorpay order creation fails

### 5.2 Verify Payment

- Method: `POST`
- Path: `/api/ecom/payments/verify`
- Request type: `application/json`
- Path params: none
- Query params: none
- Body: `PaymentVerifyRequest`
- Success response: `200 OK` with `PaymentResponse`
- Validation and rules:
  - Payment record is resolved by `razorpayOrderId`.
  - Signature is recalculated using `razorpayOrderId + "|" + razorpayPaymentId` and server secret.
  - On success:
    - payment status becomes `CAPTURED`
    - `razorpayPaymentId` and signature are stored
    - related order status becomes `CONFIRMED`
  - On signature failure:
    - payment status becomes `FAILED`
    - `400 Bad Request` is returned
- Error cases:
  - `400` for invalid signature or validation issues
  - `404` if payment record is not found for the Razorpay order id

Example body:

```json
{
  "razorpayOrderId": "order_abc",
  "razorpayPaymentId": "pay_xyz",
  "razorpaySignature": "signature_string"
}
```

---

## 6. WebhookController

Base path: `/api/webhooks`

Auth:

- Public in non-local environments.
- Security is intended to come from signature verification or webhook secret validation.

### 6.1 Razorpay Webhook

- Method: `POST`
- Path: `/api/webhooks/razorpay`
- Request type: raw body, effectively `application/json` payload treated as `String`
- Path params: none
- Query params: none
- Headers:
  - `X-Razorpay-Signature`: optional in method signature, but required if webhook secret verification is enabled
- Body:
  - raw Razorpay webhook payload as string
- Success response: `200 OK`, empty body
- Validation and rules:
  - If `webhookSecret` is configured, the signature is verified against the full raw payload.
  - Invalid signature results in `400`.
  - Current implementation logs the payload but does not yet process specific event types such as `payment.captured` or `refund.created`.

### 6.2 Shiprocket Webhook

- Method: `POST`
- Path: `/api/webhooks/shiprocket`
- Request type: `application/json`
- Path params: none
- Query params: none
- Body:

```json
{
  "awb": "AWB123",
  "current_status": "IN TRANSIT",
  "courier_name": "Courier Name"
}
```

- Success response: `200 OK`, empty body
- Validation and rules:
  - If `awb` is missing or blank, webhook is ignored and still returns `200`.
  - Matching shipment is looked up by AWB code.
  - Shiprocket statuses are mapped into internal shipment statuses.
  - Related order status is updated as follows:
    - `PICKED_UP` or `IN_TRANSIT` -> order `SHIPPED`
    - `OUT_FOR_DELIVERY` -> order `OUT_FOR_DELIVERY`
    - `DELIVERED` -> order `DELIVERED`
  - `courier_name` updates shipment courier name when provided.

---

## 7. UserChannelController

Base path: `/api/user/channel`

Auth:

- Auth required in non-local environments for all routes under this controller, including the `/public/...` routes.

Important implementation notes:

- This controller has endpoint-specific local exception handling and does not consistently use the shared `ErrorResponse` format.
- `GET /api/user/channel` auto-creates a channel if none exists.
- `POST /api/user/channel` returns an existing channel instead of erroring if one already exists for the user.
- `PUT /api/user/channel` requires a channel to already exist.

### 7.1 Get Or Create Current User Channel

- Method: `GET`
- Path: `/api/user/channel`
- Request type: `application/json`
- Path params: none
- Query params: none
- Body: none
- Success response: `200 OK` with `ChannelResponse`
- Behavior:
  - If user has no channel, one is auto-created.
  - Auto-generated defaults:
    - `channelName`: `<user name>'s Channel` or `My Channel`
    - `channelHandle`: generated from channel name and uniquified if needed
- Error response:
  - `500` with `null` body on unhandled controller-level failure

### 7.2 Create Channel

- Method: `POST`
- Path: `/api/user/channel`
- Request type: `application/json`
- Path params: none
- Query params: none
- Body: `ChannelRequest`
- Success response: `200 OK` with `ChannelResponse`
- Behavior:
  - If a channel already exists for the user, that existing channel is returned.
  - `channelName` defaults to `<user name>'s Channel` or `My Channel` if omitted.
  - `channelHandle` is sanitized to lowercase and punctuation-normalized.
  - If the supplied handle already exists, a random suffix is appended.
- Error responses:
  - `400` with `{ "error": "..." }` for `IllegalArgumentException`
  - `500` with `{ "error": "Failed to create channel" }` for generic failures

Example body:

```json
{
  "channelName": "Devotional Music",
  "channelHandle": "devotional-music",
  "description": "Tamil devotional uploads"
}
```

### 7.3 Update Channel

- Method: `PUT`
- Path: `/api/user/channel`
- Request type: `application/json`
- Path params: none
- Query params: none
- Body: `ChannelRequest`
- Success response: `200 OK` with `ChannelResponse`
- Validation and rules:
  - Channel must already exist for the current user.
  - `channelHandle` is sanitized.
  - If a new sanitized handle is already in use by another channel, update fails.
- Error responses:
  - `400` with `{ "error": "Channel handle already taken: ..." }`
  - `500` with `{ "error": "Failed to update channel" }`
  - `404` can still surface through the global handler if no channel exists and the service throws `ResourceNotFoundException`

Example body:

```json
{
  "channelName": "Updated Channel",
  "channelHandle": "updated-channel",
  "description": "Updated description"
}
```

### 7.4 Upload Channel Image

- Method: `POST`
- Path: `/api/user/channel/image`
- Request type: `multipart/form-data`
- Path params: none
- Query params: none
- Form-data fields:
  - `file`: `MultipartFile`, required
- Success response: `200 OK` with updated `ChannelResponse`
- Behavior:
  - Channel must already exist for the user.
  - Image is uploaded to S3 under the configured channel images prefix.
  - Response `imageUrl` is built from CloudFront base URL and stored image key.
- Error responses:
  - `500` with `{ "error": "Failed to upload image" }`
  - `404` may surface through global handler if channel does not exist

### 7.5 Upload Media To Channel

- Method: `POST`
- Path: `/api/user/channel/media/upload`
- Request type: `multipart/form-data`
- Path params: none
- Query params: none
- Form-data fields:
  - `title`: `String`, required
  - `description`: `String`, optional
  - `mediaType`: `MediaType`, required, values `AUDIO` or `VIDEO`
  - `file`: `MultipartFile`, required
  - `thumbnail`: `MultipartFile`, optional
- Success response: `200 OK` with `UserMediaResponse`
- Behavior:
  - Channel must already exist for the user.
  - Source file is uploaded to S3 under audio or video prefix.
  - Thumbnail is uploaded if provided.
  - Media is created with:
    - `status = UPLOADING`
    - `approvalStatus = PENDING`
  - Newly uploaded media is not public until admin approval and until it becomes `READY`.
- Error responses:
  - `500` with `{ "error": "Failed to upload media: ..." }`

### 7.6 Get My Channel Media

- Method: `GET`
- Path: `/api/user/channel/media`
- Request type: `application/json`
- Path params: none
- Query params:
  - `status`: optional approval filter, expected values `PENDING`, `APPROVED`, `REJECTED`
  - `page`: optional
  - `size`: optional
  - `sort`: optional
- Body: none
- Success response: `200 OK` with `Page<UserMediaResponse>`
- Behavior:
  - Returns all media for the current user's channel.
  - If `status` is supplied, it is mapped to `ApprovalStatus.valueOf(status.toUpperCase())`.
- Error responses:
  - `500` with `null` body on controller-level failure
  - invalid `status` value can bubble into generic error handling depending on failure path

### 7.7 Delete My Media

- Method: `DELETE`
- Path: `/api/user/channel/media/{mediaId}`
- Request type: `application/json`
- Path params:
  - `mediaId`: `UUID`, required
- Query params: none
- Body: none
- Success response: `204 No Content`
- Validation and rules:
  - Media must belong to the current user.
  - Approved media cannot be deleted by the user.
  - Pending and rejected media can be deleted.
- Error responses:
  - `400` with `{ "error": "..." }` for ownership and approval-status violations
  - `500` with `{ "error": "Failed to delete media" }`
  - `404` may surface through global handler if media does not exist

### 7.8 Get Public Channel View

- Method: `GET`
- Path: `/api/user/channel/public/{channelId}`
- Request type: `application/json`
- Path params:
  - `channelId`: `UUID`, required
- Query params: none
- Body: none
- Success response: `200 OK` with `ChannelResponse`
- Behavior:
  - Returns channel details plus `approvedMedia` count.
  - Despite the word `public` in the route, authentication is still required in non-local environments.
- Error responses:
  - `404 Not Found` with empty body on failure in this controller

### 7.9 Get Public Channel Media

- Method: `GET`
- Path: `/api/user/channel/public/{channelId}/media`
- Request type: `application/json`
- Path params:
  - `channelId`: `UUID`, required
- Query params:
  - `page`: optional
  - `size`: optional
  - `sort`: optional
- Body: none
- Success response: `200 OK` with `Page<UserMediaResponse>`
- Behavior:
  - Returns only media where:
    - `approvalStatus = APPROVED`
    - `status = READY`
  - Despite the word `public` in the route, authentication is still required in non-local environments.
- Error responses:
  - `500` with `null` body on controller-level failure

## Summary of Additional User-Facing APIs Included

These were added because they are directly related to channel creation/editing or the e-commerce user flow:

- `UserAddressController`
  - Required by order placement because `PlaceOrderRequest` depends on `addressId`.
- Additional `UserChannelController` routes beyond create and update:
  - image upload
  - media upload
  - media listing and deletion
  - public channel and public media views

## Notable Implementation Findings

These are not recommendations, only current-behavior notes from the code:

- Catalog browsing is public in non-local environments; cart, address, order, payment, and channel APIs are authenticated.
- Local profile bypasses normal auth and permits all requests.
- `PaymentController` requires auth at the security layer, but current payment creation logic does not verify order ownership.
- Channel endpoints use mixed error formats because several methods catch exceptions directly in the controller.
- `POST /api/user/channel` is idempotent in practice for users who already have a channel because it returns the existing channel.
- `GET /api/user/channel` auto-creates a channel if none exists.
- User-uploaded media is not publicly browseable until both admin approval and media readiness are satisfied.
- Razorpay webhook currently verifies the signature and logs payload but does not yet process specific webhook event business logic.
