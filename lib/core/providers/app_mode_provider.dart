import 'package:flutter/foundation.dart';

/// App display mode — music (default) or shop
enum AppMode { music, shop }

/// AppModeProvider
///
/// Controls whether the app is showing the music shell or the shop shell.
/// Used to implement the "two apps in one" experience.
class AppModeProvider extends ChangeNotifier {
  AppMode _mode = AppMode.music;
  int _shopTabIndex = 0;

  AppMode get mode => _mode;
  bool get isShop => _mode == AppMode.shop;
  bool get isMusic => _mode == AppMode.music;
  int get shopTabIndex => _shopTabIndex;

  void enterShop() {
    if (_mode != AppMode.shop) {
      _mode = AppMode.shop;
      notifyListeners();
    }
  }

  void exitShop() {
    if (_mode != AppMode.music) {
      _mode = AppMode.music;
      notifyListeners();
    }
  }

  void setShopTab(int index) {
    if (_shopTabIndex != index) {
      _shopTabIndex = index;
      notifyListeners();
    }
  }
}
