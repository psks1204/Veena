/// Shop Payment Models
library;

enum PaymentStatus {
  created,
  authorized,
  captured,
  failed,
  refundInitiated,
  refunded,
}

class PaymentResponse {
  final int id;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final String? method;
  final DateTime? createdAt;

  const PaymentResponse({
    required this.id,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    required this.amount,
    this.currency = 'INR',
    required this.status,
    this.method,
    this.createdAt,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      id: json['id'] as int,
      razorpayOrderId: json['razorpayOrderId'] as String?,
      razorpayPaymentId: json['razorpayPaymentId'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'INR',
      status: _parseStatus(json['status'] as String?),
      method: json['method'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  static PaymentStatus _parseStatus(String? value) {
    switch (value?.toUpperCase()) {
      case 'AUTHORIZED':
        return PaymentStatus.authorized;
      case 'CAPTURED':
        return PaymentStatus.captured;
      case 'FAILED':
        return PaymentStatus.failed;
      case 'REFUND_INITIATED':
        return PaymentStatus.refundInitiated;
      case 'REFUNDED':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.created;
    }
  }
}

class PaymentVerifyRequest {
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String razorpaySignature;

  const PaymentVerifyRequest({
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.razorpaySignature,
  });

  Map<String, dynamic> toJson() => {
    'razorpayOrderId': razorpayOrderId,
    'razorpayPaymentId': razorpayPaymentId,
    'razorpaySignature': razorpaySignature,
  };
}
