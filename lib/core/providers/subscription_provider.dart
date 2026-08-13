import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/subscription.dart';
import '../services/ads_service.dart';
import '../services/api_service.dart';
import '../services/subscription_service.dart';

enum SubscriptionPaymentResolutionType {
  activated,
  activatedAfterStatusSync,
  activatedAfterReverify,

  /// Razorpay/the backend confirmed no money was taken for the order. The user
  /// is free (and expected) to start the payment again.
  paymentNotCompleted,

  /// We could not reach a verdict — usually a network failure while asking the
  /// backend. The order stays recoverable, and a retry is still allowed.
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
      type == SubscriptionPaymentResolutionType.activated ||
      type == SubscriptionPaymentResolutionType.activatedAfterStatusSync ||
      type == SubscriptionPaymentResolutionType.activatedAfterReverify;

  /// The order is definitively dead — starting a brand new checkout is the
  /// correct next step, and nothing is left to re-verify.
  bool get shouldRestartPayment =>
      type == SubscriptionPaymentResolutionType.paymentNotCompleted;

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

  factory SubscriptionPaymentResolution.paymentNotCompleted(String message) {
    return SubscriptionPaymentResolution._(
      type: SubscriptionPaymentResolutionType.paymentNotCompleted,
      message: message,
    );
  }
}

/// Result of asking the backend to re-check an order against Razorpay.
class _ReverifyOutcome {
  const _ReverifyOutcome({
    this.subscription,
    this.activated = false,
    this.answered = false,
    this.paymentMissing = false,
    this.error,
  });

  /// Whatever the backend returned, regardless of status.
  final UserSubscription? subscription;

  /// The subscription came back ACTIVE (or status sync says we are subscribed).
  final bool activated;

  /// The backend gave us a real verdict — as opposed to the call dying on
  /// transport or an error we cannot interpret.
  final bool answered;

  /// The backend positively established that no successful payment exists for
  /// the order.
  final bool paymentMissing;

  /// Set when the call itself failed for a reason we cannot interpret.
  final Object? error;

  /// Enough to conclude "not paid" for an order we hold no payment proof for.
  /// A plain "still PENDING" answer counts here, but not when we are holding a
  /// Razorpay payment id — see [SubscriptionProvider._shouldTreatAsUnpaid].
  bool get isUnpaidVerdict => !activated && (paymentMissing || answered);
}

class SubscriptionProvider extends ChangeNotifier {
  SubscriptionProvider(this._prefs, this._service) {
    _cachedNoAdsSubscribed = _prefs.getBool(_kNoAdsSubscribedKey) ?? false;
    _loadStatusFromCache();
    _loadPendingVerificationFromCache();
    // Apply the cached verdict before the first frame so a subscriber never
    // gets an interstitial in the window before the backend status lands.
    _syncAdsGate();
  }

  /// Keep the global ads switch aligned with the current subscription state.
  ///
  /// Widgets read [shouldShowAds] directly, but ads are also requested from
  /// non-widget code (interstitials on playback start), so the verdict has to
  /// live somewhere both can see.
  void _syncAdsGate() {
    AdsService.setAdsEnabled(shouldShowAds);
  }

  @override
  void notifyListeners() {
    _syncAdsGate();
    super.notifyListeners();
  }

  static const String _kNoAdsSubscribedKey = 'no_ads_subscribed';
  static const String _kStatusCacheKey = 'subscription_status_cache_v1';
  static const String _kStatusCacheTsKey = 'subscription_status_cache_ts_v1';
  static const String _kPendingVerificationKey =
      'subscription_pending_verification_v1';
  static const Duration _statusCacheTtl = Duration(minutes: 5);

  /// An order that never reached payment is worthless after a while — dropping
  /// it keeps stale records from resurfacing on the next app launch.
  static const Duration _unpaidOrderMaxAge = Duration(hours: 6);

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

  /// True only when we have real evidence that money moved but the
  /// subscription is not active yet.
  ///
  /// A merely created (and then abandoned) Razorpay order deliberately does not
  /// count — otherwise cancelling the checkout sheet would lock the user out of
  /// ever subscribing again.
  bool get hasPendingVerification {
    final pending = _pendingVerification;
    if (pending == null) return false;
    if (isNoAdsSubscribed) return false;
    return pending.hasPaymentProof;
  }

  /// Whether to offer the payment-recovery card.
  ///
  /// Wider than [hasPendingVerification]: it also covers an order whose status
  /// we simply could not establish (backend unreachable), so the user always
  /// has a way to ask "did my payment go through?" — while the subscribe button
  /// stays available regardless.
  bool get hasUnresolvedPayment {
    final pending = _pendingVerification;
    if (pending == null) return false;
    if (isNoAdsSubscribed) return false;
    return pending.hasPaymentProof || pending.lastError != null;
  }

  /// Starting a fresh checkout is always allowed unless the user is already
  /// subscribed or a call is in flight. Nothing about a stuck order may block
  /// this.
  bool get canStartNewPayment =>
      !isNoAdsSubscribed && !_isProcessingPurchase && _plans.isNotEmpty;

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

      // Only chase orders we believe were actually paid. Auto-retrying an
      // abandoned order just spams the backend with a guaranteed 400.
      if (hasPendingVerification) {
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
        PendingSubscriptionVerification.fromSubscription(
          subscription,
          // The checkout sheet has not even opened yet — no payment proof.
          stage: PendingPaymentStage.orderCreated,
        ).copyWith(planId: planId),
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

  /// The checkout sheet closed without a success callback — the user backed
  /// out, the payment failed, or the sheet crashed.
  ///
  /// We never take the client's word for it: the backend is asked whether a
  /// payment landed on the order before deciding what to tell the user. That
  /// covers the rare case where money was taken but the SDK reported an error.
  Future<SubscriptionPaymentResolution> resolveAbandonedCheckout({
    required int subscriptionId,
    bool cancelledByUser = true,
    String? failureMessage,
  }) async {
    _isRecoveringPendingVerification = true;
    notifyListeners();

    try {
      final pending = _pendingVerification;
      final outcome = await _reverify(subscriptionId);

      if (outcome.activated) {
        await _clearPendingVerification(emit: false);
        _error = null;
        return SubscriptionPaymentResolution.activated(
          'Payment went through. Your subscription is now active.',
          subscription: outcome.subscription ?? activeSubscription,
          type: SubscriptionPaymentResolutionType.activatedAfterReverify,
        );
      }

      final statusRecovered = await _resolveActivationFromStatus();
      if (statusRecovered != null) {
        await _clearPendingVerification(emit: false);
        _error = null;
        return SubscriptionPaymentResolution.activated(
          'Payment went through. Your subscription is now active.',
          subscription: statusRecovered,
          type: SubscriptionPaymentResolutionType.activatedAfterStatusSync,
        );
      }

      if (_shouldTreatAsUnpaid(outcome, pending)) {
        // Confirmed: no money was taken. Drop the dead order so the user can
        // subscribe again straight away.
        await _clearPendingVerification(emit: false);
        _error = null;
        return SubscriptionPaymentResolution.paymentNotCompleted(
          cancelledByUser
              ? 'Payment cancelled. You have not been charged — tap Subscribe Now to try again.'
              : 'Payment failed${_suffix(failureMessage)} You have not been charged — please try again.',
        );
      }

      // Verdict still unknown. Keep the order so the user can check again
      // later — but the subscribe button stays open either way.
      await _markPendingVerificationFailure(
        outcome.error?.toString() ?? 'Unknown verification error.',
        emit: false,
      );
      _error = null;
      return SubscriptionPaymentResolution.pending(
        _inconclusiveMessage(outcome),
      );
    } finally {
      _isRecoveringPendingVerification = false;
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

        final outcome = await _reverify(request.subscriptionId);
        if (outcome.activated) {
          await _clearPendingVerification(emit: false);
          return SubscriptionPaymentResolution.activated(
            'Subscription activated after re-verification.',
            subscription: outcome.subscription ?? activeSubscription,
            type: SubscriptionPaymentResolutionType.activatedAfterReverify,
          );
        }

        if (outcome.paymentMissing) {
          return _resolveAsUnpaid();
        }

        await _markPendingVerificationFailure(
          verifyError.toString(),
          emit: false,
        );
        _error =
            'Payment appears successful, but verification is still pending.';
        return SubscriptionPaymentResolution.pending(
          'Payment received. Verification is pending — tap Check Payment Status.',
        );
      }

      final outcome = await _reverify(request.subscriptionId);
      if (outcome.activated) {
        await _clearPendingVerification(emit: false);
        return SubscriptionPaymentResolution.activated(
          'Subscription activated after re-verification.',
          subscription: outcome.subscription ?? activeSubscription,
          type: SubscriptionPaymentResolutionType.activatedAfterReverify,
        );
      }

      if (outcome.paymentMissing) {
        return _resolveAsUnpaid();
      }

      await _markPendingVerificationFailure(
        'Verification pending after payment success.',
        emit: false,
      );
      _error = 'Payment captured, verification is pending.';
      return SubscriptionPaymentResolution.pending(
        'Payment received. Verification is pending — tap Check Payment Status.',
      );
    } finally {
      _isProcessingPurchase = false;
      notifyListeners();
    }
  }

  /// Ask the backend whether the pending order was actually paid.
  ///
  /// This is the "did my payment go through?" action. Crucially, a backend
  /// verdict of *no payment on this order* clears the pending record instead of
  /// leaving the user stuck retrying an order that can never succeed.
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
    }
    notifyListeners();

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
        return SubscriptionPaymentResolution.paymentNotCompleted(
          'No pending payment was found. You can start a new subscription.',
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

      final outcome = await _reverify(pending.subscriptionId);
      if (outcome.activated) {
        await _clearPendingVerification(emit: false);
        _error = null;
        return SubscriptionPaymentResolution.activated(
          'Payment confirmed. Your subscription is now active.',
          subscription: outcome.subscription ?? activeSubscription,
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

      if (_shouldTreatAsUnpaid(outcome, pending)) {
        return _resolveAsUnpaid();
      }

      await _markPendingVerificationFailure(
        outcome.error?.toString() ?? 'Still pending after re-verification.',
        emit: false,
      );
      _error = null;
      return SubscriptionPaymentResolution.pending(
        _inconclusiveMessage(outcome),
      );
    } finally {
      _isRecoveringPendingVerification = false;
      notifyListeners();
    }
  }

  /// Wording for the case where we still cannot say whether money moved.
  static String _inconclusiveMessage(_ReverifyOutcome outcome) {
    return outcome.answered
        ? 'Your payment is still being confirmed by the bank. Please check again in a few minutes.'
        : "Couldn't reach the payment server. Please check again in a moment, or start the payment again.";
  }

  /// Forget the stuck order without asking the backend. Used when the user
  /// explicitly chooses to start over.
  Future<void> discardPendingPayment() async {
    if (_pendingVerification == null) return;
    await _clearPendingVerification(emit: false);
    _error = null;
    notifyListeners();
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

      // An order that never got a payment and has been sitting for hours is
      // just litter — drop it rather than let it haunt the next session.
      if (!pending.hasPaymentProof && pending.isOlderThan(_unpaidOrderMaxAge)) {
        unawaited(_prefs.remove(_kPendingVerificationKey));
        return;
      }
      _pendingVerification = pending;
    } catch (_) {
      _pendingVerification = null;
      unawaited(_prefs.remove(_kPendingVerificationKey));
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

  Future<SubscriptionPaymentResolution> _resolveAsUnpaid() async {
    await _clearPendingVerification(emit: false);
    _error = null;
    return SubscriptionPaymentResolution.paymentNotCompleted(
      'No payment was received for this order. Please start the payment again.',
    );
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
              // Razorpay handed us a payment id, so money is in play.
              stage: PendingPaymentStage.paymentCaptured,
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

  Future<_ReverifyOutcome> _reverify(int subscriptionId) async {
    if (subscriptionId <= 0) {
      return const _ReverifyOutcome(answered: true, paymentMissing: true);
    }

    try {
      final reverified = await _service.reverifyPayment(subscriptionId);
      await refreshStatus(forceRemote: true);

      if (reverified.isActive || isNoAdsSubscribed) {
        return _ReverifyOutcome(
          subscription: reverified,
          activated: true,
          answered: true,
        );
      }

      // A terminal status is a definitive "no successful payment". A row that
      // is merely still PENDING is not — money may be in flight.
      return _ReverifyOutcome(
        subscription: reverified,
        answered: true,
        paymentMissing: reverified.isPaymentFailed || reverified.isCancelled,
      );
    } catch (e) {
      if (_isNoPaymentOnOrderError(e)) {
        return _ReverifyOutcome(answered: true, paymentMissing: true, error: e);
      }
      if (_isDefiniteRejection(e)) {
        // The backend refused outright (e.g. the order is no longer in a
        // verifiable state). That is an answer, not a transient glitch, so an
        // order with no payment proof can be retired instead of retried.
        return _ReverifyOutcome(answered: true, error: e);
      }
      return _ReverifyOutcome(error: e);
    }
  }

  /// A 4xx that is neither an auth problem nor rate limiting: the backend has
  /// made up its mind about this order.
  static bool _isDefiniteRejection(Object error) {
    if (error is! ApiException) return false;
    final code = error.statusCode;
    if (code < 400 || code >= 500) return false;
    return code != 401 && code != 403 && code != 408 && code != 429;
  }

  /// Whether an unsuccessful re-verify means the order is dead.
  ///
  /// When we hold a Razorpay payment id, only an explicit backend verdict
  /// counts — we must not throw away a real payment just because the backend
  /// has not caught up yet.
  bool _shouldTreatAsUnpaid(
    _ReverifyOutcome outcome,
    PendingSubscriptionVerification? pending,
  ) {
    if (outcome.activated) return false;
    if (pending?.hasPaymentProof ?? false) return outcome.paymentMissing;
    return outcome.isUnpaidVerdict;
  }

  /// Recognises the backend's "this order was never paid" rejection.
  ///
  /// Example: `400 {"message": "No payment found for this order on Razorpay.
  /// Please retry payment."}`. Treating it as a hard verdict — rather than one
  /// more failed retry — is what stops the user being stuck forever.
  static bool _isNoPaymentOnOrderError(Object error) {
    if (error is ApiException) {
      final isClientError = error.statusCode >= 400 && error.statusCode < 500;
      if (!isClientError || error.statusCode == 401) return false;
    }

    final text = error.toString().toLowerCase();
    const markers = [
      'no payment found',
      'no payment was found',
      'payment not found',
      'no payment exists',
      'retry payment',
      'not paid',
    ];
    return markers.any(text.contains);
  }

  static String _suffix(String? message) {
    final trimmed = message?.trim();
    if (trimmed == null || trimmed.isEmpty) return '.';
    return ': $trimmed.';
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

      // Stage is derived from whether the row carries a Razorpay payment id, so
      // an abandoned order discovered here will not start blocking the UI.
      final pending = PendingSubscriptionVerification.fromSubscription(latest);
      await _storePendingVerification(pending, emit: false);
      return pending;
    } catch (_) {
      return null;
    }
  }
}
