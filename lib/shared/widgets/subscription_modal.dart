import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../core/constants/payment_config.dart';
import '../../core/models/subscription.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/services/razorpay_web_checkout.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

Future<void> showSubscriptionModal(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _SubscriptionModal(),
  );
}

class _SubscriptionModal extends StatefulWidget {
  const _SubscriptionModal();

  @override
  State<_SubscriptionModal> createState() => _SubscriptionModalState();
}

class _SubscriptionModalState extends State<_SubscriptionModal> {
  Razorpay? _razorpay;
  Completer<_CheckoutResult>? _checkoutCompleter;
  int? _selectedPlanId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SubscriptionProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) {
    _checkoutCompleter?.complete(
      _CheckoutResult.success(
        orderId: response.orderId ?? '',
        paymentId: response.paymentId ?? '',
        signature: response.signature ?? '',
      ),
    );
    _checkoutCompleter = null;
  }

  void _onPaymentError(PaymentFailureResponse response) {
    _checkoutCompleter?.complete(
      _CheckoutResult.failure(response.message ?? 'Payment failed'),
    );
    _checkoutCompleter = null;
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    _checkoutCompleter?.complete(
      _CheckoutResult.failure(
        'External wallet selected (${response.walletName ?? 'unknown'})',
      ),
    );
    _checkoutCompleter = null;
  }

  Future<_CheckoutResult> _openCheckout(
    UserSubscription pending,
    SubscriptionPlan plan,
  ) async {
    if (!PaymentConfig.hasRazorpayKey) {
      return _CheckoutResult.failure(
        'Razorpay key is not configured. Add --dart-define for current APP_ENV.',
      );
    }
    if (pending.razorpayOrderId == null || pending.razorpayOrderId!.isEmpty) {
      return _CheckoutResult.failure('Missing Razorpay order ID from backend.');
    }

    final amountInMajor = pending.paymentAmount ?? plan.price;
    final amountInPaise = (amountInMajor * 100).round();

    if (kIsWeb) {
      final result = await openRazorpayWebCheckout(
        key: PaymentConfig.razorpayKey,
        amount: amountInPaise,
        currency: plan.currency,
        name: 'Veena',
        description: plan.name,
        orderId: pending.razorpayOrderId!,
        prefillName: pending.userName ?? '',
        prefillEmail: pending.userEmail ?? '',
      );

      if (!result.ok) {
        return _CheckoutResult.failure(result.message ?? 'Payment failed');
      }
      return _CheckoutResult.success(
        orderId: result.orderId ?? pending.razorpayOrderId!,
        paymentId: result.paymentId ?? '',
        signature: result.signature ?? '',
      );
    }

    if (_razorpay == null) {
      return _CheckoutResult.failure('Razorpay is not initialized.');
    }

    _checkoutCompleter = Completer<_CheckoutResult>();

    try {
      _razorpay!.open({
        'key': PaymentConfig.razorpayKey,
        'amount': amountInPaise,
        'currency': plan.currency,
        'name': 'Veena',
        'description': plan.name,
        'order_id': pending.razorpayOrderId,
        'prefill': {
          'name': pending.userName ?? '',
          'email': pending.userEmail ?? '',
        },
        'theme': {'color': '#FF6B00'},
      });

      return _checkoutCompleter!.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () => _CheckoutResult.failure('Payment timed out.'),
      );
    } catch (e) {
      _checkoutCompleter = null;
      return _CheckoutResult.failure(e.toString());
    }
  }

  Future<void> _handleSubscribe(SubscriptionProvider subscription) async {
    final selectedId = _selectedPlanId;
    if (selectedId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a plan.')));
      return;
    }

    SubscriptionPlan? plan;
    for (final item in subscription.plans) {
      if (item.id == selectedId) {
        plan = item;
        break;
      }
    }
    if (plan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected plan is unavailable.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final pending = await subscription.createSubscription(planId: selectedId);
      final checkoutResult = await _openCheckout(pending, plan);
      if (!checkoutResult.ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(checkoutResult.message ?? 'Payment cancelled'),
          ),
        );
        return;
      }

      await subscription.verifyPayment(
        SubscriptionPaymentVerifyRequest(
          subscriptionId: pending.id,
          razorpayOrderId: checkoutResult.orderId?.isNotEmpty == true
              ? checkoutResult.orderId!
              : (pending.razorpayOrderId ?? ''),
          razorpayPaymentId: checkoutResult.paymentId ?? '',
          razorpaySignature: checkoutResult.signature ?? '',
        ),
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription activated successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Subscription failed: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subscription = context.watch<SubscriptionProvider>();
    final plans = subscription.plans;

    if (_selectedPlanId == null && plans.isNotEmpty) {
      _selectedPlanId = plans.first.id;
    }

    final buttonBusy = _isSubmitting || subscription.isProcessingPurchase;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Ads Subscription',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Listen without ads across player and home carousel.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 20),
            if (subscription.isLoading && plans.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (plans.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Plans are currently unavailable.'),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () =>
                          subscription.initialize(forceRefresh: true),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: plans.map((plan) {
                  final selected = _selectedPlanId == plan.id;
                  final price = plan.price.toStringAsFixed(
                    plan.price.truncateToDouble() == plan.price ? 0 : 2,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => setState(() => _selectedPlanId = plan.id),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : (isDark ? Colors.white24 : Colors.black12),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              selected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    plan.name,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    plan.description,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$price ${plan.currency}',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),
            _BenefitRow(text: 'No ads in player banner slot'),
            _BenefitRow(text: 'No ads in featured carousel'),
            _BenefitRow(text: 'Instant ad-free experience'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    buttonBusy ||
                        plans.isEmpty ||
                        subscription.isNoAdsSubscribed
                    ? null
                    : () => _handleSubscribe(subscription),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(
                  buttonBusy
                      ? 'Processing...'
                      : (subscription.isNoAdsSubscribed
                            ? 'Subscribed'
                            : 'Subscribe Now'),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

class _CheckoutResult {
  const _CheckoutResult._({
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

  factory _CheckoutResult.success({
    required String orderId,
    required String paymentId,
    required String signature,
  }) {
    return _CheckoutResult._(
      ok: true,
      orderId: orderId,
      paymentId: paymentId,
      signature: signature,
    );
  }

  factory _CheckoutResult.failure(String message) {
    return _CheckoutResult._(ok: false, message: message);
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
