import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wishlist Provider
///
/// Local-only wishlist using SharedPreferences (no backend endpoint).
/// Stores a set of product IDs as strings.
class WishlistProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  static const _key = 'shop_wishlist_ids';

  WishlistProvider(this._prefs) {
    _load();
  }

  final Set<int> _wishlistIds = {};

  Set<int> get wishlistIds => Set.unmodifiable(_wishlistIds);
  int get count => _wishlistIds.length;

  bool isWishlisted(int productId) => _wishlistIds.contains(productId);

  void _load() {
    final stored = _prefs.getStringList(_key) ?? [];
    _wishlistIds.addAll(stored.map((s) => int.tryParse(s)).whereType<int>());
  }

  Future<void> toggle(int productId) async {
    if (_wishlistIds.contains(productId)) {
      _wishlistIds.remove(productId);
    } else {
      _wishlistIds.add(productId);
    }
    await _save();
    notifyListeners();
  }

  Future<void> add(int productId) async {
    if (_wishlistIds.add(productId)) {
      await _save();
      notifyListeners();
    }
  }

  Future<void> remove(int productId) async {
    if (_wishlistIds.remove(productId)) {
      await _save();
      notifyListeners();
    }
  }

  Future<void> _save() async {
    await _prefs.setStringList(_key, _wishlistIds.map((id) => '$id').toList());
  }
}
