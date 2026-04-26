// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:js' as js;

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
  final hasBridge = js.context.hasProperty('openRazorpayCheckout');
  if (!hasBridge) {
    return RazorpayWebCheckoutResult.failure(
      'Web checkout bridge is not loaded. Ensure index.html includes openRazorpayCheckout().',
    );
  }

  final completer = Completer<RazorpayWebCheckoutResult>();

  void resolve(RazorpayWebCheckoutResult result) {
    if (!completer.isCompleted) {
      completer.complete(result);
    }
  }

  void onSuccess(dynamic response) {
    final paymentId = _read(response, 'razorpay_payment_id');
    final callbackOrderId = _read(response, 'razorpay_order_id');
    final signature = _read(response, 'razorpay_signature');

    resolve(
      RazorpayWebCheckoutResult.success(
        orderId: callbackOrderId.isNotEmpty ? callbackOrderId : orderId,
        paymentId: paymentId,
        signature: signature,
      ),
    );
  }

  void onError(dynamic message) {
    resolve(
      RazorpayWebCheckoutResult.failure(message?.toString() ?? 'Payment failed'),
    );
  }

  void onDismiss() {
    resolve(RazorpayWebCheckoutResult.failure('Payment cancelled by user.'));
  }

  final options = js.JsObject.jsify({
    'key': key,
    'amount': amount,
    'currency': currency,
    'name': name,
    'description': description,
    'orderId': orderId,
    'prefillName': prefillName,
    'prefillEmail': prefillEmail,
    'prefillContact': prefillContact,
    'onSuccess': onSuccess,
    'onError': onError,
    'onDismiss': onDismiss,
  });

  try {
    js.context.callMethod('openRazorpayCheckout', [options]);
  } catch (e) {
    return RazorpayWebCheckoutResult.failure(e.toString());
  }

  return completer.future.timeout(
    const Duration(minutes: 5),
    onTimeout: () => RazorpayWebCheckoutResult.failure('Payment timed out.'),
  );
}

String _read(dynamic object, String key) {
  if (object == null) return '';
  if (object is js.JsObject) {
    if (!object.hasProperty(key)) return '';
    final value = object[key];
    return value?.toString() ?? '';
  }
  if (object is Map && object.containsKey(key)) {
    return object[key]?.toString() ?? '';
  }
  return '';
}
