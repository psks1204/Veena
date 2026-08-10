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
      _CheckoutResult.failure(
        response.message ?? 'Payment failed. Please try again.',
      ),
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
    debugPrint('[SubscriptionModal] _openCheckout: key=${PaymentConfig.razorpayKey}, orderId=${pending.razorpayOrderId}, amountPaise=$amountInPaise, isWeb=$kIsWeb');

    if (kIsWeb) {
      final result = await openRazorpayWebCheckout(
        key: PaymentConfig.razorpayKey,
        amount: amountInPaise,
        currency: pending.paymentCurrency ?? plan.currency,
        name: 'Veena',
        description: plan.name,
        orderId: pending.razorpayOrderId!,
        prefillName: pending.userName ?? '',
        prefillEmail: pending.userEmail ?? '',
      );

      debugPrint('[SubscriptionModal] Web checkout result: ok=${result.ok}, msg=${result.message}');
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
      debugPrint('[SubscriptionModal] _razorpay is null!');
      return _CheckoutResult.failure('Razorpay is not initialized.');
    }

    _checkoutCompleter = Completer<_CheckoutResult>();

    try {
      debugPrint('[SubscriptionModal] Opening native Razorpay checkout...');
      _razorpay!.open({
        'key': PaymentConfig.razorpayKey,
        'amount': amountInPaise,
        'currency': pending.paymentCurrency ?? plan.currency,
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
      debugPrint('[SubscriptionModal] Creating subscription for planId: $selectedId...');
      final pending = await subscription.createSubscription(planId: selectedId);
      debugPrint('[SubscriptionModal] Created pending subscription: id=${pending.id}, orderId=${pending.razorpayOrderId}');
      final checkoutResult = await _openCheckout(pending, plan);
      debugPrint('[SubscriptionModal] Checkout result: ok=${checkoutResult.ok}, msg=${checkoutResult.message}');
      if (!checkoutResult.ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(checkoutResult.message ?? 'Payment cancelled'),
          ),
        );
        return;
      }

      final resolution = await subscription.completePendingPayment(
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
      if (resolution.isActivated) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(resolution.message)));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(resolution.message)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Subscription failed: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleReverifyPending(SubscriptionProvider subscription) async {
    final resolution = await subscription.reverifyPendingPayment(
      userInitiated: true,
    );
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(resolution.message)));

    if (resolution.isActivated) {
      Navigator.pop(context);
    }
  }

  Future<void> _handleCancelSubscription(
    SubscriptionProvider subscription,
  ) async {
    final reasonController = TextEditingController();
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Cancel Subscription?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Auto-renew will be disabled after cancellation. You can optionally add a reason.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Reason (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Keep Subscription'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Cancel Subscription'),
            ),
          ],
        );
      },
    );

    final reason = reasonController.text.trim();
    reasonController.dispose();

    if (shouldCancel != true) return;

    final ok = await subscription.cancelCurrentSubscription(
      reason: reason.isEmpty ? null : reason,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Subscription cancellation requested successfully.'
              : (subscription.error ?? 'Failed to cancel subscription.'),
        ),
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'N/A';
    return value.toLocal().toIso8601String().split('T').first;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subscription = context.watch<SubscriptionProvider>();
    final plans = subscription.plans;
    final activeSubscription = subscription.activeSubscription;
    final pendingVerification = subscription.pendingVerification;
    final hasPendingVerification =
        pendingVerification != null && !subscription.isNoAdsSubscribed;

    if (_selectedPlanId == null && plans.isNotEmpty) {
      _selectedPlanId = plans.first.id;
    }

    final buttonBusy = _isSubmitting || subscription.isProcessingPurchase;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
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
                if (hasPendingVerification) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment verification pending',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Subscription #${pendingVerification.subscriptionId} is still pending confirmation. Tap Re-verify to sync payment status.',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed:
                              buttonBusy ||
                                  subscription.isRecoveringPendingVerification
                              ? null
                              : () => _handleReverifyPending(subscription),
                          icon: const Icon(Icons.sync_rounded),
                          label: Text(
                            subscription.isRecoveringPendingVerification
                                ? 'Verifying...'
                                : 'Re-verify Payment',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (subscription.isNoAdsSubscribed &&
                    activeSubscription != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active: ${activeSubscription.plan.name}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ends on ${_formatDate(activeSubscription.endDate)}',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: buttonBusy
                              ? null
                              : () => _handleCancelSubscription(subscription),
                          icon: const Icon(Icons.cancel_rounded),
                          label: const Text('Cancel Subscription'),
                        ),
                      ],
                    ),
                  ),
                ],
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
                          onTap: () =>
                              setState(() => _selectedPlanId = plan.id),
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
                                    : (isDark
                                          ? Colors.white24
                                          : Colors.black12),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        plan.name,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        plan.description,
                                        style: theme.textTheme.bodySmall,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '$price ${plan.currency}',
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
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
                            subscription.isNoAdsSubscribed ||
                            hasPendingVerification
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
                          : (hasPendingVerification
                                ? 'Verification Pending'
                                : (subscription.isNoAdsSubscribed
                                      ? 'Subscribed'
                                      : 'Subscribe Now')),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
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
