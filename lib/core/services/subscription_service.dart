import '../models/subscription.dart';
import 'api_service.dart';

class SubscriptionService {
  SubscriptionService(this._api);

  final ApiService _api;

  Future<List<SubscriptionPlan>> getPlans() async {
    final data = await _api.get('/subscriptions/plans');
    final list = _extractList(data);
    return list
        .map((e) => SubscriptionPlan.fromJson(Map<String, dynamic>.from(e)))
        .where((plan) => plan.isActive)
        .toList();
  }

  Future<UserSubscription> subscribe(SubscribeRequest request) async {
    final data = await _api.post('/subscriptions/subscribe', body: request.toJson());
    final map = _extractMap(data);
    return UserSubscription.fromJson(map);
  }

  Future<UserSubscription> verifyPayment(
    SubscriptionPaymentVerifyRequest request,
  ) async {
    final data = await _api.post(
      '/subscriptions/verify-payment',
      body: request.toJson(),
    );
    final map = _extractMap(data);
    return UserSubscription.fromJson(map);
  }

  Future<SubscriptionStatus> getStatus() async {
    final data = await _api.get('/subscriptions/status');
    final map = _extractMap(data);
    return SubscriptionStatus.fromJson(map);
  }

  Future<List<UserSubscription>> getHistory() async {
    final data = await _api.get('/subscriptions/history');
    final list = _extractList(data);
    return list
        .map((e) => UserSubscription.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<UserSubscription> cancelSubscription(int id, {String? reason}) async {
    final data = await _api.post(
      '/subscriptions/$id/cancel',
      body: reason == null ? null : {'reason': reason},
    );
    final map = _extractMap(data);
    return UserSubscription.fromJson(map);
  }

  Map<String, dynamic> _extractMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['data'] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(data['data'] as Map<String, dynamic>);
      }
      return data;
    }
    if (data is Map && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    throw StateError('Unexpected API map payload type: ${data.runtimeType}');
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) {
      return List<dynamic>.from(data['data'] as List);
    }
    throw StateError('Unexpected API list payload type: ${data.runtimeType}');
  }
}
