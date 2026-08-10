class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.planType,
    required this.durationMonths,
    required this.price,
    required this.currency,
    required this.description,
    required this.isActive,
  });

  final int id;
  final String name;
  final String planType;
  final int durationMonths;
  final double price;
  final String currency;
  final String description;
  final bool isActive;

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      planType: json['planType'] as String? ?? 'MONTHLY',
      durationMonths: (json['durationMonths'] as num?)?.toInt() ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      description: json['description'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class SubscribeRequest {
  const SubscribeRequest({required this.planId, this.autoRenew = true});

  final int planId;
  final bool autoRenew;

  Map<String, dynamic> toJson() {
    return {'planId': planId, 'autoRenew': autoRenew};
  }
}

class SubscriptionPaymentVerifyRequest {
  const SubscriptionPaymentVerifyRequest({
    required this.subscriptionId,
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.razorpaySignature,
  });

  final int subscriptionId;
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String razorpaySignature;

  Map<String, dynamic> toJson() {
    return {
      'subscriptionId': subscriptionId,
      'razorpayOrderId': razorpayOrderId,
      'razorpayPaymentId': razorpayPaymentId,
      'razorpaySignature': razorpaySignature,
    };
  }
}

class SubscriptionPlanSnapshot {
  const SubscriptionPlanSnapshot({
    required this.id,
    required this.name,
    required this.planType,
    required this.durationMonths,
    required this.price,
    required this.currency,
  });

  final int id;
  final String name;
  final String planType;
  final int durationMonths;
  final double price;
  final String currency;

  factory SubscriptionPlanSnapshot.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanSnapshot(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      planType: json['planType'] as String? ?? 'MONTHLY',
      durationMonths: (json['durationMonths'] as num?)?.toInt() ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'INR',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'planType': planType,
      'durationMonths': durationMonths,
      'price': price,
      'currency': currency,
    };
  }
}

class UserSubscription {
  const UserSubscription({
    required this.id,
    required this.status,
    required this.autoRenew,
    required this.plan,
    this.userId,
    this.userName,
    this.userEmail,
    this.startDate,
    this.endDate,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.paymentAmount,
    this.paymentCurrency,
    this.cancelledAt,
    this.cancelReason,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String status;
  final bool autoRenew;
  final SubscriptionPlanSnapshot plan;
  final String? userId;
  final String? userName;
  final String? userEmail;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final double? paymentAmount;
  final String? paymentCurrency;
  final DateTime? cancelledAt;
  final String? cancelReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get normalizedStatus => status.trim().toUpperCase();
  bool get isActive => normalizedStatus == 'ACTIVE';
  bool get isPending => normalizedStatus == 'PENDING';
  bool get isCancelled => normalizedStatus == 'CANCELLED';
  bool get isExpired => normalizedStatus == 'EXPIRED';
  bool get isPaymentFailed => normalizedStatus == 'PAYMENT_FAILED';

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: (json['id'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'PENDING',
      autoRenew: json['autoRenew'] as bool? ?? false,
      plan: SubscriptionPlanSnapshot.fromJson(
        Map<String, dynamic>.from(json['plan'] as Map? ?? {}),
      ),
      userId: json['userId']?.toString(),
      userName: json['userName'] as String?,
      userEmail: json['userEmail'] as String?,
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      razorpayOrderId: json['razorpayOrderId'] as String?,
      razorpayPaymentId: json['razorpayPaymentId'] as String?,
      paymentAmount: (json['paymentAmount'] as num?)?.toDouble(),
      paymentCurrency: json['paymentCurrency'] as String?,
      cancelledAt: _parseDate(json['cancelledAt']),
      cancelReason: json['cancelReason'] as String?,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'autoRenew': autoRenew,
      'plan': plan.toJson(),
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'razorpayOrderId': razorpayOrderId,
      'razorpayPaymentId': razorpayPaymentId,
      'paymentAmount': paymentAmount,
      'paymentCurrency': paymentCurrency,
      'cancelledAt': cancelledAt?.toIso8601String(),
      'cancelReason': cancelReason,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class SubscriptionStatus {
  const SubscriptionStatus({
    required this.isSubscribed,
    required this.showAds,
    this.activeSubscription,
  });

  final bool isSubscribed;
  final bool showAds;
  final UserSubscription? activeSubscription;

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    final rawActive = json['activeSubscription'];
    final activeSubscription = rawActive is Map
        ? UserSubscription.fromJson(Map<String, dynamic>.from(rawActive))
        : null;

    final parsedSubscribed = _readBool(json, const [
      'isSubscribed',
      'subscribed',
      'hasSubscription',
      'noAdsSubscribed',
      'is_subscribed',
      'has_subscription',
    ]);
    final resolvedSubscribed =
        parsedSubscribed ?? (activeSubscription?.isActive ?? false);

    final parsedShowAds = _readBool(json, const [
      'showAds',
      'adsEnabled',
      'show_ads',
      'ads_enabled',
    ]);
    final resolvedShowAds = parsedShowAds ?? !resolvedSubscribed;

    return SubscriptionStatus(
      isSubscribed: resolvedSubscribed,
      showAds: resolvedShowAds,
      activeSubscription: activeSubscription,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isSubscribed': isSubscribed,
      'showAds': showAds,
      'activeSubscription': activeSubscription?.toJson(),
    };
  }

  static bool? _readBool(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (!json.containsKey(key)) continue;

      final raw = json[key];
      if (raw is bool) return raw;
      if (raw is num) return raw != 0;
      if (raw is String) {
        final normalized = raw.trim().toLowerCase();
        if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
          return true;
        }
        if (normalized == 'false' || normalized == '0' || normalized == 'no') {
          return false;
        }
      }
    }
    return null;
  }
}

/// How far a pending subscription order actually got.
///
/// The distinction matters: an order that was created but never paid must not
/// block the user from starting a fresh checkout, while an order the payment
/// gateway confirmed money for has to keep nagging until it is verified.
enum PendingPaymentStage {
  /// `/subscribe` created a Razorpay order. No payment proof exists yet, so the
  /// user may simply have cancelled the checkout sheet.
  orderCreated,

  /// Razorpay reported a captured payment (or the backend told us one exists)
  /// but the subscription is not ACTIVE yet.
  paymentCaptured,
}

class PendingSubscriptionVerification {
  const PendingSubscriptionVerification({
    required this.subscriptionId,
    this.planId,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.razorpaySignature,
    required this.createdAt,
    required this.updatedAt,
    this.lastError,
    this.attemptCount = 0,
    this.stage = PendingPaymentStage.orderCreated,
  });

  final int subscriptionId;
  final int? planId;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final String? razorpaySignature;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastError;
  final int attemptCount;
  final PendingPaymentStage stage;

  /// Only a captured payment justifies showing the "verification pending"
  /// banner — anything else is just an abandoned order.
  bool get hasPaymentProof => stage == PendingPaymentStage.paymentCaptured;

  bool isOlderThan(Duration duration) =>
      DateTime.now().difference(createdAt) > duration;

  factory PendingSubscriptionVerification.fromSubscription(
    UserSubscription subscription, {
    PendingPaymentStage? stage,
  }) {
    final now = DateTime.now();
    final paymentId = subscription.razorpayPaymentId;
    return PendingSubscriptionVerification(
      subscriptionId: subscription.id,
      planId: subscription.plan.id == 0 ? null : subscription.plan.id,
      razorpayOrderId: subscription.razorpayOrderId,
      razorpayPaymentId: paymentId,
      createdAt: subscription.createdAt ?? now,
      updatedAt: now,
      stage:
          stage ??
          (paymentId != null && paymentId.isNotEmpty
              ? PendingPaymentStage.paymentCaptured
              : PendingPaymentStage.orderCreated),
    );
  }

  factory PendingSubscriptionVerification.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return PendingSubscriptionVerification(
      subscriptionId: (json['subscriptionId'] as num?)?.toInt() ?? 0,
      planId: (json['planId'] as num?)?.toInt(),
      razorpayOrderId: json['razorpayOrderId'] as String?,
      razorpayPaymentId: json['razorpayPaymentId'] as String?,
      razorpaySignature: json['razorpaySignature'] as String?,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? now,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? now,
      lastError: json['lastError'] as String?,
      attemptCount: (json['attemptCount'] as num?)?.toInt() ?? 0,
      stage: _parseStage(json['stage']),
    );
  }

  static PendingPaymentStage _parseStage(dynamic raw) {
    final value = raw?.toString();
    for (final stage in PendingPaymentStage.values) {
      if (stage.name == value) return stage;
    }
    return PendingPaymentStage.orderCreated;
  }

  PendingSubscriptionVerification copyWith({
    int? subscriptionId,
    int? planId,
    String? razorpayOrderId,
    String? razorpayPaymentId,
    String? razorpaySignature,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastError,
    bool clearLastError = false,
    int? attemptCount,
    PendingPaymentStage? stage,
  }) {
    return PendingSubscriptionVerification(
      subscriptionId: subscriptionId ?? this.subscriptionId,
      planId: planId ?? this.planId,
      razorpayOrderId: razorpayOrderId ?? this.razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId ?? this.razorpayPaymentId,
      razorpaySignature: razorpaySignature ?? this.razorpaySignature,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      attemptCount: attemptCount ?? this.attemptCount,
      stage: stage ?? this.stage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subscriptionId': subscriptionId,
      'planId': planId,
      'razorpayOrderId': razorpayOrderId,
      'razorpayPaymentId': razorpayPaymentId,
      'razorpaySignature': razorpaySignature,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastError': lastError,
      'attemptCount': attemptCount,
      'stage': stage.name,
    };
  }
}
