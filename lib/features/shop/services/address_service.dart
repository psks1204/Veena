import '../../../core/services/api_service.dart';
import '../models/address.dart';

/// Address Service
///
/// Wraps all /ecom/addresses endpoints (auth required).
class AddressService {
  final ApiService _api;
  AddressService(this._api);

  Future<List<AddressResponse>> getAddresses() async {
    final data = await _api.get('/ecom/addresses');
    final list = data is List ? data : (data['data'] as List<dynamic>? ?? []);
    return list
        .map((e) => AddressResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AddressResponse?> getAddress(int id) async {
    final data = await _api.get('/ecom/addresses/$id');
    final json = data is Map ? data : (data['data'] as Map<String, dynamic>);
    return AddressResponse.fromJson(json as Map<String, dynamic>);
  }

  Future<AddressResponse?> createAddress(AddressRequest request) async {
    final data = await _api.post('/ecom/addresses', body: request.toJson());
    final json = data is Map ? data : (data['data'] as Map<String, dynamic>);
    return AddressResponse.fromJson(json as Map<String, dynamic>);
  }

  Future<AddressResponse?> updateAddress(int id, AddressRequest request) async {
    final data = await _api.put('/ecom/addresses/$id', body: request.toJson());
    final json = data is Map ? data : (data['data'] as Map<String, dynamic>);
    return AddressResponse.fromJson(json as Map<String, dynamic>);
  }

  Future<bool> deleteAddress(int id) async {
    await _api.delete('/ecom/addresses/$id');
    return true;
  }
}
