import 'package:flutter/foundation.dart';
import '../models/address.dart';
import '../services/address_service.dart';

/// Address Provider
///
/// Manages saved delivery addresses.
class AddressProvider extends ChangeNotifier {
  final AddressService _service;

  AddressProvider(this._service);

  List<AddressResponse> _addresses = [];
  bool _isLoading = false;
  String? _error;

  List<AddressResponse> get addresses => _addresses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AddressResponse? get defaultAddress {
    if (_addresses.isEmpty) return null;
    final defaults = _addresses.where((a) => a.isDefault);
    return defaults.isNotEmpty ? defaults.first : _addresses.first;
  }

  Future<void> loadAddresses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _addresses = await _service.getAddresses();
    } catch (e) {
      _error = 'Failed to load addresses';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AddressResponse?> createAddress(AddressRequest request) async {
    _error = null;
    try {
      final addr = await _service.createAddress(request);
      if (addr != null) {
        if (addr.isDefault) {
          _addresses = _addresses
              .map(
                (a) => AddressResponse(
                  id: a.id,
                  fullName: a.fullName,
                  phone: a.phone,
                  addressLine1: a.addressLine1,
                  addressLine2: a.addressLine2,
                  city: a.city,
                  state: a.state,
                  pincode: a.pincode,
                  country: a.country,
                  isDefault: false,
                  createdAt: a.createdAt,
                ),
              )
              .toList();
        }
        _addresses.insert(0, addr);
        notifyListeners();
      }
      return addr;
    } catch (e) {
      _error = 'Failed to save address';
      notifyListeners();
      return null;
    }
  }

  Future<AddressResponse?> updateAddress(int id, AddressRequest request) async {
    _error = null;
    try {
      final addr = await _service.updateAddress(id, request);
      if (addr != null) {
        final idx = _addresses.indexWhere((a) => a.id == id);
        if (addr.isDefault) {
          _addresses = _addresses
              .map(
                (a) => AddressResponse(
                  id: a.id,
                  fullName: a.fullName,
                  phone: a.phone,
                  addressLine1: a.addressLine1,
                  addressLine2: a.addressLine2,
                  city: a.city,
                  state: a.state,
                  pincode: a.pincode,
                  country: a.country,
                  isDefault: false,
                  createdAt: a.createdAt,
                ),
              )
              .toList();
        }
        if (idx >= 0) {
          _addresses[idx] = addr;
        } else {
          _addresses.insert(0, addr);
        }
        notifyListeners();
      }
      return addr;
    } catch (e) {
      _error = 'Failed to update address';
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteAddress(int id) async {
    _error = null;
    try {
      await _service.deleteAddress(id);
      _addresses.removeWhere((a) => a.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete address';
      notifyListeners();
      return false;
    }
  }
}
