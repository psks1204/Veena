import 'payment.dart';

/// Shop Order Models

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  outForDelivery,
  delivered,
  cancelled,
  returnRequested,
  returned,
  refunded,
}

enum ShipmentStatus {
  pending,
  pickupScheduled,
  pickedUp,
  inTransit,
  outForDelivery,
  delivered,
  rtoInitiated,
  rtoDelivered,
  cancelled,
}

class OrderItem {
  final int id;
  final int productId;
  final int? variantId;
  final String productName;
  final String? variantName;
  final String? sku;
  final int quantity;
  final double unitPrice;
  final double taxPercent;
  final double taxAmount;
  final double totalPrice;

  const OrderItem({
    required this.id,
    required this.productId,
    this.variantId,
    required this.productName,
    this.variantName,
    this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.taxPercent,
    required this.taxAmount,
    required this.totalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int,
      productId: json['productId'] as int,
      variantId: json['variantId'] as int?,
      productName: json['productName'] as String? ?? '',
      variantName: json['variantName'] as String?,
      sku: json['sku'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      taxPercent: (json['taxPercent'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ShipmentInfo {
  final int id;
  final String? shiprocketOrderId;
  final String? shiprocketShipmentId;
  final String? awbCode;
  final String? courierName;
  final ShipmentStatus status;
  final String? trackingUrl;
  final String? estimatedDelivery;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;

  const ShipmentInfo({
    required this.id,
    this.shiprocketOrderId,
    this.shiprocketShipmentId,
    this.awbCode,
    this.courierName,
    required this.status,
    this.trackingUrl,
    this.estimatedDelivery,
    this.shippedAt,
    this.deliveredAt,
  });

  factory ShipmentInfo.fromJson(Map<String, dynamic> json) {
    return ShipmentInfo(
      id: json['id'] as int,
      shiprocketOrderId: json['shiprocketOrderId'] as String?,
      shiprocketShipmentId: json['shiprocketShipmentId'] as String?,
      awbCode: json['awbCode'] as String?,
      courierName: json['courierName'] as String?,
      status: _parseShipStatus(json['status'] as String?),
      trackingUrl: json['trackingUrl'] as String?,
      estimatedDelivery: json['estimatedDelivery'] as String?,
      shippedAt: json['shippedAt'] != null
          ? DateTime.tryParse(json['shippedAt'] as String)
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.tryParse(json['deliveredAt'] as String)
          : null,
    );
  }

  static ShipmentStatus _parseShipStatus(String? value) {
    switch (value?.toUpperCase()) {
      case 'PICKUP_SCHEDULED':
        return ShipmentStatus.pickupScheduled;
      case 'PICKED_UP':
        return ShipmentStatus.pickedUp;
      case 'IN_TRANSIT':
        return ShipmentStatus.inTransit;
      case 'OUT_FOR_DELIVERY':
        return ShipmentStatus.outForDelivery;
      case 'DELIVERED':
        return ShipmentStatus.delivered;
      case 'RTO_INITIATED':
        return ShipmentStatus.rtoInitiated;
      case 'RTO_DELIVERED':
        return ShipmentStatus.rtoDelivered;
      case 'CANCELLED':
        return ShipmentStatus.cancelled;
      default:
        return ShipmentStatus.pending;
    }
  }
}

class OrderResponse {
  final int id;
  final String? orderNumber;
  final OrderStatus status;
  final double subtotal;
  final double taxAmount;
  final double shippingCharge;
  final double discountAmount;
  final double totalAmount;
  final String currency;
  final String? shippingName;
  final String? shippingPhone;
  final String? shippingAddress1;
  final String? shippingAddress2;
  final String? shippingCity;
  final String? shippingState;
  final String? shippingPincode;
  final String? shippingCountry;
  final String? notes;
  final String? cancelReason;
  final List<OrderItem> items;
  final PaymentResponse? payment;
  final ShipmentInfo? shipment;
  final String? userName;
  final String? userEmail;
  final DateTime? cancelledAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const OrderResponse({
    required this.id,
    this.orderNumber,
    required this.status,
    required this.subtotal,
    required this.taxAmount,
    this.shippingCharge = 0.0,
    this.discountAmount = 0.0,
    required this.totalAmount,
    this.currency = 'INR',
    this.shippingName,
    this.shippingPhone,
    this.shippingAddress1,
    this.shippingAddress2,
    this.shippingCity,
    this.shippingState,
    this.shippingPincode,
    this.shippingCountry,
    this.notes,
    this.cancelReason,
    this.items = const [],
    this.payment,
    this.shipment,
    this.userName,
    this.userEmail,
    this.cancelledAt,
    this.createdAt,
    this.updatedAt,
  });

  bool get canCancel =>
      status == OrderStatus.pending || status == OrderStatus.confirmed;

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    return OrderResponse(
      id: json['id'] as int,
      orderNumber: json['orderNumber'] as String?,
      status: _parseStatus(json['status'] as String?),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      shippingCharge: (json['shippingCharge'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'INR',
      shippingName: json['shippingName'] as String?,
      shippingPhone: json['shippingPhone'] as String?,
      shippingAddress1: json['shippingAddress1'] as String?,
      shippingAddress2: json['shippingAddress2'] as String?,
      shippingCity: json['shippingCity'] as String?,
      shippingState: json['shippingState'] as String?,
      shippingPincode: json['shippingPincode'] as String?,
      shippingCountry: json['shippingCountry'] as String?,
      notes: json['notes'] as String?,
      cancelReason: json['cancelReason'] as String?,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      payment: json['payment'] != null
          ? PaymentResponse.fromJson(json['payment'] as Map<String, dynamic>)
          : null,
      shipment: json['shipment'] != null
          ? ShipmentInfo.fromJson(json['shipment'] as Map<String, dynamic>)
          : null,
      userName: json['userName'] as String?,
      userEmail: json['userEmail'] as String?,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.tryParse(json['cancelledAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  static OrderStatus _parseStatus(String? value) {
    switch (value?.toUpperCase()) {
      case 'CONFIRMED':
        return OrderStatus.confirmed;
      case 'PROCESSING':
        return OrderStatus.processing;
      case 'SHIPPED':
        return OrderStatus.shipped;
      case 'OUT_FOR_DELIVERY':
        return OrderStatus.outForDelivery;
      case 'DELIVERED':
        return OrderStatus.delivered;
      case 'CANCELLED':
        return OrderStatus.cancelled;
      case 'RETURN_REQUESTED':
        return OrderStatus.returnRequested;
      case 'RETURNED':
        return OrderStatus.returned;
      case 'REFUNDED':
        return OrderStatus.refunded;
      default:
        return OrderStatus.pending;
    }
  }
}

class PlaceOrderRequest {
  final int addressId;
  final String? notes;

  const PlaceOrderRequest({required this.addressId, this.notes});

  Map<String, dynamic> toJson() => {
    'addressId': addressId,
    if (notes != null && notes!.isNotEmpty) 'notes': notes,
  };
}

class CancelOrderRequest {
  final String? reason;
  const CancelOrderRequest({this.reason});
  Map<String, dynamic> toJson() => {
    if (reason != null && reason!.isNotEmpty) 'reason': reason,
  };
}
