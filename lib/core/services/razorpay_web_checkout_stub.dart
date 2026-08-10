class RazorpayWebCheckoutResult {
  const RazorpayWebCheckoutResult._({
    required this.ok,
    this.orderId,
    this.paymentId,
    this.signature,
    this.message,
    this.cancelled = false,
  });

  final bool ok;
  final String? orderId;
  final String? paymentId;
  final String? signature;
  final String? message;

  /// The user closed the checkout themselves rather than hitting an error.
  final bool cancelled;

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

  factory RazorpayWebCheckoutResult.failure(
    String message, {
    bool cancelled = false,
  }) {
    return RazorpayWebCheckoutResult._(
      ok: false,
      message: message,
      cancelled: cancelled,
    );
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
