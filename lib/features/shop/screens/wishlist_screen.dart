import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/product.dart';
import '../providers/wishlist_provider.dart';
import '../providers/shop_catalog_provider.dart';
import '../providers/cart_provider.dart';
import 'product_detail_screen.dart';

/// Wishlist Screen
///
/// Shows locally saved wishlist items (product IDs from SharedPreferences).
/// Loads product details on-demand for each wishlist item.
class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final Map<int, ProductResponse?> _products = {};
  final Set<int> _failedProductIds = {};
  Set<int> _lastWishlistIds = const {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProducts());
  }

  Future<void> _loadProducts() async {
    final wishlist = context.read<WishlistProvider>();
    final ids = wishlist.wishlistIds;
    _syncLocalState(ids);

    final pendingIds = ids
        .where(
          (id) => !_products.containsKey(id) && !_failedProductIds.contains(id),
        )
        .toList();
    if (pendingIds.isEmpty) return;

    if (mounted) {
      setState(() => _loading = true);
    }
    final catalog = context.read<ShopCatalogProvider>();

    try {
      for (final id in pendingIds) {
        try {
          final p = await catalog.getProduct(id);
          if (!mounted) return;
          if (p != null) {
            setState(() => _products[id] = p);
          } else {
            setState(() => _failedProductIds.add(id));
          }
        } catch (_) {
          if (!mounted) return;
          setState(() => _failedProductIds.add(id));
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _syncLocalState(Set<int> ids) {
    _products.removeWhere((id, _) => !ids.contains(id));
    _failedProductIds.removeWhere((id) => !ids.contains(id));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final wishlist = context.watch<WishlistProvider>();
    final ids = wishlist.wishlistIds.toList();
    final idsSet = wishlist.wishlistIds;

    if (!setEquals(_lastWishlistIds, idsSet)) {
      _lastWishlistIds = Set<int>.from(idsSet);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _loadProducts();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Wishlist', style: theme.textTheme.headlineMedium),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: _loading && ids.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ids.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite_border_rounded,
                        size: 80,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Your wishlist is empty',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 260,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: ids.length,
                  itemBuilder: (context, index) {
                    final id = ids[index];
                    if (_failedProductIds.contains(id)) {
                      return _UnavailableWishlistCard(
                        isDark: isDark,
                        onRemove: () {
                          wishlist.remove(id);
                          setState(() {
                            _products.remove(id);
                            _failedProductIds.remove(id);
                          });
                        },
                      );
                    }

                    final product = _products[id];
                    if (product == null) {
                      return Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface
                              : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                        ),
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    }
                    return _WishlistCard(
                      product: product,
                      isDark: isDark,
                      onRemove: () {
                        wishlist.remove(id);
                        setState(() => _products.remove(id));
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _WishlistCard extends StatelessWidget {
  const _WishlistCard({
    required this.product,
    required this.isDark,
    required this.onRemove,
  });
  final ProductResponse product;
  final bool isDark;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = context.watch<CartProvider>();
    final inCart = cart.isInCart(product.id);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(productId: product.id),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.06),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSpacing.radiusLg),
                    ),
                    child: product.primaryImageUrl != null
                        ? Image.network(
                            product.primaryImageUrl!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: isDark
                                  ? AppColors.darkSurfaceVariant
                                  : AppColors.lightSurfaceVariant,
                            ),
                          )
                        : Container(
                            color: isDark
                                ? AppColors.darkSurfaceVariant
                                : AppColors.lightSurfaceVariant,
                            child: const Center(
                              child: Icon(Icons.image_outlined, size: 40),
                            ),
                          ),
                  ),
                  // Remove from wishlist
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black54
                              : Colors.white.withOpacity(0.85),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          size: 16,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${product.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  SizedBox(
                    width: double.infinity,
                    height: 30,
                    child: FilledButton(
                      onPressed: product.inStock
                          ? () {
                              if (!inCart) {
                                context.read<CartProvider>().addItem(
                                  productId: product.id,
                                );
                              }
                            }
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: inCart
                            ? AppColors.success
                            : AppColors.primary,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                      ),
                      child: Text(
                        inCart ? 'Added ✓' : 'Add to Cart',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnavailableWishlistCard extends StatelessWidget {
  const _UnavailableWishlistCard({
    required this.isDark,
    required this.onRemove,
  });

  final bool isDark;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              size: 32,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Unable to load this item',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(onPressed: onRemove, child: const Text('Remove')),
          ],
        ),
      ),
    );
  }
}
