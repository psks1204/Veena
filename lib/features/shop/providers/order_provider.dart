import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../services/shop_catalog_service.dart';

/// Order Provider
///
/// Manages order listing, detail, placement, and cancellation.
class OrderProvider extends ChangeNotifier {
  final OrderService _service;

  OrderProvider(this._service);

  List<OrderResponse> _orders = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 0;
  String? _error;

  // Currently viewed order detail
  OrderResponse? _currentOrder;
  bool _detailLoading = false;

  List<OrderResponse> get orders => _orders;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;
  OrderResponse? get currentOrder => _currentOrder;
  bool get detailLoading => _detailLoading;

  Future<void> loadOrders({bool refresh = false}) async {
    if (refresh) {
      _orders = [];
      _page = 0;
      _hasMore = true;
    }
    if (!_hasMore || _isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _service.getOrders(page: _page);
      _orders.addAll(result.items);
      _hasMore = result.hasNext;
      _page++;
    } catch (e) {
      _error = 'Failed to load orders';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadOrderDetail(int id) async {
    _detailLoading = true;
    notifyListeners();
    try {
      _currentOrder = await _service.getOrder(id);
    } catch (_) {
      _currentOrder = null;
    } finally {
      _detailLoading = false;
      notifyListeners();
    }
  }

  Future<OrderResponse?> placeOrder(PlaceOrderRequest request) async {
    try {
      final order = await _service.placeOrder(request);
      if (order != null) {
        _orders.insert(0, order);
        notifyListeners();
      }
      return order;
    } catch (e) {
      _error = 'Failed to place order';
      notifyListeners();
      return null;
    }
  }

  Future<bool> cancelOrder(int id, {String? reason}) async {
    try {
      final updated = await _service.cancelOrder(
        id,
        CancelOrderRequest(reason: reason),
      );
      if (updated != null) {
        final idx = _orders.indexWhere((o) => o.id == id);
        if (idx >= 0) _orders[idx] = updated;
        if (_currentOrder?.id == id) _currentOrder = updated;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to cancel order';
      notifyListeners();
      return false;
    }
  }
}
