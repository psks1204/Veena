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

  bool get isActive => status.toUpperCase() == 'ACTIVE';

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
