import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:veena/core/providers/profile_provider.dart';
import 'package:veena/core/services/api_service.dart';
import 'package:veena/core/services/profile_service.dart';
import 'package:veena/features/auth/services/auth_service.dart';

/// A backend that answers by the bearer token a request carries: tokens in
/// [okTokens] get 200, everything else 401.
MockClient _backend(Set<String> okTokens, {List<String?>? seen}) {
  return MockClient((request) async {
    final auth = request.headers['Authorization'];
    final token = auth?.replaceFirst('Bearer ', '');
    seen?.add(token);
    if (token != null && okTokens.contains(token)) {
      return http.Response('{"ok":true}', 200);
    }
    return http.Response('{"message":"Unauthorized"}', 401);
  });
}

Future<T> _withBackend<T>(http.Client client, Future<T> Function() body) =>
    http.runWithClient(body, () => client);

String _jwt(Map<String, dynamic> claims) {
  String part(Object o) =>
      base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  return '${part({'alg': 'none'})}.${part(claims)}.sig';
}

void main() {
  group('ApiService 401 handling', () {
    late ApiService api;
    late int signOuts;
    late int refreshes;

    setUp(() {
      api = ApiService();
      signOuts = 0;
      refreshes = 0;
      api.onUnauthorized = () => signOuts++;
    });

    test(
      'an expired session signs out even straight after the token is set',
      () async {
        // Regression: a 3-second "grace period" after setAccessToken swallowed
        // the 401s from an expired token restored at launch, so the user was
        // never signed out and landed on the DOB gate instead.
        api.setAccessToken('expired');
        api.onRefreshToken = () async {
          refreshes++;
          return false;
        };

        await _withBackend(_backend({}), () async {
          await expectLater(api.get('/profile'), throwsA(isA<ApiException>()));
        });

        expect(refreshes, 1);
        expect(signOuts, 1);
      },
    );

    test('a refreshed token is retried and the request succeeds', () async {
      api.setAccessToken('old');
      api.onRefreshToken = () async {
        refreshes++;
        api.setAccessToken('new');
        return true;
      };

      final result = await _withBackend(
        _backend({'new'}),
        () => api.get('/profile'),
      );

      expect(result, {'ok': true});
      expect(refreshes, 1);
      expect(signOuts, 0);
    });

    test(
      'a 401 for a freshly refreshed token is an error, not a sign-out',
      () async {
        // The backend also uses 401 for ownership checks ("You are not the
        // owner of this playlist"); that must not end the session.
        api.setAccessToken('old');
        api.onRefreshToken = () async {
          refreshes++;
          api.setAccessToken('new');
          return true;
        };

        await _withBackend(_backend({}), () async {
          await expectLater(
            api.put('/user/library/playlists/1', body: {}),
            throwsA(isA<ApiException>()),
          );
        });

        expect(refreshes, 1);
        expect(signOuts, 0);
      },
    );

    test('with no session a 401 neither refreshes nor signs out', () async {
      api.onRefreshToken = () async {
        refreshes++;
        return false;
      };

      await _withBackend(_backend({}), () async {
        await expectLater(api.get('/media'), throwsA(isA<ApiException>()));
      });

      expect(refreshes, 0);
      expect(signOuts, 0);
    });

    test(
      'a request sent with a since-replaced token is resent, not refreshed',
      () async {
        api.setAccessToken('old');
        api.onRefreshToken = () async {
          refreshes++;
          return false;
        };
        final seen = <String?>[];
        final client = MockClient((request) async {
          final token = request.headers['Authorization'];
          seen.add(token);
          if (token == 'Bearer old') {
            // Another request refreshed the token while this one was out.
            api.setAccessToken('new');
            return http.Response('', 401);
          }
          return http.Response('{"ok":true}', 200);
        });

        final result = await _withBackend(client, () => api.get('/x'));

        expect(result, {'ok': true});
        expect(seen, ['Bearer old', 'Bearer new']);
        expect(refreshes, 0);
        expect(signOuts, 0);
      },
    );

    test('a session started during the refresh is not signed out', () async {
      api.setAccessToken('a');
      api.onRefreshToken = () async {
        refreshes++;
        api.setAccessToken('b'); // e.g. the user signed in again meanwhile
        return false;
      };

      await _withBackend(_backend({}), () async {
        await expectLater(api.get('/x'), throwsA(isA<ApiException>()));
      });

      expect(signOuts, 0);
    });
  });

  group('isJwtExpired', () {
    final now = DateTime.utc(2026, 11, 27, 12);
    int secs(DateTime t) => t.millisecondsSinceEpoch ~/ 1000;

    test('past exp is expired, future exp is not', () {
      final past = _jwt({'exp': secs(now.subtract(const Duration(hours: 1)))});
      final future = _jwt({'exp': secs(now.add(const Duration(hours: 1)))});
      expect(isJwtExpired(past, now: now), isTrue);
      expect(isJwtExpired(future, now: now), isFalse);
    });

    test('a token about to expire counts as expired', () {
      final soon = _jwt({'exp': secs(now.add(const Duration(seconds: 10)))});
      expect(isJwtExpired(soon, now: now), isTrue);
    });

    test('unreadable tokens are left for the server to judge', () {
      expect(isJwtExpired('not-a-jwt', now: now), isFalse);
      expect(isJwtExpired(_jwt({'sub': 'x'}), now: now), isFalse);
    });
  });

  group('isTransientAuthError', () {
    test('refusals end the session', () {
      expect(isTransientAuthError('HTTP 400: {"error":"invalid_grant"}'),
          isFalse);
      expect(
        isTransientAuthError(
          'PlatformException(token_failed, Failed to get token: '
          '[error: invalid_grant, description: Refresh Token has expired])',
        ),
        isFalse,
      );
      expect(isTransientAuthError(null), isFalse);
    });

    test('network trouble keeps the session', () {
      expect(isTransientAuthError('Network error'), isTrue);
      expect(
        isTransientAuthError('The Internet connection appears to be offline.'),
        isTrue,
      );
      expect(isTransientAuthError('ClientException: XMLHttpRequest error.'),
          isTrue);
      expect(isTransientAuthError('HTTP 503: Service Unavailable'), isTrue);
    });
  });

  group('ProfileProvider date-of-birth gate', () {
    Future<ProfileProvider> initWith(http.Response profileResponse) async {
      final api = ApiService()..setAccessToken('t');
      api.onRefreshToken = () async => false;
      final provider = ProfileProvider(ProfileService(api));
      final client = MockClient((_) async => profileResponse);
      await http.runWithClient(
        () => provider.initializeOnLogin(googleName: null, googleEmail: null),
        () => client,
      );
      return provider;
    }

    test('a profile that failed to load does not demand a birth date',
        () async {
      // Regression: a failed fetch was read as "no birth date on file".
      final expired = await initWith(http.Response('', 401));
      expect(expired.needsDobSetup, isFalse);
      expect(expired.needsNameSetup, isFalse);

      final serverError = await initWith(http.Response('oops', 500));
      expect(serverError.needsDobSetup, isFalse);
    });

    test('a loaded profile without a birth date still gets the gate',
        () async {
      final provider = await initWith(
        http.Response(jsonEncode({'id': '1', 'name': 'Asha'}), 200),
      );
      expect(provider.needsDobSetup, isTrue);
      expect(provider.needsNameSetup, isFalse);
    });

    test('a loaded profile with a birth date passes', () async {
      final provider = await initWith(
        http.Response(
          jsonEncode({'id': '1', 'name': 'Asha', 'birthDate': '1990-04-02'}),
          200,
        ),
      );
      expect(provider.needsDobSetup, isFalse);
    });
  });
}
