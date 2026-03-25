import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../models/media_item.dart';
import '../models/artist.dart';

/// Playlist Model
class Playlist {
  final String id;
  final String name;
  final String? description;
  final String? coverUrl;
  final int trackCount;
  final DateTime? createdAt;

  Playlist({
    required this.id,
    required this.name,
    this.description,
    this.coverUrl,
    this.trackCount = 0,
    this.createdAt,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: (json['id'] ?? '').toString(),
      name: json['name'] ?? json['title'] ?? 'Untitled',
      description: json['description'] as String?,
      coverUrl:
          json['coverUrl'] ?? json['coverImageUrl'] ?? json['thumbnailUrl'],
      trackCount: json['trackCount'] ?? json['tracks']?.length ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

/// Album Model
class Album {
  final String id;
  final String title;
  final String artistName;
  final String? coverUrl;
  final int trackCount;
  final String? description;
  final DateTime? createdAt;

  Album({
    required this.id,
    required this.title,
    required this.artistName,
    this.coverUrl,
    this.trackCount = 0,
    this.description,
    this.createdAt,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    // Extract artist name: prefer nested artist object, fall back to artistName
    String name = 'Unknown Artist';
    if (json['artist'] != null && json['artist'] is Map) {
      name = json['artist']['name'] as String? ?? 'Unknown Artist';
    } else {
      name =
          json['artistName'] as String? ??
          json['artist'] as String? ??
          'Unknown Artist';
    }

    return Album(
      id: (json['id'] ?? '').toString(),
      title: json['title'] ?? json['name'] ?? 'Untitled',
      artistName: name,
      coverUrl:
          json['coverUrl'] ?? json['coverImageUrl'] ?? json['thumbnailUrl'],
      trackCount: json['trackCount'] ?? 0,
      description: json['description'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

/// Library Service
///
/// Manages user's personal library: playlists, favorites, artists, albums.
class LibraryService extends ChangeNotifier {
  final ApiService _api;

  LibraryService(this._api);

  List<Playlist> _playlists = [];
  List<Playlist> _featuredPlaylists = [];
  List<MediaItem> _favorites = [];
  List<Artist> _artists = [];
  List<Album> _albums = [];
  bool _isLoading = false;
  String? _error;

  List<Playlist> get playlists => _playlists;
  List<Playlist> get featuredPlaylists => _featuredPlaylists;
  List<MediaItem> get favorites => _favorites;
  List<Artist> get artists => _artists;
  List<Album> get albums => _albums;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch complete library overview
  Future<void> fetchLibrary() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch user library data and all albums concurrently
      final results = await Future.wait([
        _api.get('/user/library'),
        _api.get('/albums'),
      ]);

      final data = results[0];
      final albumsData = results[1];

      if (data != null) {
        if (data['playlists'] != null) {
          _playlists = (data['playlists'] as List)
              .map((item) => Playlist.fromJson(item))
              .toList();
        }
        if (data['favorites'] != null) {
          _favorites = (data['favorites'] as List)
              .map((item) => MediaItem.fromJson(item))
              .toList();
        }
// Note: We skip data['artists'] here to always use the followed artists API below
        if (data['albums'] != null) {
          _albums = (data['albums'] as List)
              .map((item) => Album.fromJson(item))
              .toList();
        }
      }

      // Parse albums from /albums endpoint (GET all albums)
      if (albumsData != null && albumsData is List) {
        _albums = albumsData.map((item) => Album.fromJson(item)).toList();
        debugPrint('[LibraryService] Loaded ${_albums.length} albums');
      }

      // Always fetch followed artists to ensure consistency
      try {
        await getArtists(size: 30);
      } catch (e) {
        debugPrint('[LibraryService] Failed to load followed artists: $e');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('[LibraryService] fetchLibrary error: $e');
    }
  }

  // ==================== PLAYLISTS ====================

  /// Get all user's playlists
  Future<List<Playlist>> getPlaylists() async {
    try {
      final data = await _api.get('/user/library/playlists');
      if (data != null && data is List) {
        _playlists = data.map((item) => Playlist.fromJson(item)).toList();
        notifyListeners();
      }
      return _playlists;
    } catch (e) {
      debugPrint('Get playlists error: $e');
      return [];
    }
  }

  /// Get featured playlists
  /// GET /api/user/library/playlists/featured
  Future<List<Playlist>> getFeaturedPlaylists() async {
    try {
      final data = await _api.get('/user/library/playlists/featured');
      if (data != null && data is List) {
        _featuredPlaylists = data
            .map((item) => Playlist.fromJson(item))
            .toList();
        debugPrint(
          '[LibraryService] Loaded ${_featuredPlaylists.length} featured playlists',
        );
        notifyListeners();
      }
      return _featuredPlaylists;
    } catch (e) {
      debugPrint('Get featured playlists error: $e');
      return [];
    }
  }

  /// Create a new playlist
  Future<Playlist?> createPlaylist(String name, {String? description}) async {
    try {
      final data = await _api.post(
        '/user/library/playlists',
        body: {
          'name': name,
          if (description != null) 'description': description,
        },
      );

      if (data != null) {
        final playlist = Playlist.fromJson(data);
        _playlists.insert(0, playlist);
        notifyListeners();
        return playlist;
      }
    } catch (e) {
      debugPrint('Create playlist error: $e');
    }
    return null;
  }

  /// Delete a playlist
  Future<bool> deletePlaylist(String playlistId) async {
    try {
      await _api.delete('/user/library/playlists/$playlistId');
      _playlists.removeWhere((p) => p.id == playlistId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Delete playlist error: $e');
      return false;
    }
  }

  /// Get tracks in a playlist
  Future<List<MediaItem>> getPlaylistTracks(String playlistId) async {
    try {
      final data = await _api.get('/user/library/playlists/$playlistId/tracks');
      if (data != null && data is List) {
        return data.map((item) => MediaItem.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Get playlist tracks error: $e');
    }
    return [];
  }

  /// Add track to playlist
  Future<bool> addToPlaylist(String playlistId, String mediaId) async {
    try {
      await _api.post(
        '/user/library/playlists/$playlistId/tracks',
        body: {'mediaId': mediaId},
      );
      return true;
    } catch (e) {
      debugPrint('Add to playlist error: $e');
      return false;
    }
  }

  /// Get all favorites/liked tracks
  Future<List<MediaItem>> getFavorites() async {
    try {
      final data = await _api.get('/user/library/favorites');
      if (data != null && data is List) {
        _favorites = data.map((item) => MediaItem.fromJson(item)).toList();
        notifyListeners();
      }
      return _favorites;
    } catch (e) {
      debugPrint('Get favorites error: $e');
      return [];
    }
  }

  /// Manually add a favorite locally
  void addFavoriteLocal(MediaItem item) {
    if (!_favorites.any((m) => m.id == item.id)) {
      _favorites.insert(0, item);
      notifyListeners();
    }
  }

  /// Manually remove a favorite locally
  void removeFavoriteLocal(String mediaId) {
    _favorites.removeWhere((item) => item.id == mediaId);
    notifyListeners();
  }

  // ==================== ARTISTS ====================

  /// Get followed artists
  /// GET /api/user/library/artists
  Future<List<Artist>> getArtists({int size = 30}) async {
    try {
      final data = await _api.get(
        '/artists/following/page',
        queryParams: {'page': '0', 'size': '50'},
      );
      if (data != null && data['content'] != null) {
        final content = data['content'] as List;
        _artists = content.map((item) => Artist.fromJson(item)).toList();
        notifyListeners();
      }
      return _artists;
    } catch (e) {
      debugPrint('Get artists error: $e');
      return [];
    }
  }

  // ==================== ALBUMS ====================

  /// Get all albums
  /// GET /api/albums
  Future<List<Album>> getAlbums() async {
    try {
      final data = await _api.get('/albums');
      if (data != null && data is List) {
        _albums = data.map((item) => Album.fromJson(item)).toList();
        debugPrint('[LibraryService] getAlbums: ${_albums.length} albums');
        notifyListeners();
      }
      return _albums;
    } catch (e) {
      debugPrint('Get albums error: $e');
      return [];
    }
  }

  /// Remove track from playlist
  /// DELETE /api/user/library/playlists/{id}/tracks/{mediaId}
  Future<bool> removeFromPlaylist(String playlistId, String mediaId) async {
    try {
      await _api.delete('/user/library/playlists/$playlistId/tracks/$mediaId');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Remove from playlist error: $e');
      return false;
    }
  }

  /// Get all artists (not user-specific)
  /// GET /api/user/library/artists
  Future<List<Artist>> getAllArtists() async {
    try {
      final data = await _api.get(
        '/user/library/artists',
        queryParams: {'page': '0', 'size': '30'},
      );
      if (data != null && data['content'] != null) {
        return (data['content'] as List)
            .map((item) => Artist.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Get all artists error: $e');
      return [];
    }
  }

  /// Get tracks by artist
  /// GET /api/user/library/artists/{id}/tracks
  Future<List<MediaItem>> getArtistTracks(String artistId) async {
    try {
      final data = await _api.get('/user/library/artists/$artistId/tracks');
      if (data != null && data is List) {
        return data.map((item) => MediaItem.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Get artist tracks error: $e');
      return [];
    }
  }
}
