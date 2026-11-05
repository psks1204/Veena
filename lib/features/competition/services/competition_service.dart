import 'package:flutter/foundation.dart';
import '../../../core/services/api_service.dart';
import '../models/competition_response.dart';

/// Service to interact with the public Competition API (/api/competitions/*)
class CompetitionService extends ChangeNotifier {
  final ApiService _api;

  CompetitionResponse? _currentCompetition;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasFetched = false;

  CompetitionService(this._api);

  CompetitionResponse? get currentCompetition => _currentCompetition;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasFetched => _hasFetched;

  /// Fetches the ongoing competition from /api/competitions/ongoing
  /// Returns null if 204 No Content (no active/relevant competition).
  Future<CompetitionResponse?> fetchOngoingCompetition({bool forceRefresh = false}) async {
    if (_isLoading) return _currentCompetition;
    if (_hasFetched && !forceRefresh && _currentCompetition != null) {
      return _currentCompetition;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _api.get('/competitions/ongoing');
      if (data != null && data is Map<String, dynamic>) {
        _currentCompetition = CompetitionResponse.fromJson(data);
      } else {
        _currentCompetition = null; // 204 No Content
      }
      _hasFetched = true;
    } catch (e) {
      debugPrint('[CompetitionService] Error fetching ongoing competition: $e');
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return _currentCompetition;
  }
}
