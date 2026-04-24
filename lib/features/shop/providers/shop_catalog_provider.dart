import 'package:flutter/foundation.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../services/shop_catalog_service.dart';

/// Shop Catalog Provider
///
/// Manages categories, product lists, search results, and featured products.
class ShopCatalogProvider extends ChangeNotifier {
  final ShopCatalogService _service;

  ShopCatalogProvider(this._service);

  // ── Categories ────────────────────────────────────────────────────────────
  List<CategoryResponse> _categories = [];
  bool _categoriesLoading = false;
  String? _categoriesError;

  List<CategoryResponse> get categories => _categories;
  bool get categoriesLoading => _categoriesLoading;
  String? get categoriesError => _categoriesError;

  Future<void> loadCategories() async {
    if (_categories.isNotEmpty) return;
    _categoriesLoading = true;
    _categoriesError = null;
    notifyListeners();
    try {
      _categories = await _service.getCategories();
    } catch (e) {
      _categoriesError = 'Failed to load categories';
    } finally {
      _categoriesLoading = false;
      notifyListeners();
    }
  }

  // ── Featured products ─────────────────────────────────────────────────────
  List<ProductResponse> _featured = [];
  bool _featuredLoading = false;
  String? _featuredError;

  List<ProductResponse> get featured => _featured;
  bool get featuredLoading => _featuredLoading;

  Future<void> loadFeatured() async {
    if (_featured.isNotEmpty) return;
    _featuredLoading = true;
    _featuredError = null;
    notifyListeners();
    try {
      _featured = await _service.getFeaturedProducts();
    } catch (e) {
      _featuredError = 'Failed to load featured products';
    } finally {
      _featuredLoading = false;
      notifyListeners();
    }
  }

  // ── Product listing ───────────────────────────────────────────────────────
  List<ProductResponse> _products = [];
  bool _productsLoading = false;
  bool _productsHasMore = true;
  int _productsPage = 0;
  int? _selectedCategoryId;
  String? _productsError;

  List<ProductResponse> get products => _products;
  bool get productsLoading => _productsLoading;
  bool get productsHasMore => _productsHasMore;
  int? get selectedCategoryId => _selectedCategoryId;

  Future<void> loadProducts({int? categoryId, bool refresh = false}) async {
    if (refresh || categoryId != _selectedCategoryId) {
      _products = [];
      _productsPage = 0;
      _productsHasMore = true;
      _selectedCategoryId = categoryId;
    }
    if (!_productsHasMore || _productsLoading) return;
    _productsLoading = true;
    _productsError = null;
    notifyListeners();
    try {
      PagedResponse<ProductResponse> page;
      if (categoryId != null) {
        page = await _service.getCategoryProducts(
          categoryId,
          page: _productsPage,
        );
      } else {
        page = await _service.getProducts(page: _productsPage);
      }
      _products.addAll(page.items);
      _productsHasMore = page.hasNext;
      _productsPage++;
    } catch (e) {
      _productsError = 'Failed to load products';
    } finally {
      _productsLoading = false;
      notifyListeners();
    }
  }

  // ── Search ────────────────────────────────────────────────────────────────
  List<ProductResponse> _searchResults = [];
  bool _searchLoading = false;
  bool _searchHasMore = false;
  int _searchPage = 0;
  String _lastQuery = '';
  String? _searchError;

  List<ProductResponse> get searchResults => _searchResults;
  bool get searchLoading => _searchLoading;
  bool get searchHasMore => _searchHasMore;
  String get lastQuery => _lastQuery;

  Future<void> search(String query, {bool refresh = false}) async {
    if (query.isEmpty) {
      _searchResults = [];
      _lastQuery = '';
      notifyListeners();
      return;
    }
    if (refresh || query != _lastQuery) {
      _searchResults = [];
      _searchPage = 0;
      _searchHasMore = true;
      _lastQuery = query;
    }
    if (!_searchHasMore || _searchLoading) return;
    _searchLoading = true;
    _searchError = null;
    notifyListeners();
    try {
      final page = await _service.searchProducts(query, page: _searchPage);
      _searchResults.addAll(page.items);
      _searchHasMore = page.hasNext;
      _searchPage++;
    } catch (e) {
      _searchError = 'Search failed';
    } finally {
      _searchLoading = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchResults = [];
    _lastQuery = '';
    _searchPage = 0;
    _searchHasMore = false;
    notifyListeners();
  }

  // ── Product detail ────────────────────────────────────────────────────────
  final Map<int, ProductResponse> _productCache = {};

  Future<ProductResponse?> getProduct(int id) async {
    if (_productCache.containsKey(id)) return _productCache[id];
    try {
      final p = await _service.getProduct(id);
      _productCache[id] = p;
      notifyListeners();
      return p;
    } catch (_) {
      return null;
    }
  }
}
