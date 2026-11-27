import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:veena/core/services/api_service.dart';
import 'package:veena/core/services/dashboard_service.dart';

Map<String, dynamic> _song(String id, {required bool karaoke}) => {
  'id': id,
  'title': id,
  'mediaType': 'AUDIO',
  'status': 'READY',
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
  'karaoke': karaoke,
};

/// Stands in for the backend: GET /user/dashboard/karaoke returns the newest
/// [dashboardCount] karaoke songs (capped at 10, like the real endpoint);
/// GET /media pages through [catalogue], newest first.
class _FakeBackend {
  _FakeBackend(this.catalogue, {this.mediaStatus = 200});

  final List<Map<String, dynamic>> catalogue;
  final int mediaStatus;
  final mediaPagesRequested = <int>[];

  http.Client get client => MockClient((request) async {
    final path = request.url.path;
    if (path.endsWith('/user/dashboard/karaoke')) {
      final newest = catalogue.where((s) => s['karaoke'] == true).take(10);
      return http.Response(jsonEncode(newest.toList()), 200);
    }
    if (path.endsWith('/media')) {
      final page = int.parse(request.url.queryParameters['page']!);
      final size = int.parse(request.url.queryParameters['size']!);
      mediaPagesRequested.add(page);
      if (mediaStatus != 200) return http.Response('error', mediaStatus);
      final start = page * size;
      final content = catalogue.skip(start).take(size).toList();
      return http.Response(
        jsonEncode({
          'content': content,
          'last': start + size >= catalogue.length,
        }),
        200,
      );
    }
    return http.Response('not found', 404);
  });
}

/// [karaokeCount] karaoke songs, each followed by two regular songs.
List<Map<String, dynamic>> _catalogue(int karaokeCount) => [
  for (var i = 0; i < karaokeCount; i++) ...[
    _song('k$i', karaoke: true),
    _song('a$i', karaoke: false),
    _song('b$i', karaoke: false),
  ],
];

void main() {
  test('scrolling loads every karaoke song past the first 10, in order',
      () async {
    final backend = _FakeBackend(_catalogue(45));
    final dashboard = DashboardService(ApiService());

    await http.runWithClient(() async {
      await dashboard.fetchKaraoke();
      expect(dashboard.karaoke.length, 10);
      expect(dashboard.hasMoreKaraoke, isTrue);

      // Each step adds at least a page's worth until the catalogue runs out.
      await dashboard.loadMoreKaraoke();
      expect(dashboard.karaoke.length, greaterThanOrEqualTo(30));
      while (dashboard.hasMoreKaraoke) {
        await dashboard.loadMoreKaraoke();
      }
    }, () => backend.client);

    final ids = dashboard.karaoke.map((m) => m.id).toList();
    expect(ids, [for (var i = 0; i < 45; i++) 'k$i']);
    expect(dashboard.isLoadingMoreKaraoke, isFalse);
    // 135 catalogue rows at 100 per request: pages 0 and 1, each read once.
    expect(backend.mediaPagesRequested, [0, 1]);
  });

  test('fewer than 10 karaoke songs means there is nothing more to load',
      () async {
    final backend = _FakeBackend(_catalogue(7));
    final dashboard = DashboardService(ApiService());

    await http.runWithClient(() async {
      await dashboard.fetchKaraoke();
      await dashboard.loadMoreKaraoke();
    }, () => backend.client);

    expect(dashboard.karaoke.length, 7);
    expect(dashboard.hasMoreKaraoke, isFalse);
    expect(backend.mediaPagesRequested, isEmpty);
  });

  test('a failed page keeps the list and offers a retry', () async {
    final backend = _FakeBackend(_catalogue(30), mediaStatus: 500);
    final dashboard = DashboardService(ApiService());

    await http.runWithClient(() async {
      await dashboard.fetchKaraoke();
      await dashboard.loadMoreKaraoke();
    }, () => backend.client);

    expect(dashboard.karaoke.length, 10);
    expect(dashboard.hasMoreKaraoke, isTrue);
    expect(dashboard.karaokeLoadMoreFailed, isTrue);
    expect(dashboard.isLoadingMoreKaraoke, isFalse);
  });

  test('pull-to-refresh starts over from the newest songs', () async {
    final backend = _FakeBackend(_catalogue(45));
    final dashboard = DashboardService(ApiService());

    await http.runWithClient(() async {
      await dashboard.fetchKaraoke();
      await dashboard.loadMoreKaraoke();
      await dashboard.fetchKaraoke();
    }, () => backend.client);

    expect(dashboard.karaoke.map((m) => m.id).take(10).toList(), [
      for (var i = 0; i < 10; i++) 'k$i',
    ]);
    expect(dashboard.karaoke.length, 10);
    expect(dashboard.hasMoreKaraoke, isTrue);
  });
}
