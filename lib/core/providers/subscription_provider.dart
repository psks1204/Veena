import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/subscription.dart';
import '../services/subscription_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  SubscriptionProvider(this._prefs, this._service) {
    _cachedNoAdsSubscribed = _prefs.getBool(_kNoAdsSubscribedKey) ?? false;
  }

  static const String _kNoAdsSubscribedKey = 'no_ads_subscribed';

  final SharedPreferences _prefs;
  final SubscriptionService _service;

  bool _cachedNoAdsSubscribed = false;
  bool _initialized = false;
  bool _isLoading = false;
  bool _isProcessingPurchase = false;
  String? _error;

  List<SubscriptionPlan> _plans = const [];
  SubscriptionStatus? _status;

  List<SubscriptionPlan> get plans => _plans;
  SubscriptionStatus? get status => _status;
  UserSubscription? get activeSubscription => _status?.activeSubscription;

  bool get isLoading => _isLoading;
  bool get isProcessingPurchase => _isProcessingPurchase;
  String? get error => _error;

  bool get isInitialized => _initialized;

  bool get isNoAdsSubscribed {
    if (_status != null) {
      return _status!.isSubscribed ||
          (_status!.activeSubscription?.isActive ?? false);
    }
    return _cachedNoAdsSubscribed;
  }

  bool get shouldShowAds {
    if (isNoAdsSubscribed) return false;
    final backendShowAds = _status?.showAds;
    if (backendShowAds != null) return backendShowAds;
    return !_cachedNoAdsSubscribed;
  }

  String get monthlyPlanLabel {
    final monthly = _plans.firstWhere(
      (p) => p.planType.toUpperCase() == 'MONTHLY',
      orElse: () => _plans.isNotEmpty
          ? _plans.first
          : const SubscriptionPlan(
              id: 0,
              name: 'No Ads Plan',
              planType: 'MONTHLY',
              durationMonths: 1,
              price: 9,
              currency: 'INR',
              description: '',
              isActive: true,
            ),
    );

    final price = monthly.price.toStringAsFixed(
      monthly.price.truncateToDouble() == monthly.price ? 0 : 2,
    );
    return '$price ${monthly.currency}/month';
  }

  Future<void> initialize({bool forceRefresh = false}) async {
    if (_isLoading) return;
    if (_initialized && !forceRefresh) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait<dynamic>([
        _service.getPlans(),
        _service.getStatus(),
      ]);

      _plans = List<SubscriptionPlan>.from(
        results[0] as List<SubscriptionPlan>,
      );
      _status = results[1] as SubscriptionStatus;
      final resolvedSubscribed =
          _status?.isSubscribed == true ||
          (_status?.activeSubscription?.isActive ?? false);
      _cachedNoAdsSubscribed = resolvedSubscribed;
      await _prefs.setBool(_kNoAdsSubscribedKey, _cachedNoAdsSubscribed);
      _initialized = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshStatus() async {
    try {
      _status = await _service.getStatus();
      final resolvedSubscribed =
          _status?.isSubscribed == true ||
          (_status?.activeSubscription?.isActive ?? false);
      _cachedNoAdsSubscribed = resolvedSubscribed;
      await _prefs.setBool(_kNoAdsSubscribedKey, _cachedNoAdsSubscribed);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<UserSubscription> createSubscription({
    required int planId,
    bool autoRenew = true,
  }) async {
    _isProcessingPurchase = true;
    _error = null;
    notifyListeners();

    try {
      final subscription = await _service.subscribe(
        SubscribeRequest(planId: planId, autoRenew: autoRenew),
      );
      return subscription;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isProcessingPurchase = false;
      notifyListeners();
    }
  }

  Future<UserSubscription> verifyPayment(
    SubscriptionPaymentVerifyRequest request,
  ) async {
    _isProcessingPurchase = true;
    _error = null;
    notifyListeners();

    try {
      final verified = await _service.verifyPayment(request);
      await refreshStatus();
      return verified;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isProcessingPurchase = false;
      notifyListeners();
    }
  }

  void clearTransientError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  Future<void> resetForSignOut() async {
    _plans = const [];
    _status = null;
    _error = null;
    _isLoading = false;
    _isProcessingPurchase = false;
    _initialized = false;
    _cachedNoAdsSubscribed = false;
    await _prefs.remove(_kNoAdsSubscribedKey);
    notifyListeners();
  }

  Future<void> setNoAdsSubscribed(bool value) async {
    _cachedNoAdsSubscribed = value;
    await _prefs.setBool(_kNoAdsSubscribedKey, value);
    notifyListeners();
  }
}
