import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CreditsService {
  static const String _cacheKeyDate = 'app_credits_date';
  static const String _cacheKeyName = 'app_credits_name';
  static const String _cacheKeyUrl = 'app_credits_url';

  // REPLACE THIS URL with your deployed Supabase Edge Function URL
  static const String _apiUrl =
      'https://noexvhmdqxueuqzxrqmo.supabase.co/functions/v1/app_credits';

  Future<Map<String, String>?> getCredits() async {
    try {
      print('=== CREDITS SERVICE: getCredits() called ===');
      final prefs = await SharedPreferences.getInstance();

      // Check cache first
      final cachedDateStr = prefs.getString(_cacheKeyDate);
      print('=== CREDITS SERVICE: Cache Date: $cachedDateStr ===');
      if (cachedDateStr != null) {
        final cachedDate = DateTime.tryParse(cachedDateStr);
        if (cachedDate != null) {
          final now = DateTime.now();
          // Check if cached today
          if (cachedDate.year == now.year &&
              cachedDate.month == now.month &&
              cachedDate.day == now.day) {
            final name = prefs.getString(_cacheKeyName);
            final url = prefs.getString(_cacheKeyUrl);
            print('=== CREDITS SERVICE: Cache Hit: name=$name, url=$url ===');
            if (name != null &&
                name.isNotEmpty &&
                url != null &&
                url.isNotEmpty) {
              return {'name': name, 'url': url};
            }
          }
        }
      }

      print('=== CREDITS SERVICE: Calling API ($_apiUrl) ===');
      // If no valid cache or expired (new day), call API
      final response = await http
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 10));

      print(
        '=== CREDITS SERVICE: API Response Status: ${response.statusCode} ===',
      );
      print('=== CREDITS SERVICE: API Response Body: ${response.body} ===');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final name = data['name']?.toString();
        final url = data['url']?.toString();

        print('=== CREDITS SERVICE: Parsed name: $name, url: $url ===');

        if (name != null && name.isNotEmpty && url != null && url.isNotEmpty) {
          // Store in cache
          await prefs.setString(
            _cacheKeyDate,
            DateTime.now().toIso8601String(),
          );
          await prefs.setString(_cacheKeyName, name);
          await prefs.setString(_cacheKeyUrl, url);

          print('=== CREDITS SERVICE: Cache saved ===');
          return {'name': name, 'url': url};
        } else {
          print('=== CREDITS SERVICE: API data invalid mostly nulls ===');
        }
      }
    } catch (e) {
      print('=== CREDITS SERVICE: Error $e ===');
      // Return null directly if API fails or parsing issues occur
      return null;
    }

    print('=== CREDITS SERVICE: Returning null overall ===');
    return null;
  }
}
