import 'package:flutter/material.dart';
import 'app_tabs.dart';

/// Global navigator keys for each tab - allows navigation within tabs
/// while keeping the shell (nav bar + mini player) visible
class AppNavigation {
  // Private constructor to prevent instantiation
  AppNavigation._();

  /// Navigator keys for each tab
  static final homeNavigatorKey = GlobalKey<NavigatorState>();
  static final uploadsNavigatorKey = GlobalKey<NavigatorState>();
  static final searchNavigatorKey = GlobalKey<NavigatorState>();
  static final libraryNavigatorKey = GlobalKey<NavigatorState>();
  static final profileNavigatorKey = GlobalKey<NavigatorState>();

  /// Navigator keys for shop tabs
  static final shopHomeKey = GlobalKey<NavigatorState>();
  static final shopOrdersKey = GlobalKey<NavigatorState>();
  static final shopWishlistKey = GlobalKey<NavigatorState>();
  static final shopCartKey = GlobalKey<NavigatorState>();

  /// Current active tab index
  static int _currentTabIndex = 0;

  /// Set the current tab index (called when tab changes)
  static void setCurrentTab(int index) {
    _currentTabIndex = index;
  }

  /// Get the navigator key for the current tab
  static GlobalKey<NavigatorState> get currentNavigatorKey {
    switch (_currentTabIndex) {
      case AppTabs.home:
        return homeNavigatorKey;
      case AppTabs.uploads:
        return uploadsNavigatorKey;
      case AppTabs.search:
        return searchNavigatorKey;
      case AppTabs.library:
        return libraryNavigatorKey;
      case AppTabs.profile:
        return profileNavigatorKey;
      default:
        return homeNavigatorKey;
    }
  }

  /// Get navigator key for a specific tab index
  static GlobalKey<NavigatorState> getNavigatorKey(int index) {
    switch (index) {
      case AppTabs.home:
        return homeNavigatorKey;
      case AppTabs.uploads:
        return uploadsNavigatorKey;
      case AppTabs.search:
        return searchNavigatorKey;
      case AppTabs.library:
        return libraryNavigatorKey;
      case AppTabs.profile:
        return profileNavigatorKey;
      // Shop tabs (5-8)
      case AppTabs.shopHome:
        return shopHomeKey;
      case AppTabs.shopOrders:
        return shopOrdersKey;
      case AppTabs.shopWishlist:
        return shopWishlistKey;
      case AppTabs.shopCart:
        return shopCartKey;
      default:
        return homeNavigatorKey;
    }
  }

  /// Push a route within the current tab's navigator
  /// Use this instead of Navigator.of(context).push() to keep nav bar visible
  static Future<T?> push<T>(BuildContext context, Route<T> route) {
    return currentNavigatorKey.currentState!.push(route);
  }

  /// Push a named route within the current tab's navigator
  static Future<T?> pushNamed<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return currentNavigatorKey.currentState!.pushNamed(
      routeName,
      arguments: arguments,
    );
  }

  /// Pop the current route within the tab's navigator
  static void pop<T>(BuildContext context, [T? result]) {
    currentNavigatorKey.currentState!.pop(result);
  }

  /// Pop until a specific route within the tab's navigator
  static void popUntil(BuildContext context, RoutePredicate predicate) {
    currentNavigatorKey.currentState!.popUntil(predicate);
  }

  /// Check if the current tab's navigator can pop
  static bool canPop() {
    return currentNavigatorKey.currentState?.canPop() ?? false;
  }

  /// Try to pop the current tab's navigator, returns true if popped
  static bool maybePop<T>([T? result]) {
    if (canPop()) {
      currentNavigatorKey.currentState!.pop(result);
      return true;
    }
    return false;
  }

  /// Push a route within a specific tab
  static Future<T?> pushInTab<T>(int tabIndex, Route<T> route) {
    return getNavigatorKey(tabIndex).currentState!.push(route);
  }

  /// Pop to first route in the current tab
  static void popToFirst() {
    currentNavigatorKey.currentState!.popUntil((route) => route.isFirst);
  }
}
