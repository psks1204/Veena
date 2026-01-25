import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../models/media_item.dart';

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
      id: json['id'] ?? '',
      name: json['name'] ?? 'Untitled',
      description: json['description'],
      coverUrl: json['coverUrl'] ?? json['thumbnailUrl'],
      trackCount: json['trackCount'] ?? json['tracks']?.length ?? 0,
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt']) 
          : null,
    );
  }
}

/// Artist Model
class Artist {
  final String id;
  final String name;
  final String? imageUrl;
  final int followerCount;
  
  Artist({
    required this.id,
    required this.name,
    this.imageUrl,
    this.followerCount = 0,
  });
  
  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Artist',
      imageUrl: json['imageUrl'] ?? json['thumbnailUrl'],
      followerCount: json['followerCount'] ?? 0,
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
  final int? releaseYear;
  
  Album({
    required this.id,
    required this.title,
    required this.artistName,
    this.coverUrl,
    this.trackCount = 0,
    this.releaseYear,
  });
  
  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'] ?? '',
      title: json['title'] ?? json['name'] ?? 'Untitled',
      artistName: json['artistName'] ?? json['artist'] ?? 'Unknown',
      coverUrl: json['coverUrl'] ?? json['thumbnailUrl'],
      trackCount: json['trackCount'] ?? 0,
      releaseYear: json['releaseYear'],
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
  List<MediaItem> _favorites = [];
  List<Artist> _artists = [];
  List<Album> _albums = [];
  bool _isLoading = false;
  String? _error;
  
  List<Playlist> get playlists => _playlists;
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
      final data = await _api.get('/user/library');
      
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
        if (data['artists'] != null) {
          _artists = (data['artists'] as List)
              .map((item) => Artist.fromJson(item))
              .toList();
        }
        if (data['albums'] != null) {
          _albums = (data['albums'] as List)
              .map((item) => Album.fromJson(item))
              .toList();
        }
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
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
  
  /// Create a new playlist
  Future<Playlist?> createPlaylist(String name, {String? description}) async {
    try {
      final data = await _api.post('/user/library/playlists', body: {
        'name': name,
        if (description != null) 'description': description,
      });
      
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
      await _api.post('/user/library/playlists/$playlistId/tracks', body: {
        'mediaId': mediaId,
      });
      return true;
    } catch (e) {
      debugPrint('Add to playlist error: $e');
      return false;
    }
  }
  
  // ==================== FAVORITES ====================
  
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
  
  // ==================== ARTISTS ====================
  
  /// Get followed artists
  Future<List<Artist>> getArtists() async {
    try {
      final data = await _api.get('/user/library/artists');
      if (data != null && data is List) {
        _artists = data.map((item) => Artist.fromJson(item)).toList();
        notifyListeners();
      }
      return _artists;
    } catch (e) {
      debugPrint('Get artists error: $e');
      return [];
    }
  }
  
  // ==================== ALBUMS ====================
  
  /// Get saved albums
  Future<List<Album>> getAlbums() async {
    try {
      final data = await _api.get('/user/library/albums');
      if (data != null && data is List) {
        _albums = data.map((item) => Album.fromJson(item)).toList();
        notifyListeners();
      }
      return _albums;
    } catch (e) {
      debugPrint('Get albums error: $e');
      return [];
    }
  }
}
