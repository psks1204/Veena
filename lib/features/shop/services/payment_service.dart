import '../../../core/services/api_service.dart';
import '../models/payment.dart';

/// Payment Service
///
/// Wraps all /ecom/payments endpoints (auth required).
class PaymentService {
  final ApiService _api;
  PaymentService(this._api);

  /// Create a Razorpay order for an existing platform order
  Future<PaymentResponse?> createPaymentOrder(int orderId) async {
    final data = await _api.post(
      '/ecom/payments/create-order/$orderId',
      body: {},
    );

    final map = _extractMap(data);
    return PaymentResponse.fromJson(map);
  }

  /// Verify a Razorpay payment after checkout
  Future<PaymentResponse?> verifyPayment(PaymentVerifyRequest request) async {
    final data = await _api.post(
      '/ecom/payments/verify',
      body: request.toJson(),
    );

    final map = _extractMap(data);
    return PaymentResponse.fromJson(map);
  }

  Map<String, dynamic> _extractMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['data'] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(data['data'] as Map<String, dynamic>);
      }
      return data;
    }
    if (data is Map && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    throw StateError('Unexpected payment payload type: ${data.runtimeType}');
  }
}
