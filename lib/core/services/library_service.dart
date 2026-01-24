import 'api_service.dart';
import '../../shared/models/media_item.dart';

class LibraryService {
  final ApiService _apiService = ApiService();

  // ==================== LIBRARY DATA ====================

  Future<LibraryData> getLibraryData({String? token}) async {
    final response = await _apiService.get('/user/library', token: token);
    return LibraryData.fromJson(response);
  }

  // ==================== PLAYLISTS ====================

  Future<List<Playlist>> getPlaylists({String? token}) async {
    final List response = await _apiService.get('/user/library/playlists', token: token);
    return response.map((item) => Playlist.fromJson(item)).toList();
  }

  Future<Playlist> createPlaylist({
    required String name,
    String? description,
    String? token,
  }) async {
    final response = await _apiService.post(
      '/user/library/playlists',
      body: {'name': name, 'description': description},
      token: token,
    );
    return Playlist.fromJson(response);
  }

  Future<void> deletePlaylist(String playlistId, {String? token}) async {
    await _apiService.delete('/user/library/playlists/$playlistId', token: token);
  }

  Future<List<MediaItem>> getPlaylistTracks(String playlistId, {String? token}) async {
    final List response = await _apiService.get(
      '/user/library/playlists/$playlistId/tracks',
      token: token,
    );
    return response.map((item) => MediaItem.fromJson(item)).toList();
  }

  Future<void> addToPlaylist(String playlistId, String mediaId, {String? token}) async {
    await _apiService.post(
      '/user/library/playlists/$playlistId/tracks',
      body: {'mediaId': mediaId},
      token: token,
    );
  }

  Future<void> removeFromPlaylist(String playlistId, String mediaId, {String? token}) async {
    await _apiService.delete(
      '/user/library/playlists/$playlistId/tracks/$mediaId',
      token: token,
    );
  }

  // ==================== ARTISTS ====================

  Future<List<Artist>> getArtists({String? token}) async {
    final List response = await _apiService.get('/user/library/artists', token: token);
    return response.map((item) => Artist.fromJson(item)).toList();
  }

  Future<List<Artist>> getAllArtists({String? token}) async {
    final List response = await _apiService.get('/user/library/artists/all', token: token);
    return response.map((item) => Artist.fromJson(item)).toList();
  }

  Future<List<MediaItem>> getArtistTracks(int artistId, {String? token}) async {
    final List response = await _apiService.get(
      '/user/library/artists/$artistId/tracks',
      token: token,
    );
    return response.map((item) => MediaItem.fromJson(item)).toList();
  }

  // ==================== ALBUMS ====================

  Future<List<Album>> getAlbums({String? token}) async {
    final List response = await _apiService.get('/user/library/albums', token: token);
    return response.map((item) => Album.fromJson(item)).toList();
  }

  // ==================== FAVORITES ====================

  Future<List<MediaItem>> getFavorites({String? token}) async {
    final List response = await _apiService.get('/user/library/favorites', token: token);
    return response.map((item) => MediaItem.fromJson(item)).toList();
  }
}

// ==================== MODEL CLASSES ====================

class LibraryData {
  final List<Playlist> playlists;
  final List<Artist> artists;
  final List<Album> albums;
  final List<MediaItem> favorites;
  final List<MediaItem> recentlyPlayed;

  LibraryData({
    required this.playlists,
    required this.artists,
    required this.albums,
    required this.favorites,
    required this.recentlyPlayed,
  });

  factory LibraryData.fromJson(Map<String, dynamic> json) {
    return LibraryData(
      playlists: (json['playlists'] as List?)
          ?.map((item) => Playlist.fromJson(item))
          .toList() ?? [],
      artists: (json['artists'] as List?)
          ?.map((item) => Artist.fromJson(item))
          .toList() ?? [],
      albums: (json['albums'] as List?)
          ?.map((item) => Album.fromJson(item))
          .toList() ?? [],
      favorites: (json['favorites'] as List?)
          ?.map((item) => MediaItem.fromJson(item))
          .toList() ?? [],
      recentlyPlayed: (json['recentlyPlayed'] as List?)
          ?.map((item) => MediaItem.fromJson(item))
          .toList() ?? [],
    );
  }
}

class Playlist {
  final String id;
  final String name;
  final String? description;
  final String? coverUrl;
  final int trackCount;
  final bool isPublic;

  Playlist({
    required this.id,
    required this.name,
    this.description,
    this.coverUrl,
    this.trackCount = 0,
    this.isPublic = false,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      coverUrl: json['coverUrl'],
      trackCount: json['trackCount'] ?? 0,
      isPublic: json['isPublic'] ?? false,
    );
  }
}

class Artist {
  final int id;
  final String name;
  final String? imageUrl;
  final String? genre;
  final bool verified;

  Artist({
    required this.id,
    required this.name,
    this.imageUrl,
    this.genre,
    this.verified = false,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'],
      name: json['name'],
      imageUrl: json['imageUrl'],
      genre: json['genre'],
      verified: json['verified'] ?? false,
    );
  }
}

class Album {
  final String id;
  final String title;
  final String artistName;
  final String? coverUrl;
  final int trackCount;

  Album({
    required this.id,
    required this.title,
    required this.artistName,
    this.coverUrl,
    this.trackCount = 0,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'],
      title: json['title'],
      artistName: json['artistName'],
      coverUrl: json['coverUrl'],
      trackCount: json['trackCount'] ?? 0,
    );
  }
}
