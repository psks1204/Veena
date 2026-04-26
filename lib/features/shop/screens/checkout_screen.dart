import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/constants/payment_config.dart';
import '../../../core/services/razorpay_web_checkout.dart';
import '../../../core/providers/app_mode_provider.dart';
import '../models/address.dart';
import '../providers/cart_provider.dart';
import '../providers/address_provider.dart';
import '../providers/order_provider.dart';
import '../models/order.dart';
import '../models/payment.dart';
import '../services/payment_service.dart';
import 'address_screen.dart';

/// Checkout Screen
///
/// Address selection + order summary → place order.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  AddressResponse? _selectedAddress;
  bool _placing = false;
  String? _error;
  Razorpay? _razorpay;
  Completer<_CheckoutResult>? _checkoutCompleter;

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final addrProvider = context.read<AddressProvider>();
      if (addrProvider.addresses.isEmpty) {
        addrProvider.loadAddresses().then((_) {
          if (mounted) {
            setState(() {
              _selectedAddress = addrProvider.defaultAddress;
            });
          }
        });
      } else {
        setState(() {
          _selectedAddress = addrProvider.defaultAddress;
        });
      }
    });
  }

  Future<void> _placeOrder() async {
    if (_selectedAddress == null) {
      setState(() => _error = 'Please select a delivery address');
      return;
    }
    setState(() {
      _placing = true;
      _error = null;
    });

    final order = await context.read<OrderProvider>().placeOrder(
      PlaceOrderRequest(addressId: _selectedAddress!.id),
    );

    if (!mounted) return;

    if (order != null) {
      final paymentOk = await _startOrderPayment(order);

      if (!mounted) return;
      setState(() => _placing = false);

      if (!paymentOk) {
        await context.read<CartProvider>().loadCart();
        if (!mounted) return;
        return;
      }

      // Clear the cart first after successful payment verification
      await context.read<CartProvider>().clearCart();
      if (!mounted) return;

      // Show the order success screen — replaces the checkout route so the
      // user can't go "back to checkout" after placing the order.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => _OrderSuccessScreen(order: order)),
      );
    } else {
      setState(() => _placing = false);
      setState(() => _error = 'Failed to place order. Please try again.');
    }
  }

  Future<bool> _startOrderPayment(OrderResponse order) async {
    if (!PaymentConfig.hasRazorpayKey) {
      setState(() {
        _error =
            'Razorpay key is not configured. Add --dart-define for current APP_ENV.';
      });
      return false;
    }

    try {
      final paymentService = context.read<PaymentService>();
      final pendingPayment = await paymentService.createPaymentOrder(order.id);
      if (pendingPayment == null ||
          pendingPayment.razorpayOrderId == null ||
          pendingPayment.razorpayOrderId!.isEmpty) {
        setState(() => _error = 'Unable to initiate payment for this order.');
        return false;
      }

      final checkoutResult = await _openRazorpayCheckout(order, pendingPayment);
      if (!checkoutResult.ok) {
        setState(() {
          _error = checkoutResult.message ?? 'Payment was not completed.';
        });
        return false;
      }

      final verifyResult = await paymentService.verifyPayment(
        PaymentVerifyRequest(
          razorpayOrderId: checkoutResult.orderId?.isNotEmpty == true
              ? checkoutResult.orderId!
              : pendingPayment.razorpayOrderId!,
          razorpayPaymentId: checkoutResult.paymentId ?? '',
          razorpaySignature: checkoutResult.signature ?? '',
        ),
      );

      if (verifyResult == null) {
        setState(() => _error = 'Payment verification failed.');
        return false;
      }

      return true;
    } catch (e) {
      setState(() => _error = 'Payment failed: $e');
      return false;
    }
  }

  Future<_CheckoutResult> _openRazorpayCheckout(
    OrderResponse order,
    PaymentResponse pendingPayment,
  ) async {
    if (kIsWeb) {
      final result = await openRazorpayWebCheckout(
        key: PaymentConfig.razorpayKey,
        amount: (pendingPayment.amount * 100).round(),
        currency: pendingPayment.currency,
        name: 'Veena Shop',
        description: 'Order ${order.orderNumber ?? '#${order.id}'}',
        orderId: pendingPayment.razorpayOrderId ?? '',
        prefillName: order.userName ?? order.shippingName ?? '',
        prefillEmail: order.userEmail ?? '',
        prefillContact: order.shippingPhone ?? '',
      );

      if (!result.ok) {
        return _CheckoutResult.failure(result.message ?? 'Payment failed.');
      }

      return _CheckoutResult.success(
        orderId: result.orderId ?? (pendingPayment.razorpayOrderId ?? ''),
        paymentId: result.paymentId ?? '',
        signature: result.signature ?? '',
      );
    }

    _razorpay ??= Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);

    _checkoutCompleter = Completer<_CheckoutResult>();

    try {
      _razorpay!.open({
        'key': PaymentConfig.razorpayKey,
        'amount': (pendingPayment.amount * 100).round(),
        'currency': pendingPayment.currency,
        'name': 'Veena Shop',
        'description': 'Order ${order.orderNumber ?? '#${order.id}'}',
        'order_id': pendingPayment.razorpayOrderId,
        'prefill': {
          'name': order.userName ?? order.shippingName ?? '',
          'email': order.userEmail ?? '',
          'contact': order.shippingPhone ?? '',
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
      _CheckoutResult.failure(response.message ?? 'Payment failed.'),
    );
    _checkoutCompleter = null;
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    _checkoutCompleter?.complete(
      _CheckoutResult.failure(
        'External wallet selected (${response.walletName ?? 'unknown'}).',
      ),
    );
    _checkoutCompleter = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cart = context.watch<CartProvider>();
    final addrProvider = context.watch<AddressProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout', style: theme.textTheme.headlineMedium),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Delivery address section ──────────────────────────
            Text(
              'Delivery Address',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            if (addrProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (addrProvider.addresses.isEmpty)
              _AddNewAddressTile(isDark: isDark)
            else ...[
              ...addrProvider.addresses.map(
                (addr) => _AddressTile(
                  address: addr,
                  selected: _selectedAddress?.id == addr.id,
                  isDark: isDark,
                  onTap: () => setState(() => _selectedAddress = addr),
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddressScreen()),
                  );
                  if (mounted) {
                    await addrProvider.loadAddresses();
                    setState(() {
                      _selectedAddress = addrProvider.defaultAddress;
                    });
                  }
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add New Address'),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),

            // ── Order summary ─────────────────────────────────────
            Text(
              'Order Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Column(
                children: [
                  ...cart.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.productName}${item.variantName != null ? " (${item.variantName})" : ""} × ${item.quantity}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          Text(
                            '₹${item.totalPrice.toStringAsFixed(0)}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                  if ((cart.cart?.taxAmount ?? 0) > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tax', style: theme.textTheme.bodyMedium),
                        Text(
                          '₹${cart.cart?.taxAmount.toStringAsFixed(0) ?? "0"}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₹${cart.totalAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),

            // ── Place Order button — lives in the scroll body so it clears the
            // FloatingNavBar (ShopShell handles padding via MediaQuery override)
            SafeArea(
              top: false,
              child: FilledButton(
                onPressed: _placing ? null : _placeOrder,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                ),
                child: _placing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Place Order'),
              ),
            ),

            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.address,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });
  final AddressResponse address;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.08)),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? AppColors.primary : null,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    address.singleLine,
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(address.phone, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            if (address.isDefault)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Default',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddNewAddressTile extends StatelessWidget {
  const _AddNewAddressTile({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AddressScreen()));
        if (!context.mounted) return;
        await context.read<AddressProvider>().loadAddresses();
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add_rounded, color: AppColors.primary),
            SizedBox(width: AppSpacing.sm),
            Text(
              'Add Delivery Address',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Order Success Screen ───────────────────────────────────────────────────────

/// Shown after a successful checkout. Replaces the CheckoutScreen in the
/// navigation stack so the user cannot go back to checkout.
class _OrderSuccessScreen extends StatelessWidget {
  const _OrderSuccessScreen({required this.order});
  final OrderResponse order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final orderNum = order.orderNumber ?? '#${order.id}';

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Success icon
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 56,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  Text(
                    'Order Placed!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Your order $orderNum has been placed successfully.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Total: ₹${order.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // View Order button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        // Switch to Orders tab and refresh — the tab navigator
                        // root (OrdersScreen) will show the new order.
                        context.read<AppModeProvider>().setShopTab(1);
                        context.read<OrderProvider>().loadOrders(refresh: true);
                        // Pop back to the cart tab root (clears checkout route)
                        Navigator.of(context).popUntil((r) => r.isFirst);
                      },
                      icon: const Icon(Icons.receipt_long_rounded),
                      label: const Text('View My Orders'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Continue Shopping button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.read<AppModeProvider>().setShopTab(0);
                        Navigator.of(context).popUntil((r) => r.isFirst);
                      },
                      icon: const Icon(Icons.storefront_rounded),
                      label: const Text('Continue Shopping'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
