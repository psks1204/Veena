import 'package:flutter/foundation.dart';
import '../models/cart.dart';
import '../services/cart_service.dart';

/// Cart Provider
///
/// Manages the shopping cart state and operations.
class CartProvider extends ChangeNotifier {
  final CartService _service;

  CartProvider(this._service);

  CartResponse? _cart;
  bool _isLoading = false;
  String? _error;

  CartResponse? get cart => _cart;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get itemCount => _cart?.totalItems ?? 0;
  double get totalAmount => _cart?.totalAmount ?? 0.0;
  List<CartItem> get items => _cart?.items ?? [];

  Future<void> loadCart() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _cart = await _service.getCart();
    } catch (e) {
      _error = 'Failed to load cart';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addItem({
    required int productId,
    int? variantId,
    int quantity = 1,
  }) async {
    _error = null;
    try {
      final request = AddToCartRequest(
        productId: productId,
        variantId: variantId,
        quantity: quantity,
      );
      final updated = await _service.addItem(request);
      if (updated != null) {
        _cart = updated;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to add item to cart';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateItem(int itemId, int quantity) async {
    if (quantity <= 0) return removeItem(itemId);
    _error = null;
    try {
      final request = UpdateCartItemRequest(quantity: quantity);
      final updated = await _service.updateItem(itemId, request);
      if (updated != null) {
        _cart = updated;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to update cart item';
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeItem(int itemId) async {
    _error = null;
    try {
      final ok = await _service.removeItem(itemId);
      if (ok) {
        // Optimistically remove from list
        _cart = _cart == null
            ? null
            : CartResponse(
                id: _cart!.id,
                items: _cart!.items.where((i) => i.id != itemId).toList(),
                totalItems: (_cart!.totalItems - 1).clamp(0, 9999),
                subtotal: _cart!.subtotal,
                taxAmount: _cart!.taxAmount,
                totalAmount: _cart!.totalAmount,
              );
        // Reload for accurate totals
        await loadCart();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to remove item';
      notifyListeners();
      return false;
    }
  }

  Future<bool> clearCart() async {
    _error = null;
    try {
      final ok = await _service.clearCart();
      if (ok) {
        _cart = null;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to clear cart';
      notifyListeners();
      return false;
    }
  }

  bool isInCart(int productId) =>
      _cart?.items.any((i) => i.productId == productId) ?? false;
}
