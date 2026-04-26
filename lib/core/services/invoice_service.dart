import '../models/invoice.dart';
import 'api_service.dart';

class InvoiceService {
  InvoiceService(this._api);

  final ApiService _api;

  Future<List<InvoiceResponse>> getMyInvoices() async {
    final data = await _api.get('/invoices');
    final list = _extractList(data);
    return list
        .map((e) => InvoiceResponse.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<InvoiceResponse> getInvoiceById(int id) async {
    final data = await _api.get('/invoices/$id');
    return InvoiceResponse.fromJson(_extractMap(data));
  }

  Future<InvoiceResponse> getOrderInvoice(int orderId) async {
    final data = await _api.get('/ecom/orders/$orderId/invoice');
    return InvoiceResponse.fromJson(_extractMap(data));
  }

  Future<InvoiceResponse> generateOrderInvoice(int orderId) async {
    final data = await _api.post(
      '/ecom/orders/$orderId/invoice/generate',
      body: {},
    );
    return InvoiceResponse.fromJson(_extractMap(data));
  }

  Future<InvoiceResponse> getSubscriptionInvoice(int subscriptionId) async {
    final data = await _api.get('/subscriptions/$subscriptionId/invoice');
    return InvoiceResponse.fromJson(_extractMap(data));
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
    throw StateError('Unexpected invoice payload type: ${data.runtimeType}');
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) {
      return List<dynamic>.from(data['data'] as List);
    }
    throw StateError(
      'Unexpected invoice list payload type: ${data.runtimeType}',
    );
  }
}
