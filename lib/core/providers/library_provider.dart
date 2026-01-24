import 'package:flutter/foundation.dart';
import '../services/library_service.dart';
import '../../features/auth/services/auth_service.dart';
import '../../shared/models/media_item.dart';

export '../services/library_service.dart' show Playlist, Artist, Album, LibraryData;

enum LibraryState { initial, loading, success, error }

class LibraryProvider extends ChangeNotifier {
  final LibraryService _libraryService = LibraryService();
  AuthService? _authService;

  LibraryState _state = LibraryState.initial;
  String _errorMessage = '';

  // Library data
  List<Playlist> _playlists = [];
  List<Artist> _artists = [];
  List<Album> _albums = [];
  List<MediaItem> _favorites = [];
  List<MediaItem> _recentlyPlayed = [];

  // Loading states for individual tabs
  bool _isLoadingPlaylists = false;
  bool _isLoadingArtists = false;
  bool _isLoadingAlbums = false;
  bool _isLoadingFavorites = false;

  // Getters
  LibraryState get state => _state;
  String get errorMessage => _errorMessage;
  List<Playlist> get playlists => _playlists;
  List<Artist> get artists => _artists;
  List<Album> get albums => _albums;
  List<MediaItem> get favorites => _favorites;
  List<MediaItem> get recentlyPlayed => _recentlyPlayed;
  bool get isLoadingPlaylists => _isLoadingPlaylists;
  bool get isLoadingArtists => _isLoadingArtists;
  bool get isLoadingAlbums => _isLoadingAlbums;
  bool get isLoadingFavorites => _isLoadingFavorites;

  void updateAuth(AuthService auth) {
    _authService = auth;
  }

  // Load all library data at once
  Future<void> loadLibrary() async {
    _state = LibraryState.loading;
    notifyListeners();

    try {
      final data = await _libraryService.getLibraryData(
        token: _authService?.token,
      );
      _playlists = data.playlists;
      _artists = data.artists;
      _albums = data.albums;
      _favorites = data.favorites;
      _recentlyPlayed = data.recentlyPlayed;
      _state = LibraryState.success;
    } catch (e) {
      _state = LibraryState.error;
      _errorMessage = e.toString();
      debugPrint('Error loading library: $e');
    }
    notifyListeners();
  }

  // ==================== PLAYLISTS ====================

  Future<void> loadPlaylists() async {
    _isLoadingPlaylists = true;
    notifyListeners();

    try {
      _playlists = await _libraryService.getPlaylists(
        token: _authService?.token,
      );
    } catch (e) {
      debugPrint('Error loading playlists: $e');
    } finally {
      _isLoadingPlaylists = false;
      notifyListeners();
    }
  }

  Future<Playlist?> createPlaylist(String name, {String? description}) async {
    try {
      final playlist = await _libraryService.createPlaylist(
        name: name,
        description: description,
        token: _authService?.token,
      );
      _playlists.insert(0, playlist);
      notifyListeners();
      return playlist;
    } catch (e) {
      debugPrint('Error creating playlist: $e');
      return null;
    }
  }

  Future<bool> deletePlaylist(String playlistId) async {
    try {
      await _libraryService.deletePlaylist(
        playlistId,
        token: _authService?.token,
      );
      _playlists.removeWhere((p) => p.id == playlistId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting playlist: $e');
      return false;
    }
  }

  Future<List<MediaItem>> getPlaylistTracks(String playlistId) async {
    try {
      return await _libraryService.getPlaylistTracks(
        playlistId,
        token: _authService?.token,
      );
    } catch (e) {
      debugPrint('Error loading playlist tracks: $e');
      return [];
    }
  }

  Future<bool> addToPlaylist(String playlistId, String mediaId) async {
    try {
      await _libraryService.addToPlaylist(
        playlistId,
        mediaId,
        token: _authService?.token,
      );
      // Update track count locally
      final index = _playlists.indexWhere((p) => p.id == playlistId);
      if (index != -1) {
        final playlist = _playlists[index];
        _playlists[index] = Playlist(
          id: playlist.id,
          name: playlist.name,
          description: playlist.description,
          coverUrl: playlist.coverUrl,
          trackCount: playlist.trackCount + 1,
          isPublic: playlist.isPublic,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error adding to playlist: $e');
      return false;
    }
  }

  Future<bool> removeFromPlaylist(String playlistId, String mediaId) async {
    try {
      await _libraryService.removeFromPlaylist(
        playlistId,
        mediaId,
        token: _authService?.token,
      );
      return true;
    } catch (e) {
      debugPrint('Error removing from playlist: $e');
      return false;
    }
  }

  // ==================== ARTISTS ====================

  Future<void> loadArtists() async {
    _isLoadingArtists = true;
    notifyListeners();

    try {
      _artists = await _libraryService.getArtists(
        token: _authService?.token,
      );
    } catch (e) {
      debugPrint('Error loading artists: $e');
    } finally {
      _isLoadingArtists = false;
      notifyListeners();
    }
  }

  Future<List<MediaItem>> getArtistTracks(int artistId) async {
    try {
      return await _libraryService.getArtistTracks(
        artistId,
        token: _authService?.token,
      );
    } catch (e) {
      debugPrint('Error loading artist tracks: $e');
      return [];
    }
  }

  // ==================== ALBUMS ====================

  Future<void> loadAlbums() async {
    _isLoadingAlbums = true;
    notifyListeners();

    try {
      _albums = await _libraryService.getAlbums(
        token: _authService?.token,
      );
    } catch (e) {
      debugPrint('Error loading albums: $e');
    } finally {
      _isLoadingAlbums = false;
      notifyListeners();
    }
  }

  // ==================== FAVORITES ====================

  Future<void> loadFavorites() async {
    _isLoadingFavorites = true;
    notifyListeners();

    try {
      _favorites = await _libraryService.getFavorites(
        token: _authService?.token,
      );
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    } finally {
      _isLoadingFavorites = false;
      notifyListeners();
    }
  }

  // Get all items for "All" tab
  List<LibraryItem> getAllItems() {
    final items = <LibraryItem>[];

    // Add playlists
    for (final playlist in _playlists) {
      items.add(LibraryItem(
        id: playlist.id,
        title: playlist.name,
        subtitle: '${playlist.trackCount} tracks',
        imageUrl: playlist.coverUrl,
        type: LibraryItemType.playlist,
      ));
    }

    // Add artists
    for (final artist in _artists) {
      items.add(LibraryItem(
        id: artist.id.toString(),
        title: artist.name,
        subtitle: artist.genre ?? 'Artist',
        imageUrl: artist.imageUrl,
        type: LibraryItemType.artist,
      ));
    }

    // Add albums
    for (final album in _albums) {
      items.add(LibraryItem(
        id: album.id,
        title: album.title,
        subtitle: album.artistName,
        imageUrl: album.coverUrl,
        type: LibraryItemType.album,
      ));
    }

    return items;
  }
}


enum LibraryItemType { playlist, artist, album, favorite }

class LibraryItem {
  final String id;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final LibraryItemType type;

  LibraryItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.type,
  });
}

