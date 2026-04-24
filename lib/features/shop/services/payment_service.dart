import '../../../core/services/api_service.dart';
import '../models/payment.dart';

/// Payment Service
///
/// Wraps all /ecom/payments endpoints (auth required).
class PaymentService {
  final ApiService _api;
  PaymentService(this._api);

  /// Create a Razorpay order for an existing platform order
  Future<Map<String, dynamic>?> createPaymentOrder(int orderId) async {
    final data = await _api.post(
      '/ecom/payments/create-order/$orderId',
      body: {},
    );
    return data is Map ? Map<String, dynamic>.from(data as Map) : null;
  }

  /// Verify a Razorpay payment after checkout
  Future<PaymentResponse?> verifyPayment(PaymentVerifyRequest request) async {
    final data = await _api.post(
      '/ecom/payments/verify',
      body: request.toJson(),
    );
    final json = data is Map ? data : (data['data'] as Map<String, dynamic>);
    return PaymentResponse.fromJson(json as Map<String, dynamic>);
  }
}
