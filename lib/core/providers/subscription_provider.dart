import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/subscription.dart';
import '../services/subscription_service.dart';

enum SubscriptionPaymentResolutionType {
  activated,
  activatedAfterStatusSync,
  activatedAfterReverify,
  pendingVerification,
}

class SubscriptionPaymentResolution {
  const SubscriptionPaymentResolution._({
    required this.type,
    required this.message,
    this.subscription,
  });

  final SubscriptionPaymentResolutionType type;
  final String message;
  final UserSubscription? subscription;

  bool get isActivated =>
      type != SubscriptionPaymentResolutionType.pendingVerification;

  factory SubscriptionPaymentResolution.activated(
    String message, {
    UserSubscription? subscription,
    SubscriptionPaymentResolutionType type =
        SubscriptionPaymentResolutionType.activated,
  }) {
    return SubscriptionPaymentResolution._(
      type: type,
      message: message,
      subscription: subscription,
    );
  }

  factory SubscriptionPaymentResolution.pending(
    String message, {
    UserSubscription? subscription,
  }) {
    return SubscriptionPaymentResolution._(
      type: SubscriptionPaymentResolutionType.pendingVerification,
      message: message,
      subscription: subscription,
    );
  }
}

class SubscriptionProvider extends ChangeNotifier {
  SubscriptionProvider(this._prefs, this._service) {
    _cachedNoAdsSubscribed = _prefs.getBool(_kNoAdsSubscribedKey) ?? false;
    _loadStatusFromCache();
    _loadPendingVerificationFromCache();
  }

  static const String _kNoAdsSubscribedKey = 'no_ads_subscribed';
  static const String _kStatusCacheKey = 'subscription_status_cache_v1';
  static const String _kStatusCacheTsKey = 'subscription_status_cache_ts_v1';
  static const String _kPendingVerificationKey =
      'subscription_pending_verification_v1';
  static const Duration _statusCacheTtl = Duration(minutes: 5);

  final SharedPreferences _prefs;
  final SubscriptionService _service;

  bool _cachedNoAdsSubscribed = false;
  bool _initialized = false;
  bool _isLoading = false;
  bool _isProcessingPurchase = false;
  bool _isRecoveringPendingVerification = false;
  String? _error;

  List<SubscriptionPlan> _plans = const [];
  SubscriptionStatus? _status;
  PendingSubscriptionVerification? _pendingVerification;
  DateTime? _statusFetchedAt;

  List<SubscriptionPlan> get plans => _plans;
  SubscriptionStatus? get status => _status;
  UserSubscription? get activeSubscription => _status?.activeSubscription;
  PendingSubscriptionVerification? get pendingVerification =>
      _pendingVerification;

  bool get isLoading => _isLoading;
  bool get isProcessingPurchase => _isProcessingPurchase;
  bool get isRecoveringPendingVerification => _isRecoveringPendingVerification;
  String? get error => _error;

  bool get isInitialized => _initialized;
  bool get hasPendingVerification => _pendingVerification != null;

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
      _plans = await _service.getPlans();

      final shouldRefreshRemote = forceRefresh || !_isStatusCacheFresh;
      if (shouldRefreshRemote) {
        await _fetchRemoteStatusAndPersist();
      } else {
        await _syncCachedSubscriptionFlag();
      }

      _initialized = true;

      if (_pendingVerification != null && !isNoAdsSubscribed) {
        unawaited(reverifyPendingPayment(userInitiated: false));
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshStatus({bool forceRemote = true}) async {
    try {
      final shouldUseCache =
          !forceRemote && _status != null && _isStatusCacheFresh;
      if (shouldUseCache) {
        await _syncCachedSubscriptionFlag();
      } else {
        await _fetchRemoteStatusAndPersist();
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<UserSubscription> createSubscription({required int planId}) async {
    _isProcessingPurchase = true;
    _error = null;
    notifyListeners();

    try {
      // Auto-renew remains enabled by default until user cancels manually.
      final subscription = await _service.subscribe(
        SubscribeRequest(planId: planId, autoRenew: true),
      );
      await _storePendingVerification(
        PendingSubscriptionVerification.fromSubscription(subscription),
        emit: false,
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

  Future<SubscriptionPaymentResolution> completePendingPayment(
    SubscriptionPaymentVerifyRequest request,
  ) async {
    _isProcessingPurchase = true;
    _error = null;
    notifyListeners();

    try {
      await _attachPaymentProofToPending(request, emit: false);

      try {
        final verified = await _service.verifyPayment(request);
        await refreshStatus(forceRemote: true);

        if (verified.isActive || isNoAdsSubscribed) {
          await _clearPendingVerification(emit: false);
          return SubscriptionPaymentResolution.activated(
            'Subscription activated successfully.',
            subscription: verified,
          );
        }
      } catch (verifyError) {
        final statusRecovered = await _resolveActivationFromStatus();
        if (statusRecovered != null) {
          await _clearPendingVerification(emit: false);
          return SubscriptionPaymentResolution.activated(
            'Subscription activated successfully.',
            subscription: statusRecovered,
            type: SubscriptionPaymentResolutionType.activatedAfterStatusSync,
          );
        }

        final reverified = await _tryReverifyBySubscriptionId(
          request.subscriptionId,
          recordFailure: false,
        );
        if (reverified != null && (reverified.isActive || isNoAdsSubscribed)) {
          await _clearPendingVerification(emit: false);
          return SubscriptionPaymentResolution.activated(
            'Subscription activated after re-verification.',
            subscription: reverified,
            type: SubscriptionPaymentResolutionType.activatedAfterReverify,
          );
        }

        await _markPendingVerificationFailure(
          verifyError.toString(),
          emit: false,
        );
        _error =
            'Payment appears successful, but verification is still pending.';
        return SubscriptionPaymentResolution.pending(
          'Payment received. Verification is pending. Please tap Re-verify.',
        );
      }

      final reverified = await _tryReverifyBySubscriptionId(
        request.subscriptionId,
      );
      if (reverified != null && (reverified.isActive || isNoAdsSubscribed)) {
        await _clearPendingVerification(emit: false);
        return SubscriptionPaymentResolution.activated(
          'Subscription activated after re-verification.',
          subscription: reverified,
          type: SubscriptionPaymentResolutionType.activatedAfterReverify,
        );
      }

      await _markPendingVerificationFailure(
        'Verification pending after payment success.',
        emit: false,
      );
      _error = 'Payment captured, verification is pending.';
      return SubscriptionPaymentResolution.pending(
        'Payment received. Verification is pending. Please tap Re-verify.',
      );
    } finally {
      _isProcessingPurchase = false;
      notifyListeners();
    }
  }

  Future<SubscriptionPaymentResolution> reverifyPendingPayment({
    bool userInitiated = true,
  }) async {
    if (_isRecoveringPendingVerification) {
      return SubscriptionPaymentResolution.pending(
        'Verification is already in progress.',
      );
    }

    _isRecoveringPendingVerification = true;
    if (userInitiated) {
      _error = null;
      notifyListeners();
    }

    try {
      PendingSubscriptionVerification? pending = _pendingVerification;
      pending ??= await _discoverLatestPendingFromHistory();

      if (pending == null) {
        await refreshStatus(forceRemote: true);
        if (isNoAdsSubscribed) {
          return SubscriptionPaymentResolution.activated(
            'Subscription is already active.',
            subscription: activeSubscription,
            type: SubscriptionPaymentResolutionType.activatedAfterStatusSync,
          );
        }
        return SubscriptionPaymentResolution.pending(
          'No pending subscription payment was found.',
        );
      }

      await _storePendingVerification(
        pending.copyWith(
          updatedAt: DateTime.now(),
          attemptCount: pending.attemptCount + 1,
          clearLastError: true,
        ),
        emit: false,
      );

      final reverified = await _tryReverifyBySubscriptionId(
        pending.subscriptionId,
      );
      if (reverified != null && (reverified.isActive || isNoAdsSubscribed)) {
        await _clearPendingVerification(emit: false);
        _error = null;
        return SubscriptionPaymentResolution.activated(
          'Subscription activated after re-verification.',
          subscription: reverified,
          type: SubscriptionPaymentResolutionType.activatedAfterReverify,
        );
      }

      final statusRecovered = await _resolveActivationFromStatus();
      if (statusRecovered != null) {
        await _clearPendingVerification(emit: false);
        _error = null;
        return SubscriptionPaymentResolution.activated(
          'Subscription activated successfully.',
          subscription: statusRecovered,
          type: SubscriptionPaymentResolutionType.activatedAfterStatusSync,
        );
      }

      await _markPendingVerificationFailure(
        'Still pending after re-verification attempt.',
        emit: false,
      );
      _error = 'Payment verification is still pending.';
      return SubscriptionPaymentResolution.pending(
        'Still waiting for payment confirmation. Please try Re-verify again shortly.',
      );
    } finally {
      _isRecoveringPendingVerification = false;
      notifyListeners();
    }
  }

  Future<bool> cancelCurrentSubscription({String? reason}) async {
    final active = activeSubscription;
    if (active == null) {
      _error = 'No active subscription to cancel.';
      notifyListeners();
      return false;
    }

    _isProcessingPurchase = true;
    _error = null;
    notifyListeners();

    try {
      await _service.cancelSubscription(active.id, reason: reason);
      await refreshStatus(forceRemote: true);
      _error = null;
      return true;
    } catch (e) {
      _error = 'Failed to cancel subscription: $e';
      return false;
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
    _pendingVerification = null;
    _statusFetchedAt = null;
    _error = null;
    _isLoading = false;
    _isProcessingPurchase = false;
    _isRecoveringPendingVerification = false;
    _initialized = false;
    _cachedNoAdsSubscribed = false;

    await _prefs.remove(_kNoAdsSubscribedKey);
    await _prefs.remove(_kStatusCacheKey);
    await _prefs.remove(_kStatusCacheTsKey);
    await _prefs.remove(_kPendingVerificationKey);
    notifyListeners();
  }

  Future<void> setNoAdsSubscribed(bool value) async {
    _cachedNoAdsSubscribed = value;
    await _prefs.setBool(_kNoAdsSubscribedKey, value);
    notifyListeners();
  }

  bool get _isStatusCacheFresh {
    final ts = _prefs.getInt(_kStatusCacheTsKey);
    if (ts == null) return false;
    final age = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(ts),
    );
    return age <= _statusCacheTtl;
  }

  void _loadStatusFromCache() {
    final raw = _prefs.getString(_kStatusCacheKey);
    final ts = _prefs.getInt(_kStatusCacheTsKey);
    if (raw == null || ts == null) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;

      _status = SubscriptionStatus.fromJson(Map<String, dynamic>.from(decoded));
      _statusFetchedAt = DateTime.fromMillisecondsSinceEpoch(ts);
      final resolvedSubscribed =
          _status?.isSubscribed == true ||
          (_status?.activeSubscription?.isActive ?? false);
      _cachedNoAdsSubscribed = resolvedSubscribed;
    } catch (_) {
      _status = null;
      _statusFetchedAt = null;
    }
  }

  void _loadPendingVerificationFromCache() {
    final raw = _prefs.getString(_kPendingVerificationKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final pending = PendingSubscriptionVerification.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      if (pending.subscriptionId <= 0) return;
      _pendingVerification = pending;
    } catch (_) {
      _pendingVerification = null;
    }
  }

  Future<void> _fetchRemoteStatusAndPersist() async {
    _status = await _service.getStatus();
    _statusFetchedAt = DateTime.now();

    await _prefs.setString(_kStatusCacheKey, jsonEncode(_status!.toJson()));
    await _prefs.setInt(
      _kStatusCacheTsKey,
      _statusFetchedAt!.millisecondsSinceEpoch,
    );
    await _syncCachedSubscriptionFlag();

    if (isNoAdsSubscribed) {
      await _clearPendingVerification(emit: false);
    }
  }

  Future<void> _syncCachedSubscriptionFlag() async {
    final resolvedSubscribed =
        _status?.isSubscribed == true ||
        (_status?.activeSubscription?.isActive ?? false);
    _cachedNoAdsSubscribed = resolvedSubscribed;
    await _prefs.setBool(_kNoAdsSubscribedKey, _cachedNoAdsSubscribed);
  }

  Future<void> _storePendingVerification(
    PendingSubscriptionVerification pending, {
    bool emit = true,
  }) async {
    _pendingVerification = pending;
    await _prefs.setString(
      _kPendingVerificationKey,
      jsonEncode(pending.toJson()),
    );
    if (emit) notifyListeners();
  }

  Future<void> _clearPendingVerification({bool emit = true}) async {
    _pendingVerification = null;
    await _prefs.remove(_kPendingVerificationKey);
    if (emit) notifyListeners();
  }

  Future<void> _attachPaymentProofToPending(
    SubscriptionPaymentVerifyRequest request, {
    bool emit = true,
  }) async {
    final now = DateTime.now();
    final existing = _pendingVerification;

    final next =
        (existing ??
                PendingSubscriptionVerification(
                  subscriptionId: request.subscriptionId,
                  createdAt: now,
                  updatedAt: now,
                ))
            .copyWith(
              subscriptionId: request.subscriptionId,
              razorpayOrderId: request.razorpayOrderId,
              razorpayPaymentId: request.razorpayPaymentId,
              razorpaySignature: request.razorpaySignature,
              updatedAt: now,
              clearLastError: true,
            );

    await _storePendingVerification(next, emit: emit);
  }

  Future<void> _markPendingVerificationFailure(
    String message, {
    bool emit = true,
  }) async {
    final pending = _pendingVerification;
    if (pending == null) return;

    await _storePendingVerification(
      pending.copyWith(updatedAt: DateTime.now(), lastError: message),
      emit: emit,
    );
  }

  Future<UserSubscription?> _resolveActivationFromStatus() async {
    try {
      await _fetchRemoteStatusAndPersist();
      if (isNoAdsSubscribed) {
        return activeSubscription;
      }
    } catch (_) {}
    return null;
  }

  Future<UserSubscription?> _tryReverifyBySubscriptionId(
    int subscriptionId, {
    bool recordFailure = true,
  }) async {
    try {
      final reverified = await _service.reverifyPayment(subscriptionId);
      await refreshStatus(forceRemote: true);
      if (reverified.isActive || isNoAdsSubscribed) {
        return reverified;
      }
      return null;
    } catch (e) {
      if (recordFailure) {
        await _markPendingVerificationFailure(e.toString(), emit: false);
      }
      return null;
    }
  }

  Future<PendingSubscriptionVerification?>
  _discoverLatestPendingFromHistory() async {
    try {
      final history = await _service.getHistory();
      final pendingSubscriptions = history
          .where((item) => item.isPending)
          .toList(growable: false);
      if (pendingSubscriptions.isEmpty) return null;

      UserSubscription latest = pendingSubscriptions.first;
      for (final subscription in pendingSubscriptions.skip(1)) {
        final candidateTime =
            subscription.updatedAt ?? subscription.createdAt ?? DateTime(1970);
        final latestTime =
            latest.updatedAt ?? latest.createdAt ?? DateTime(1970);
        if (candidateTime.isAfter(latestTime)) {
          latest = subscription;
        }
      }

      final pending = PendingSubscriptionVerification.fromSubscription(latest);
      await _storePendingVerification(pending, emit: false);
      return pending;
    } catch (_) {
      return null;
    }
  }
}
