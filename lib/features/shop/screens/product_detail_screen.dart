import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/product.dart';
import '../providers/shop_catalog_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';
import 'cart_screen.dart';

/// Product Detail Screen
///
/// Displays full product information, variant selector, and add-to-cart.
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final int productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  ProductResponse? _product;
  bool _loading = true;
  ProductVariant? _selectedVariant;
  int _selectedImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final p = await context.read<ShopCatalogProvider>().getProduct(
      widget.productId,
    );
    if (mounted) {
      setState(() {
        _product = p;
        _loading = false;
        if (p != null && p.variants.isNotEmpty) {
          _selectedVariant = p.variants.firstWhere(
            (v) => v.inStock,
            orElse: () => p.variants.first,
          );
        }
      });
    }
  }

  void _addToCart() async {
    final product = _product;
    if (product == null) return;
    final ok = await context.read<CartProvider>().addItem(
      productId: product.id,
      variantId: _selectedVariant?.id,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Added to cart!'),
          backgroundColor: AppColors.success,
          action: SnackBarAction(
            label: 'View Cart',
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const CartScreen()));
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Product not found')),
      );
    }

    final p = _product!;
    final cart = context.watch<CartProvider>();
    final wishlist = context.watch<WishlistProvider>();
    final inCart = cart.isInCart(p.id);
    final wishlisted = wishlist.isWishlisted(p.id);
    final effectivePrice = _selectedVariant?.price ?? p.price;
    final isAvailable = _selectedVariant?.inStock ?? p.inStock;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Image gallery as app bar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            actions: [
              IconButton(
                icon: Icon(
                  wishlisted
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: wishlisted ? AppColors.error : null,
                ),
                onPressed: () => wishlist.toggle(p.id),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: p.images.isNotEmpty
                  ? PageView.builder(
                      itemCount: p.images.length,
                      onPageChanged: (i) =>
                          setState(() => _selectedImageIndex = i),
                      itemBuilder: (context, i) => Image.network(
                        p.images[i].imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: isDark
                              ? AppColors.darkSurfaceVariant
                              : AppColors.lightSurfaceVariant,
                          child: const Icon(Icons.image_outlined, size: 64),
                        ),
                      ),
                    )
                  : Container(
                      color: isDark
                          ? AppColors.darkSurfaceVariant
                          : AppColors.lightSurfaceVariant,
                      child: const Center(
                        child: Icon(Icons.image_outlined, size: 64),
                      ),
                    ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Category
                  if (p.categoryName != null)
                    Text(
                      p.categoryName!,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    p.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Price
                  Row(
                    children: [
                      Text(
                        '₹${effectivePrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      if (p.compareAtPrice != null &&
                          p.compareAtPrice! > effectivePrice) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '₹${p.compareAtPrice!.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                            decoration: TextDecoration.lineThrough,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm,
                            ),
                          ),
                          child: Text(
                            '${p.discountPercent.toStringAsFixed(0)}% off',
                            style: const TextStyle(
                              color: AppColors.success,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Stock status
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Icon(
                        isAvailable
                            ? Icons.check_circle_outline_rounded
                            : Icons.cancel_outlined,
                        size: 16,
                        color: isAvailable
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isAvailable ? 'In Stock' : 'Out of Stock',
                        style: TextStyle(
                          color: isAvailable
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),

                  // Variants
                  if (p.variants.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Options',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: p.variants.map((v) {
                        final selected = _selectedVariant?.id == v.id;
                        return ChoiceChip(
                          label: Text(v.name),
                          selected: selected,
                          onSelected: v.isActive
                              ? (_) => setState(() => _selectedVariant = v)
                              : null,
                          selectedColor: AppColors.primary.withOpacity(0.15),
                          side: BorderSide(
                            color: selected
                                ? AppColors.primary
                                : (isDark ? Colors.white24 : Colors.black26),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  // Description
                  if (p.description != null && p.description!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Description',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      p.description!,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],

                  // ── Add to Cart / View Cart — inside the body so it clears
                  // the FloatingNavBar rendered by ShopShell above it.
                  const SizedBox(height: AppSpacing.xl),
                  SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed:
                                isAvailable && !inCart ? _addToCart : null,
                            icon: Icon(
                              inCart
                                  ? Icons.check_rounded
                                  : Icons.shopping_cart_outlined,
                            ),
                            label: Text(
                                inCart ? 'Added to Cart' : 'Add to Cart'),
                            style: FilledButton.styleFrom(
                              backgroundColor: inCart
                                  ? AppColors.success
                                  : AppColors.primary,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusLg),
                              ),
                            ),
                          ),
                        ),
                        if (inCart) ...[
                          const SizedBox(width: AppSpacing.sm),
                          OutlinedButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const CartScreen()),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusLg),
                              ),
                            ),
                            child: const Text('View Cart'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
