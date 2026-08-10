import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:veena/core/models/subscription.dart';
import 'package:veena/core/providers/subscription_provider.dart';
import 'package:veena/core/services/api_service.dart';
import 'package:veena/core/services/subscription_service.dart';

/// The exact rejection the backend returns for an order the user never paid.
ApiException get noPaymentFound => ApiException(
  'No payment found for this order on Razorpay. Please retry payment.',
  400,
);

Map<String, dynamic> _subscriptionJson({
  required int id,
  required String status,
  String? paymentId,
}) {
  return {
    'id': id,
    'status': status,
    'autoRenew': true,
    'plan': {
      'id': 1,
      'name': 'No Ads Plan',
      'planType': 'MONTHLY',
      'durationMonths': 1,
      'price': 9,
      'currency': 'INR',
    },
    'razorpayOrderId': 'order_TEST123',
    'razorpayPaymentId': paymentId,
    'paymentAmount': 9,
    'paymentCurrency': 'INR',
    'createdAt': DateTime.now().toIso8601String(),
    'updatedAt': DateTime.now().toIso8601String(),
  };
}

class FakeSubscriptionService extends SubscriptionService {
  FakeSubscriptionService() : super(ApiService());

  /// What `/subscriptions/{id}/re-verify` should do on the next call.
  Object? reverifyError;
  UserSubscription? reverifyResult;

  bool subscribedFlag = false;
  List<UserSubscription> history = const [];

  int reverifyCalls = 0;
  int subscribeCalls = 0;

  @override
  Future<List<SubscriptionPlan>> getPlans() async => [
    SubscriptionPlan.fromJson({
      'id': 1,
      'name': 'No Ads Plan',
      'planType': 'MONTHLY',
      'durationMonths': 1,
      'price': 9,
      'currency': 'INR',
      'description': 'Ad free',
      'isActive': true,
    }),
  ];

  @override
  Future<UserSubscription> subscribe(SubscribeRequest request) async {
    subscribeCalls++;
    // A freshly created order: PENDING, and crucially no payment id yet.
    return UserSubscription.fromJson(
      _subscriptionJson(id: 42, status: 'PENDING'),
    );
  }

  @override
  Future<UserSubscription> reverifyPayment(int id) async {
    reverifyCalls++;
    final error = reverifyError;
    if (error != null) throw error;
    return reverifyResult ??
        UserSubscription.fromJson(_subscriptionJson(id: id, status: 'PENDING'));
  }

  @override
  Future<SubscriptionStatus> getStatus() async {
    return SubscriptionStatus.fromJson({
      'isSubscribed': subscribedFlag,
      'showAds': !subscribedFlag,
      'activeSubscription': subscribedFlag
          ? _subscriptionJson(id: 42, status: 'ACTIVE', paymentId: 'pay_X')
          : null,
    });
  }

  @override
  Future<List<UserSubscription>> getHistory() async => history;

  @override
  Future<UserSubscription> verifyPayment(
    SubscriptionPaymentVerifyRequest request,
  ) async {
    throw ApiException('Signature verification failed', 400);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSubscriptionService service;
  late SubscriptionProvider provider;

  Future<void> buildProvider() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    service = FakeSubscriptionService();
    provider = SubscriptionProvider(prefs, service);
    await provider.initialize();
  }

  setUp(buildProvider);

  test('creating an order does not put the user in "verification pending"', () async {
    await provider.createSubscription(planId: 1);

    // The regression that caused the lockout: an order with no payment behind
    // it must not look like a payment awaiting verification.
    expect(provider.hasPendingVerification, isFalse);
    expect(provider.hasUnresolvedPayment, isFalse);
    expect(provider.canStartNewPayment, isTrue);
    expect(
      provider.pendingVerification?.stage,
      PendingPaymentStage.orderCreated,
    );
  });

  test('cancelling checkout clears the order and invites a retry', () async {
    await provider.createSubscription(planId: 1);
    service.reverifyError = noPaymentFound;

    final resolution = await provider.resolveAbandonedCheckout(
      subscriptionId: 42,
      cancelledByUser: true,
    );

    expect(resolution.shouldRestartPayment, isTrue);
    expect(resolution.isActivated, isFalse);
    expect(resolution.message, contains('cancelled'));
    expect(resolution.message, contains('not been charged'));

    // Nothing left blocking a second attempt.
    expect(provider.pendingVerification, isNull);
    expect(provider.hasPendingVerification, isFalse);
    expect(provider.hasUnresolvedPayment, isFalse);
    expect(provider.canStartNewPayment, isTrue);
    expect(provider.error, isNull);
  });

  test('user can immediately subscribe again after cancelling', () async {
    await provider.createSubscription(planId: 1);
    service.reverifyError = noPaymentFound;
    await provider.resolveAbandonedCheckout(subscriptionId: 42);

    // Second attempt goes through order creation cleanly.
    service.reverifyError = null;
    final second = await provider.createSubscription(planId: 1);

    expect(second.id, 42);
    expect(service.subscribeCalls, 2);
    expect(provider.hasPendingVerification, isFalse);
  });

  test('the reported 400 retires the order instead of looping forever', () async {
    await provider.createSubscription(planId: 1);
    service.reverifyError = noPaymentFound;

    final resolution = await provider.reverifyPendingPayment();

    expect(resolution.shouldRestartPayment, isTrue);
    expect(resolution.message, contains('start the payment again'));
    expect(provider.pendingVerification, isNull);
    expect(service.reverifyCalls, 1, reason: 'must not retry a dead order');
  });

  test('a payment that did land still activates on cancel reconciliation', () async {
    await provider.createSubscription(planId: 1);
    // Razorpay reported failure, but the money actually went through.
    service.subscribedFlag = true;
    service.reverifyResult = UserSubscription.fromJson(
      _subscriptionJson(id: 42, status: 'ACTIVE', paymentId: 'pay_REAL'),
    );

    final resolution = await provider.resolveAbandonedCheckout(
      subscriptionId: 42,
      cancelledByUser: true,
    );

    expect(resolution.isActivated, isTrue);
    expect(provider.isNoAdsSubscribed, isTrue);
    expect(provider.pendingVerification, isNull);
  });

  test('a captured payment survives a network failure', () async {
    // Razorpay handed us a payment id, so money is in play.
    service.reverifyError = ApiException('Connection refused', 503);
    await provider.completePendingPayment(
      const SubscriptionPaymentVerifyRequest(
        subscriptionId: 42,
        razorpayOrderId: 'order_TEST123',
        razorpayPaymentId: 'pay_REAL',
        razorpaySignature: 'sig',
      ),
    );

    // The record must NOT be thrown away — that would lose a real payment.
    expect(provider.pendingVerification, isNotNull);
    expect(
      provider.pendingVerification?.stage,
      PendingPaymentStage.paymentCaptured,
    );
    expect(provider.hasPendingVerification, isTrue);

    // ...but the user is still free to start a new payment.
    expect(provider.canStartNewPayment, isTrue);
  });

  test('a stale unpaid order is dropped on next launch', () async {
    SharedPreferences.setMockInitialValues({
      'subscription_pending_verification_v1':
          '{"subscriptionId":42,"stage":"orderCreated",'
              '"createdAt":"2020-01-01T00:00:00.000",'
              '"updatedAt":"2020-01-01T00:00:00.000"}',
    });
    final prefs = await SharedPreferences.getInstance();
    final fresh = SubscriptionProvider(prefs, FakeSubscriptionService());

    expect(fresh.pendingVerification, isNull);
    expect(fresh.hasPendingVerification, isFalse);
  });
}
