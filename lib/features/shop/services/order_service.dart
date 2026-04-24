import '../../../core/services/api_service.dart';
import '../models/order.dart';
import 'shop_catalog_service.dart';

/// Order Service
///
/// Wraps all /ecom/orders endpoints (auth required).
class OrderService {
  final ApiService _api;
  OrderService(this._api);

  Future<OrderResponse?> placeOrder(PlaceOrderRequest request) async {
    final data = await _api.post('/ecom/orders', body: request.toJson());
    final json = data is Map ? data : (data['data'] as Map<String, dynamic>);
    return OrderResponse.fromJson(json as Map<String, dynamic>);
  }

  Future<PagedResponse<OrderResponse>> getOrders({
    int page = 0,
    int size = 20,
  }) async {
    final data = await _api.get('/ecom/orders?page=$page&size=$size');
    return _parsePage(data);
  }

  Future<OrderResponse?> getOrder(int id) async {
    final data = await _api.get('/ecom/orders/$id');
    final json = data is Map ? data : (data['data'] as Map<String, dynamic>);
    return OrderResponse.fromJson(json as Map<String, dynamic>);
  }

  Future<OrderResponse?> cancelOrder(int id, CancelOrderRequest request) async {
    final data = await _api.post(
      '/ecom/orders/$id/cancel',
      body: request.toJson(),
    );
    final json = data is Map ? data : (data['data'] as Map<String, dynamic>);
    return OrderResponse.fromJson(json as Map<String, dynamic>);
  }

  PagedResponse<OrderResponse> _parsePage(dynamic data) {
    if (data is List) {
      final items = data
          .map((e) => OrderResponse.fromJson(e as Map<String, dynamic>))
          .toList();
      return PagedResponse(items: items, hasNext: false);
    }
    final map = data as Map<String, dynamic>;
    final content =
        map['content'] as List<dynamic>? ??
        map['items'] as List<dynamic>? ??
        map['data'] as List<dynamic>? ??
        [];
    final items = content
        .map((e) => OrderResponse.fromJson(e as Map<String, dynamic>))
        .toList();
    return PagedResponse(
      items: items,
      totalElements: (map['totalElements'] as int?) ?? items.length,
      totalPages: (map['totalPages'] as int?) ?? 1,
      currentPage: (map['number'] as int?) ?? (map['page'] as int?) ?? 0,
      hasNext:
          (map['hasNext'] as bool?) ??
          (map['last'] != null ? !(map['last'] as bool) : false),
    );
  }
}
