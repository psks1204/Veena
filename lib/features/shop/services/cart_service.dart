import '../../../core/services/api_service.dart';
import '../models/cart.dart';

/// Cart Service
///
/// Wraps all /ecom/cart endpoints (auth required).
class CartService {
  final ApiService _api;
  CartService(this._api);

  Future<CartResponse?> getCart() async {
    try {
      final data = await _api.get('/ecom/cart');
      final json = data is Map ? data : (data['data'] as Map<String, dynamic>);
      return CartResponse.fromJson(json as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<CartResponse?> addItem(AddToCartRequest request) async {
    final data = await _api.post('/ecom/cart/items', body: request.toJson());
    final json = data is Map ? data : (data['data'] as Map<String, dynamic>);
    return CartResponse.fromJson(json as Map<String, dynamic>);
  }

  Future<CartResponse?> updateItem(
    int itemId,
    UpdateCartItemRequest request,
  ) async {
    final data = await _api.put(
      '/ecom/cart/items/$itemId',
      body: request.toJson(),
    );
    final json = data is Map ? data : (data['data'] as Map<String, dynamic>);
    return CartResponse.fromJson(json as Map<String, dynamic>);
  }

  Future<bool> removeItem(int itemId) async {
    await _api.delete('/ecom/cart/items/$itemId');
    return true;
  }

  Future<bool> clearCart() async {
    await _api.delete('/ecom/cart');
    return true;
  }
}
