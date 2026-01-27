# Veena API Documentation

This document provides a comprehensive list of all APIs used in the Veena project, categorized by their functionality.

## Base Configuration

- **API Base URL**: `https://d17362b1w27h09.cloudfront.net/api`
- **Authentication**: Most endpoints require a `Bearer` token in the `Authorization` header.

---

## 🔐 Authentication APIs (AWS Cognito)

These APIs handle user identity and session management using the OAuth 2.0 PKCE flow.

| Endpoint | Method | Title | Description |
| :--- | :--- | :--- | :--- |
| `https://veena-auth.auth.ap-south-1.amazoncognito.com/oauth2/authorize` | GET | **Authorization** | Redirects to the Hosted UI for Google login. |
| `https://veena-auth.auth.ap-south-1.amazoncognito.com/oauth2/token` | POST | **Token Exchange** | Exchanges the auth code for Access, ID, and Refresh tokens. |
| `https://veena-auth.auth.ap-south-1.amazoncognito.com/logout` | GET | **Logout** | Invalidates the user session. |

---

## 🏠 Dashboard & Content Discovery

Powered by `DashboardService`. These APIs populate the home screen.

| Endpoint | Method | Title | Description |
| :--- | :--- | :--- | :--- |
| `/user/dashboard` | GET | **Dashboard Hub** | Fetches the primary data for the home screen layout. |
| `/user/dashboard/latest` | GET | **Latest Releases** | Retrieves the most recently added tracks/albums. |
| `/user/dashboard/popular` | GET | **Popular Tracks** | Fetches trending music based on global play counts. |
| `/user/dashboard/history` | GET | **Recently Played** | Gets the user's personal playback history. |

---

## 📚 User Library & Management

Powered by `LibraryService`. Manages personal collections and playlists.

| Endpoint | Method | Title | Description |
| :--- | :--- | :--- | :--- |
| `/user/library` | GET | **Library Overview** | Full summary of user's saved content. |
| `/user/library/playlists` | GET | **Get Playlists** | Lists all playlists created by the user. |
| `/user/library/playlists` | POST | **Create Playlist** | Creates a new empty playlist. |
| `/user/library/playlists/{id}`| DELETE | **Delete Playlist** | Removes a playlist from the user's library. |
| `/user/library/playlists/{id}/tracks` | GET | **Playlist Content** | Fetches all songs within a specific playlist. |
| `/user/library/playlists/{id}/tracks` | POST | **Add to Playlist** | Adds a specific media ID to a playlist. |
| `/user/library/playlists/{id}/tracks/{mediaId}` | DELETE | **Remove from Playlist** | Removes a specific track from a playlist. |
| `/user/library/artists` | GET | **My Artists** | Artists from user's history. |
| `/user/library/artists/all` | GET | **All Artists** | Global list of all active artists. |
| `/user/library/artists/{id}/tracks` | GET | **Artist Tracks** | Fetches all tracks for a specific artist. |
| `/user/library/albums` | GET | **My Albums** | Distinct albums from user's history. |
| `/user/library/favorites` | GET | **Favorites** | Retrieves all liked/favorited tracks. |

---

## 💿 Album Operations

Powered by `UserAlbumController`. Handles discovery and details of studio albums.

| Endpoint | Method | Title | Description |
| :--- | :--- | :--- | :--- |
| `/albums` | GET | **All Albums** | Retrieves all active studio albums. |
| `/albums/search` | GET | **Search Albums** | Find albums by name. |
| `/albums/{id}` | GET | **Album Details** | Fetches album info and all tracks in it. |

---

## 🎵 Media & Playback Operations

Powered by `MediaService`. Handles interaction with tracks.

| Endpoint | Method | Title | Description |
| :--- | :--- | :--- | :--- |
| `/media` | GET | **Browse Media** | Paginated list of all public media. |
| `/media/search?query={q}` | GET | **Media Search** | Search for tracks by title or description. |
| `/media/{id}/like` | POST | **Toggle Like** | Likes/Unlikes a song. |
| `/media/{id}/like` | GET | **Check Like Status** | Verifies if the current user has liked this track. |
| `/media/{id}/play` | POST | **Record Play** | Reports playback position to for analytics. |
| `/media/liked` | GET | **All Liked Media** | Dedicated endpoint for retrieving liked music. |
| `[External URL]` | GET | **Fetch Lyrics** | Retrieves raw text/LRC content from a provided URL. |

---

## Technical Implementation Notes

### Service Files

| Service | Path | Description |
| :--- | :--- | :--- |
| **ApiService** | [api_service.dart](file:///c:/Users/psks1/OneDrive/Desktop/Android%20Apps/Veena/lib/core/services/api_service.dart) | Base HTTP client with auth headers |
| **DashboardService** | [dashboard_service.dart](file:///c:/Users/psks1/OneDrive/Desktop/Android%20Apps/Veena/lib/core/services/dashboard_service.dart) | Home screen data fetching |
| **MediaService** | [media_service.dart](file:///c:/Users/psks1/OneDrive/Desktop/Android%20Apps/Veena/lib/core/services/media_service.dart) | Search, like, playback tracking |
| **LibraryService** | [library_service.dart](file:///c:/Users/psks1/OneDrive/Desktop/Android%20Apps/Veena/lib/core/services/library_service.dart) | Playlists, favorites, artists, albums |

### Authorization Flow

The app uses:
- **Mobile (Android/iOS)**: `flutter_appauth` package for native OAuth
- **Web**: Custom PKCE implementation with browser redirects
- **Desktop (Windows/Linux/macOS)**: Local HTTP server (port 8765) for OAuth callback

### Token Injection

The access token is automatically injected into all API requests via `ApiService.setAccessToken()` when the user authenticates.
