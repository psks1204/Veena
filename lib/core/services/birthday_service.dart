import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

/// Birthday Service
///
/// Helper logic to detect if today is the user's birthday and if the
/// celebration "bomb" has already been shown today.
class BirthdayService {
  static const String _lastSeenKey = 'birthday_bomb_last_seen_date';

  /// Check if today is the user's birthday
  bool isBirthday(UserProfile? user) {
    if (user?.birthDate == null) return false;

    final today = DateTime.now();
    final dob = user!.birthDate!;

    return today.month == dob.month && today.day == dob.day;
  }

  /// Check if the birthday bomb should be shown (i.e., hasn't been shown today)
  Future<bool> shouldShowBirthdayBomb(UserProfile? user) async {
    if (!isBirthday(user)) return false;

    final prefs = await SharedPreferences.getInstance();
    final lastSeenStr = prefs.getString(_lastSeenKey);
    final todayStr = _formatDate(DateTime.now());

    // If never seen, or seen on a different day (e.g. last year), show it
    return lastSeenStr != todayStr;
  }

  /// Mark the birthday bomb as shown for today
  Future<void> markBirthdayBombAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = _formatDate(DateTime.now());
    await prefs.setString(_lastSeenKey, todayStr);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }
}
