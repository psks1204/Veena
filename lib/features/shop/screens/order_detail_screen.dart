import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/invoice.dart';
import '../../../core/services/invoice_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';

/// Order Detail Screen
class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final int orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _invoiceLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrderDetail(widget.orderId);
    });
  }

  Future<void> _cancelOrder(OrderResponse order) async {
    // Collect a cancellation reason from the user
    final reasonCtrl = TextEditingController();

    // Use the dialog builder's OWN context for Navigator.pop — NOT the outer
    // context. The outer context belongs to the nested tab Navigator; using it
    // inside a dialog (which showDialog puts on the ROOT navigator) would call
    // Navigator.pop on the tab navigator and unintentionally pop this screen.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please tell us why you want to cancel this order.'),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            // ← dialogCtx, NOT the outer context
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Keep Order'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );

    // Capture reason BEFORE disposing the controller
    final reason = reasonCtrl.text.trim().isEmpty
        ? null
        : reasonCtrl.text.trim();
    reasonCtrl.dispose();

    if (!mounted) return;
    if (confirmed != true) return;

    final ok = await context.read<OrderProvider>().cancelOrder(
      order.id,
      reason: reason,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Order cancelled.' : 'Failed to cancel order. Please try again.',
        ),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _showInvoice(OrderResponse order) async {
    setState(() => _invoiceLoading = true);
    try {
      final invoiceService = context.read<InvoiceService>();
      InvoiceResponse invoice;
      try {
        invoice = await invoiceService.getOrderInvoice(order.id);
      } catch (_) {
        invoice = await invoiceService.generateOrderInvoice(order.id);
      }

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogCtx) {
          return AlertDialog(
            title: const Text('Invoice'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Invoice #: ${invoice.invoiceNumber}'),
                const SizedBox(height: 6),
                Text('Status: ${invoice.status}'),
                const SizedBox(height: 6),
                Text('Type: ${invoice.invoiceType}'),
                const SizedBox(height: 6),
                Text(
                  'Total: ${invoice.currency} ${invoice.totalAmount.toStringAsFixed(2)}',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Close'),
              ),
              if (invoice.pdfUrl != null)
                FilledButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(invoice.pdfUrl!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Download PDF'),
                ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to load invoice: $e')));
    } finally {
      if (mounted) {
        setState(() => _invoiceLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<OrderProvider>();
    final order = provider.currentOrder;

    if (provider.detailLoading || order == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Order', style: theme.textTheme.headlineMedium),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          order.orderNumber ?? '#${order.id}',
          style: theme.textTheme.headlineMedium,
        ),
        actions: [
          IconButton(
            tooltip: 'Invoice',
            onPressed: _invoiceLoading ? null : () => _showInvoice(order),
            icon: _invoiceLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.receipt_long_rounded),
          ),
          if (order.canCancel)
            TextButton(
              onPressed: () => _cancelOrder(order),
              child: Text('Cancel', style: TextStyle(color: AppColors.error)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            _StatusBadge(status: order.status),
            const SizedBox(height: AppSpacing.lg),

            // Shipping info
            if (order.shipment != null) ...[
              _Section(
                title: 'Tracking',
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (order.shipment!.courierName != null)
                      _buildRow('Courier', order.shipment!.courierName!, theme),
                    if (order.shipment!.awbCode != null)
                      _buildRow('AWB', order.shipment!.awbCode!, theme),
                    if (order.shipment!.estimatedDelivery != null)
                      _buildRow(
                        'Est. Delivery',
                        order.shipment!.estimatedDelivery!,
                        theme,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Items
            _Section(
              title: 'Items',
              isDark: isDark,
              child: Column(
                children: order.items
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.productName}${item.variantName != null ? " (${item.variantName})" : ""} × ${item.quantity}',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            Text(
                              '₹${item.totalPrice.toStringAsFixed(0)}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Delivery address
            _Section(
              title: 'Delivery Address',
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (order.shippingName != null)
                    Text(
                      order.shippingName!,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  if (order.shippingAddress1 != null)
                    Text(
                      [
                        order.shippingAddress1,
                        if (order.shippingAddress2 != null)
                          order.shippingAddress2,
                        if (order.shippingCity != null) order.shippingCity,
                        if (order.shippingState != null) order.shippingState,
                        if (order.shippingPincode != null)
                          order.shippingPincode,
                      ].whereType<String>().join(', '),
                      style: theme.textTheme.bodyMedium,
                    ),
                  if (order.shippingPhone != null)
                    Text(
                      order.shippingPhone!,
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Payment summary
            _Section(
              title: 'Payment',
              isDark: isDark,
              child: Column(
                children: [
                  _buildRow(
                    'Subtotal',
                    '₹${order.subtotal.toStringAsFixed(0)}',
                    theme,
                  ),
                  if (order.taxAmount > 0)
                    _buildRow(
                      'Tax',
                      '₹${order.taxAmount.toStringAsFixed(0)}',
                      theme,
                    ),
                  if (order.shippingCharge > 0)
                    _buildRow(
                      'Shipping',
                      '₹${order.shippingCharge.toStringAsFixed(0)}',
                      theme,
                    ),
                  const Divider(),
                  _buildRow(
                    'Total',
                    '₹${order.totalAmount.toStringAsFixed(0)}',
                    theme,
                    bold: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case OrderStatus.delivered:
        color = AppColors.success;
        label = 'Delivered';
        icon = Icons.check_circle_rounded;
        break;
      case OrderStatus.cancelled:
        color = AppColors.error;
        label = 'Cancelled';
        icon = Icons.cancel_rounded;
        break;
      case OrderStatus.shipped:
        color = Colors.blue;
        label = 'Shipped';
        icon = Icons.local_shipping_rounded;
        break;
      case OrderStatus.outForDelivery:
        color = Colors.blue;
        label = 'Out for Delivery';
        icon = Icons.delivery_dining_rounded;
        break;
      default:
        color = Colors.orange;
        label = _label(status);
        icon = Icons.access_time_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _label(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.returnRequested:
        return 'Return Requested';
      case OrderStatus.returned:
        return 'Returned';
      case OrderStatus.refunded:
        return 'Refunded';
      default:
        return 'Unknown';
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.isDark,
    required this.child,
  });
  final String title;
  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
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
          child: child,
        ),
      ],
    );
  }
}

Widget _buildRow(
  String label,
  String value,
  ThemeData theme, {
  bool bold = false,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(
          value,
          style: bold
              ? theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                )
              : theme.textTheme.bodyMedium,
        ),
      ],
    ),
  );
}
