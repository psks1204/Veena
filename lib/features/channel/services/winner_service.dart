import 'package:flutter/foundation.dart';
import '../../../core/services/api_service.dart';
import '../models/winner_response.dart';

/// Service to interact with the Winner APIs (/api/winners/*)
class WinnerService extends ChangeNotifier {
  final ApiService _api;

  WinnerService(this._api);

  Future<WinnerResponse?> getMonthlyWinner({
    required int year,
    required int month,
  }) async {
    try {
      final data = await _api.get(
        '/winners/monthly',
        queryParams: {'year': year.toString(), 'month': month.toString()},
      );
      if (data != null) {
        return WinnerResponse.fromJson(data as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Error getting monthly winner: $e');
    }
    return null;
  }

  Future<WinnerResponse?> getQuarterlyWinner({
    required int year,
    required int quarter,
  }) async {
    try {
      final data = await _api.get(
        '/winners/quarterly',
        queryParams: {'year': year.toString(), 'quarter': quarter.toString()},
      );
      if (data != null) {
        return WinnerResponse.fromJson(data as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Error getting quarterly winner: $e');
    }
    return null;
  }

  Future<WinnerResponse?> getYearlyWinner({required int year}) async {
    try {
      final data = await _api.get(
        '/winners/yearly',
        queryParams: {'year': year.toString()},
      );
      if (data != null) {
        return WinnerResponse.fromJson(data as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Error getting yearly winner: $e');
    }
    return null;
  }

  Future<WinnerResponse?> getCurrentMonthWinner() async {
    try {
      final data = await _api.get('/winners/current-month');
      if (data != null) {
        return WinnerResponse.fromJson(data as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Error getting current month winner: $e');
    }
    return null;
  }
}
