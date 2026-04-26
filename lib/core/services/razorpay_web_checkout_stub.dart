class RazorpayWebCheckoutResult {
  const RazorpayWebCheckoutResult._({
    required this.ok,
    this.orderId,
    this.paymentId,
    this.signature,
    this.message,
  });

  final bool ok;
  final String? orderId;
  final String? paymentId;
  final String? signature;
  final String? message;

  factory RazorpayWebCheckoutResult.success({
    required String orderId,
    required String paymentId,
    required String signature,
  }) {
    return RazorpayWebCheckoutResult._(
      ok: true,
      orderId: orderId,
      paymentId: paymentId,
      signature: signature,
    );
  }

  factory RazorpayWebCheckoutResult.failure(String message) {
    return RazorpayWebCheckoutResult._(ok: false, message: message);
  }
}

Future<RazorpayWebCheckoutResult> openRazorpayWebCheckout({
  required String key,
  required int amount,
  required String currency,
  required String name,
  required String description,
  required String orderId,
  String prefillName = '',
  String prefillEmail = '',
  String prefillContact = '',
}) async {
  return RazorpayWebCheckoutResult.failure(
    'Web checkout is unavailable on this platform.',
  );
}
