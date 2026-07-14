# Veena User API Documentation

flutter build apk --release --dart-define=RAZORPAY_KEY_ID=rzp_live_T8ckTCu28gKNSl

> **Base URL**: `https://d17362b1w27h09.cloudfront.net`
> 
> **Authentication**: AWS Cognito Bearer Token (unless specified otherwise)
> 
> **Version**: 1.0

## Table of Contents

- [Authentication](#authentication)
- [Media APIs](#media-apis)
- [Album APIs](#album-apis)
- [Library APIs](#library-apis)
- [Dashboard APIs](#dashboard-apis)
- [Common Schemas](#common-schemas)
- [Error Responses](#error-responses)

---

## Authentication

Most endpoints require authentication via AWS Cognito. Include the access token in the `Authorization` header:

```
Authorization: Bearer <your_access_token>
```

---

## Media APIs

Base path: `/api/media`

### 1. Browse All Media

Get a paginated list of all public media.

| Property | Value |
|----------|-------|
| **Endpoint** | `/api/media` |
| **Method** | `GET` |
| **Authentication** | Optional |

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `page` | integer | No | 0 | Page number (zero-indexed) |
| `size` | integer | No | 20 | Number of items per page |
| `sort` | string | No | - | Sort field and direction (e.g., `createdAt,desc`) |

**Response:** `Page<MediaResponse>`

```json
{
  "content": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "title": "Sample Song",
      "description": "A sample audio track",
      "mediaType": "AUDIO",
      "status": "PUBLISHED",
      "visibility": "PUBLIC",
      "hlsUrl": "https://example.com/audio/sample/sample_audio.m3u8",
      "thumbnailUrl": "https://example.com/thumbnails/sample.jpg",
      "lyricsUrl": "https://example.com/lyrics/sample.lrc",
      "createdAt": "2026-01-20T10:00:00Z",
      "updatedAt": "2026-01-20T10:00:00Z",
      "linkedMediaId": null,
      "artist": {
        "id": 1,
        "name": "Artist Name",
        "genre": "Pop",
        "imageUrl": "https://example.com/artists/1.jpg",
        "verified": true
      },
      "album": {
        "id": 1,
        "name": "Album Name",
        "description": "Album description",
        "coverImageUrl": "https://example.com/albums/1.jpg"
      },
      "linkedMedia": null
    }
  ],
  "pageable": {
    "pageNumber": 0,
    "pageSize": 20
  },
  "totalElements": 100,
  "totalPages": 5,
  "last": false
}
```

---

### 2. Search Media

Search for media by query string.

| Property | Value |
|----------|-------|
| **Endpoint** | `/api/media/search` |
| **Method** | `GET` |
| **Authentication** | Optional |

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `query` | string | No | - | Search query for title or description |
| `page` | integer | No | 0 | Page number (zero-indexed) |
| `size` | integer | No | 20 | Number of items per page |
| `sort` | string | No | - | Sort field and direction |

**Response:** `Page<MediaResponse>`

**Example Request:**
```
GET /api/media/search?query=love&page=0&size=10
```

---

### 3. Record Media Play

Record a play event for analytics and history.

| Property | Value |
|----------|-------|
| **Endpoint** | `/api/media/{id}/play` |
| **Method** | `POST` |
| **Authentication** | Optional (tracked if authenticated) |

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | UUID | Yes | Media ID |

**Request Body:** (Optional)

```json
{
  "position": 45
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `position` | integer | No | Playback position in seconds |

**Response:** `200 OK` (empty body)

**Error Responses:**
- `401 Unauthorized` - Invalid authentication
- `500 Internal Server Error` - Server error

---

### 4. Toggle Like/Unlike Media

Like or unlike a media item. Returns the new like status.

| Property | Value |
|----------|-------|
| **Endpoint** | `/api/media/{id}/like` |
| **Method** | `POST` |
| **Authentication** | Required |

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | UUID | Yes | Media ID |

**Response:**

```json
{
  "liked": true,
  "likeCount": 1523
}
```

| Field | Type | Description |
|-------|------|-------------|
| `liked` | boolean | Whether the current user has liked this media |
| `likeCount` | long | Total number of likes |

**Error Responses:**
- `401 Unauthorized` - User not authenticated
- `500 Internal Server Error` - Server error

---

### 5. Get Like Status

Get the like status for a media item.

| Property | Value |
|----------|-------|
| **Endpoint** | `/api/media/{id}/like` |
| **Method** | `GET` |
| **Authentication** | Optional |

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | UUID | Yes | Media ID |

**Response:**

```json
{
  "liked": true,
  "likeCount": 1523
}
```

---

### 6. Get Liked Media

Get all media liked by the current user.

| Property | Value |
|----------|-------|
| **Endpoint** | `/api/media/liked` |
| **Method** | `GET` |
| **Authentication** | Required |

**Response:** `List<MediaResponse>`

**Error Responses:**
- `500 Internal Server Error` - Server error

---

## Album APIs

Base path: `/api/albums`

### 1. Get All Albums

Get all active albums.

| Property | Value |
|----------|-------|
| **Endpoint** | `/api/albums` |
| **Method** | `GET` |
| **Authentication** | Optional |

**Response:** `List<AlbumResponse>`

```json
[
  {
    "id": 1,
    "name": "Studio Album Vol. 1",
    "description": "First studio album",
    "coverImageUrl": "https://example.com/albums/1.jpg",
    "trackCount": 12
  }
]
```

---

### 2. Search Albums

Search albums by name.

| Property | Value |
|----------|-------|
| **Endpoint** | `/api/albums/search` |
| **Method** | `GET` |
| **Authentication** | Optional |

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `query` | string | No | - | Search query for album name |
| `page` | integer | No | 0 | Page number |
| `size` | integer | No | 20 | Page size |

**Response:** `Page<AlbumResponse>`

---

### 3. Get Album Details

Get detailed information about an album including all tracks.

| Property | Value |
|----------|-------|
| **Endpoint** | `/api/albums/{id}` |
| **Method** | `GET` |
| **Authentication** | Optional |

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | Long | Yes | Album ID |

**Response:**

```json
{
  "id": 1,
  "name": "Studio Album Vol. 1",
  "description": "First studio album",
  "coverImageUrl": "https://example.com/albums/1.jpg",
  "createdAt": "2026-01-01T00:00:00Z",
  "trackCount": 12,
  "tracks": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "title": "Track 1",
      ...
    }
  ]
}
```

**Error Responses:**
- `404 Not Found` - Album not found or inactive

---

## Library APIs

Base path: `/api/user/library`

> All library endpoints require authentication.

### 1. Get Complete Library Data

Get all library data (playlists, artists, albums, favorites, recently played) in one request.

| Property | Value |
|----------|-------|
| **Endpoint** | `/api/user/library` |
| **Method** | `GET` |
| **Authentication** | Required |

**Response:**

```json
{
  "playlists": [...],
  "artists": [...],
  "albums": [...],
  "favorites": [...],
  "recentlyPlayed": [...]
}
```

---

### 2. Get User Playlists

Get all playlists created by the current user.

| Property | Value |
|----------|-------|
| **Endpoint** | `/api/user/library/playlists` |
| **Method** | `GET` |
| **Authentication** | Required |

**Response:** `List<PlaylistResponse>`

```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "My Favorites",
    "description": "My favorite songs",
    "coverUrl": "https://example.com/playlists/cover.jpg",
    "trackCount": 25,
    "isPublic": false
  }
]
```

---

### 3. Create Playlist

Create a new playlist.

| Property | Value |
|----------|-------|
| **Endpoint** | `/api/user/library/playlists` |
| **Method** | `POST` |
| **Authentication** | Required |

**Request Body:**

```json
{
  "name": "Workout Mix",
  "description": "High energy workout songs"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Playlist name |
| `description` | string | No | Playlist description |

**Response:** `PlaylistResponse`

**Error Responses:**
- `400 Bad Request` - Invalid request

---

### 4. Delete Playlist

Delete a user's playlist.

| Property | Value |
|----------|-------|
| **Endpoint** | `/api/user/library/playlists/{id}` |
| **Method** | `DELETE` |
| **Authentication** | Required |

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | UUID | Yes | Playlist ID |

**Response:** `200 OK` (empty body)

**Error Responses:**
- `400 Bad Request` - Error deleting playlist
- `401 Unauthorized` - Not the playlist owner
- `404 Not Found` - Playlist not found

---

### 5. Get Playlist Tracks

Get all tracks in a playlist.

| Property | Value |
|----------|-------|
| **Endpoint** | `/api/user/library/playlists/{id}/tracks` |
| **Method** | `GET` |
| **Authentication** | Required |

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | UUID | Yes | Playlist ID |

**Response:** `List<MediaResponse>`

**Error Responses:**
- `400 Bad Request` - Error fetching tracks
- `404 Not Found` - Playlist not found

---

### 6. Add Track to Playlist

Add a media item to a playlist.

| Property | Value |
|----------|-------|
| **Endpoint** | `/api/user/library/playlists/{id}/tracks` |
| **Method** | `POST` |
| **Authentication** | Required |

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | UUID | Yes | Playlist ID |

**Request Body:**

```json
{
  "mediaId": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Response:** `200 OK` (empty body)

**Error Responses:**
- `400 Bad Request` - Invalid request
- `401 Unauthorized` - Not the playlist owner
- `404 Not Found` - Playlist or media not found

---

### 7. Remove Track from Playlist

Remove a media item from a playlist.

| Property | Value |
|----------|-------|
| **Endpoint** | `/api/user/library/playlists/{id}/tracks/{mediaId}` |
| **Method** | `DELETE` |
| **Authentication** | Required |

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | UUID | Yes | Playlist ID |
| `mediaId` | UUID | Yes | Media ID to remove |

**Response:** `200 OK` (empty body)

**Error Responses:**
- `400 Bad Request` - Error removing track
- `401 Unauthorized` - Not the playlist owner

---

### 8. Get User Artists

Get artists from the user's listening history.

| Property | Value |
|----------|-------|
| **Endpoint** | `/api/user/library/artists` |
| **Method** | `GET` |
| **Authentication** | Required |

**Response:** `List<ArtistResponse>`

```json
[
  {
    "id": 1,
    "name": "Artist Name",
    "imageUrl": "https://example.com/artists/1.jpg",
    "genre": "Pop",
    "verified": true
  }
]
```

---

### 9. Get All Artists

Get all active artists (not user-specific).

| Property | Value |
|----------|-------|
| **Endpoint** | `/api/user/library/artists/all` |
| **Method** | `GET` |
| **Authentication** | Optional |

**Response:** `List<ArtistResponse>`

---

### 10. Get Artist Tracks

Get all tracks by a specific artist.

| Property | Value |
|----------|-------|
| **Endpoint** | `/api/user/library/artists/{id}/tracks` |
| **Method** | `GET` |
| **Authentication** | Optional |

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | Long | Yes | Artist ID |

**Response:** `List<MediaResponse>`

**Error Responses:**
- `400 Bad Request` - Error fetching tracks
- `404 Not Found` - Artist not found

---

### 11. Get User Albums

Get albums from the user's listening history.

| Property | Value |
|----------|-------|
| **Endpoint** | `/api/user/library/albums` |
| **Method** | `GET` |
| **Authentication** | Required |

**Response:** `List<AlbumResponse>`

```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "title": "Album Title",
    "artistName": "Artist Name",
    "coverUrl": "https://example.com/albums/cover.jpg",
    "trackCount": 1
  }
]
```

---

### 12. Get Favorites

Get all media liked by the current user.

| Property | Value |
|----------|-------|
| **Endpoint** | `/api/user/library/favorites` |
| **Method** | `GET` |
| **Authentication** | Required |

**Response:** `List<MediaResponse>`

---

## Dashboard APIs

Base path: `/api/user/dashboard`

### 1. Get Dashboard Data

Get all dashboard data including latest releases, popular tracks, recently played, and recommended artists.

| Property | Value |
|----------|-------|
| **Endpoint** | `/api/user/dashboard` |
| **Method** | `GET` |
| **Authentication** | Optional (personalized if authenticated) |

**Response:**

```json
{
  "latestReleases": [...],
  "popularTracks": [...],
  "recentlyPlayed": [...],
  "recommendedArtists": [...]
}
```

---

### 2. Get Latest Releases

Get the latest released media.

| Property | Value |
|----------|-------|
| **Endpoint** | `/api/user/dashboard/latest` |
| **Method** | `GET` |
| **Authentication** | Optional |

**Response:** `List<MediaResponse>`

---

### 3. Get Popular Tracks

Get popular tracks with pagination.

| Property | Value |
|----------|-------|
| **Endpoint** | `/api/user/dashboard/popular` |
| **Method** | `GET` |
| **Authentication** | Optional |

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `page` | integer | No | 0 | Page number |
| `size` | integer | No | 10 | Page size |

**Response:** `List<MediaResponse>`

---

### 4. Get Recently Played

Get the user's recently played tracks.

| Property | Value |
|----------|-------|
| **Endpoint** | `/api/user/dashboard/history` |
| **Method** | `GET` |
| **Authentication** | Required |

**Response:** `List<MediaResponse>`

---

## Common Schemas

### MediaResponse

```typescript
{
  id: UUID,
  title: string,
  description: string,
  mediaType: "AUDIO" | "VIDEO",
  status: "DRAFT" | "PROCESSING" | "PUBLISHED" | "FAILED",
  visibility: "PUBLIC" | "PRIVATE" | "UNLISTED",
  hlsUrl: string,           // HLS streaming URL
  thumbnailUrl: string,     // Thumbnail image URL
  lyricsUrl: string,        // LRC lyrics file URL (nullable)
  createdAt: Instant,       // ISO 8601 timestamp
  updatedAt: Instant,       // ISO 8601 timestamp
  linkedMediaId: UUID,      // For audio-video linking (nullable)
  artist: ArtistInfo,       // Nested artist information
  album: AlbumInfo,         // Nested album information (nullable)
  linkedMedia: LinkedMediaInfo  // Linked media details (nullable)
}
```

### ArtistInfo

```typescript
{
  id: Long,
  name: string,
  genre: string,
  imageUrl: string,
  verified: boolean
}
```

### AlbumInfo

```typescript
{
  id: Long,
  name: string,
  description: string,
  coverImageUrl: string
}
```

### LinkedMediaInfo

```typescript
{
  id: UUID,
  title: string,
  mediaType: "AUDIO" | "VIDEO",
  thumbnailUrl: string,
  hlsUrl: string,
  artist: ArtistInfo
}
```

### PlaylistResponse

```typescript
{
  id: string,           // UUID as string
  name: string,
  description: string,
  coverUrl: string,
  trackCount: integer,
  isPublic: boolean
}
```

### ArtistResponse

```typescript
{
  id: Long,
  name: string,
  imageUrl: string,
  genre: string,
  verified: boolean
}
```

### AlbumResponse

```typescript
{
  id: string,           // Can be UUID or Long as string
  title: string,        // Or "name" depending on context
  artistName: string,   // For library albums
  coverUrl: string,
  trackCount: integer
}
```

### AlbumDetailResponse

```typescript
{
  id: Long,
  name: string,
  description: string,
  coverImageUrl: string,
  createdAt: Instant,
  trackCount: integer,
  tracks: MediaResponse[]
}
```

### LibraryDataResponse

```typescript
{
  playlists: PlaylistResponse[],
  artists: ArtistResponse[],
  albums: AlbumResponse[],
  favorites: MediaResponse[],
  recentlyPlayed: MediaResponse[]
}
```

### LikeResponse

```typescript
{
  liked: boolean,
  likeCount: long
}
```

---

## Error Responses

### Standard Error Response

```json
{
  "timestamp": "2026-01-26T13:00:00Z",
  "status": 400,
  "error": "Bad Request",
  "message": "Validation failed",
  "path": "/api/user/library/playlists"
}
```

### Common HTTP Status Codes

| Code | Description |
|------|-------------|
| `200 OK` | Successful request |
| `400 Bad Request` | Invalid request parameters or body |
| `401 Unauthorized` | Missing or invalid authentication token |
| `403 Forbidden` | Authenticated but not authorized for this resource |
| `404 Not Found` | Requested resource not found |
| `500 Internal Server Error` | Server error |

---

## Enums

### MediaType

- `AUDIO` - Audio track
- `VIDEO` - Video content

### MediaStatus

- `DRAFT` - Not yet published
- `PROCESSING` - Being processed
- `PUBLISHED` - Available to users
- `FAILED` - Processing failed

### MediaVisibility

- `PUBLIC` - Visible to all users
- `PRIVATE` - Only visible to owner
- `UNLISTED` - Accessible via direct link only

---

## Pagination

Endpoints that return `Page<T>` support Spring Data pagination:

**Query Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `page` | integer | 0 | Zero-indexed page number |
| `size` | integer | 20 | Number of items per page |
| `sort` | string | - | Sort specification (e.g., `createdAt,desc`) |

**Response Structure:**

```json
{
  "content": [...],          // Array of items
  "pageable": {
    "pageNumber": 0,
    "pageSize": 20,
    "sort": {...}
  },
  "totalElements": 100,      // Total number of items
  "totalPages": 5,           // Total number of pages
  "last": false,             // Is this the last page?
  "first": true,             // Is this the first page?
  "numberOfElements": 20,    // Number of items in this page
  "size": 20,
  "number": 0,
  "empty": false
}
```

---

## Notes

1. **Authentication**: Most endpoints support optional authentication. When authenticated, responses may include personalized data (e.g., like status).

2. **UUIDs**: Media IDs and Playlist IDs use UUID format. Album and Artist IDs use Long (integer) format.

3. **HLS Streaming**: Media is served via HLS (HTTP Live Streaming). Audio and video have different URL patterns:
   - Audio: `{audioHlsBase}/{keyWithoutExtension}/{fileName}_audio.m3u8`
   - Video: `{videoHlsBase}/{keyWithoutExtension}/{fileName}.m3u8`

4. **Lyrics**: lyrics are available at the `lyricsUrl` when present.

5. **Linked Media**: Audio and video can be linked via `linkedMediaId` for providing both formats of the same content.

6. **Timestamps**: All timestamps are in ISO 8601 format (UTC).
