import 'dart:convert';
import '../../../core/services/api_service.dart';
import '../models/category.dart';
import '../models/product.dart';

/// Paged API response wrapper
class PagedResponse<T> {
  final List<T> items;
  final int totalElements;
  final int totalPages;
  final int currentPage;
  final bool hasNext;

  const PagedResponse({
    required this.items,
    this.totalElements = 0,
    this.totalPages = 1,
    this.currentPage = 0,
    this.hasNext = false,
  });
}

/// Shop Catalog Service
///
/// Wraps all public ecommerce catalog endpoints (no auth required for reads).
class ShopCatalogService {
  final ApiService _api;

  ShopCatalogService(this._api);

  // ── Categories ────────────────────────────────────────────────────────────

  Future<List<CategoryResponse>> getCategories() async {
    final data = await _api.get('/ecom/categories');
    final list = data is List ? data : (data['data'] as List<dynamic>? ?? []);
    return list
        .map((e) => CategoryResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CategoryResponse> getCategory(int id) async {
    final data = await _api.get('/ecom/categories/$id');
    final json = data is Map ? data : (data['data'] as Map<String, dynamic>);
    return CategoryResponse.fromJson(json as Map<String, dynamic>);
  }

  Future<PagedResponse<ProductResponse>> getCategoryProducts(
    int categoryId, {
    int page = 0,
    int size = 20,
  }) async {
    final data = await _api.get(
      '/ecom/categories/$categoryId/products?page=$page&size=$size',
    );
    return _parseProductPage(data);
  }

  // ── Products ──────────────────────────────────────────────────────────────

  Future<PagedResponse<ProductResponse>> getProducts({
    int page = 0,
    int size = 20,
    int? categoryId,
    bool? featured,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'size': '$size',
      if (categoryId != null) 'categoryId': '$categoryId',
      if (featured == true) 'featured': 'true',
      if (minPrice != null) 'minPrice': '$minPrice',
      if (maxPrice != null) 'maxPrice': '$maxPrice',
      if (sortBy != null) 'sortBy': sortBy,
    };
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final data = await _api.get('/ecom/products?$query');
    return _parseProductPage(data);
  }

  Future<PagedResponse<ProductResponse>> searchProducts(
    String query, {
    int page = 0,
    int size = 20,
  }) async {
    final encoded = Uri.encodeQueryComponent(query);
    final data = await _api.get(
      '/ecom/products/search?q=$encoded&page=$page&size=$size',
    );
    return _parseProductPage(data);
  }

  Future<List<ProductResponse>> getFeaturedProducts() async {
    final data = await _api.get('/ecom/products/featured');
    final list = data is List ? data : (data['data'] as List<dynamic>? ?? []);
    return list
        .map((e) => ProductResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProductResponse> getProduct(int id) async {
    final data = await _api.get('/ecom/products/$id');
    final json = data is Map ? data : (data['data'] as Map<String, dynamic>);
    return ProductResponse.fromJson(json as Map<String, dynamic>);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  PagedResponse<ProductResponse> _parseProductPage(dynamic data) {
    if (data is List) {
      final items = data
          .map((e) => ProductResponse.fromJson(e as Map<String, dynamic>))
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
        .map((e) => ProductResponse.fromJson(e as Map<String, dynamic>))
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
