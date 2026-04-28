# User Channel Upload and Media APIs Reference

## Scope

This document covers the channel management and media upload functionality in the `UserChannelController`. This includes:

- Channel creation and updates.
- Channel profile image uploads.
- Music (Audio) and Video uploads for user channels.
- Media management (Listing and Deletion).

The content below is based on the current implementation in `UserChannelController`, `ChannelService`, and related DTO classes.

## Source Files Analysed

Controllers:

- `src/main/java/com/veena/veenabackend/controller/UserChannelController.java`

Support classes:

- `src/main/java/com/veena/veenabackend/service/ChannelService.java`
- `src/main/java/com/veena/veenabackend/dto/ChannelRequest.java`
- `src/main/java/com/veena/veenabackend/dto/ChannelResponse.java`
- `src/main/java/com/veena/veenabackend/dto/UserMediaResponse.java`
- `src/main/java/com/veena/veenabackend/enums/MediaType.java`
- `src/main/java/com/veena/veenabackend/enums/MediaStatus.java`
- `src/main/java/com/veena/veenabackend/enums/ApprovalStatus.java`

## Authentication and Access Rules

- All endpoints under `/api/user/channel` require a valid user JWT token.
- In non-local environments, these are protected by Spring Security and require authentication.
- Users can only manage their own channel and media.

---

## Shared DTO Schemas

### `ChannelRequest`

```json
{
  "channelName": "My Awesome Channel",
  "channelHandle": "awesome-channel",
  "description": "Welcome to my channel where I upload my music."
}
```

### `ChannelResponse`

```json
{
  "id": "uuid",
  "userId": "uuid",
  "userName": "John Doe",
  "userEmail": "john@example.com",
  "channelName": "My Awesome Channel",
  "channelHandle": "awesome-channel",
  "description": "Welcome to my channel where I upload my music.",
  "imageUrl": "https://cdn.example.com/profiles/image.jpg",
  "active": true,
  "subscriberCount": 0,
  "totalViews": 0,
  "createdAt": "2026-04-26T10:00:00Z",
  "updatedAt": "2026-04-26T10:00:00Z",
  "totalMedia": 5,
  "pendingMedia": 2,
  "approvedMedia": 3
}
```

### `UserMediaResponse`

```json
{
  "id": "uuid",
  "title": "My New Song",
  "description": "A beautiful melody.",
  "mediaType": "AUDIO",
  "status": "READY",
  "approvalStatus": "PENDING",
  "rejectionReason": null,
  "hlsUrl": "https://cdn.example.com/hls/audio/path/song_audio.m3u8",
  "thumbnailUrl": "https://cdn.example.com/thumbnails/song_thumb.jpg",
  "fileSize": 5242880,
  "fileExtension": "mp3",
  "playCount": 0,
  "durationSeconds": 180,
  "createdAt": "2026-04-26T10:00:00Z",
  "updatedAt": "2026-04-26T10:00:00Z",
  "reviewedAt": null,
  "channelId": "uuid",
  "channelName": "My Awesome Channel",
  "uploadedById": "uuid",
  "uploadedByName": "John Doe",
  "uploadedByEmail": "john@example.com"
}
```

---

## Enums

### `MediaType`
- `VIDEO`
- `AUDIO`

### `MediaStatus`
- `UPLOADING`: File is being uploaded to S3.
- `PROCESSING`: Transcoding (HLS) is in progress.
- `READY`: Media is ready for playback.
- `FAILED`: Processing or upload failed.

### `ApprovalStatus`
- `PENDING`: Waiting for admin review.
- `APPROVED`: Visible to public.
- `REJECTED`: Not visible, uploader notified.

---

## Controller-by-Controller API List

---

## 1. UserChannelController (Upload & Management)

Base path: `/api/user/channel`

### 1.1 Get or Create Channel

- Method: `GET`
- Path: `/api/user/channel`
- Success response: `200 OK` with `ChannelResponse`
- Behavior:
  - Returns the current user's channel.
  - If no channel exists, it auto-creates one with default settings based on user profile.

### 1.2 Create Channel (Custom)

- Method: `POST`
- Path: `/api/user/channel`
- Body: `ChannelRequest`
- Success response: `200 OK` with `ChannelResponse`
- Error cases:
  - `400 Bad Request`: If `channelHandle` is already taken or invalid.

### 1.3 Update Channel Details

- Method: `PUT`
- Path: `/api/user/channel`
- Body: `ChannelRequest`
- Success response: `200 OK` with `ChannelResponse`

### 1.4 Upload Channel Image

- Method: `POST`
- Path: `/api/user/channel/image`
- Request type: `multipart/form-data`
- Body (Form Data):
  - `file`: `MultipartFile`, required (The profile image)
- Success response: `200 OK` with updated `ChannelResponse`

### 1.5 Upload Media (Music/Video)

- Method: `POST`
- Path: `/api/user/channel/media/upload`
- Request type: `multipart/form-data`
- Body (Form Data):
  - `title`: `String`, required
  - `description`: `String`, optional
  - `mediaType`: `MediaType` (AUDIO or VIDEO), required
  - `file`: `MultipartFile`, required (The actual audio/video file)
  - `thumbnail`: `MultipartFile`, optional (Cover art or video thumbnail)
- Success response: `200 OK` with `UserMediaResponse`
- Behavior:
  - Creates a media entry with `PENDING` approval status and `UPLOADING` status.
  - Triggers background processing for HLS transcoding.

### 1.6 List My Media

- Method: `GET`
- Path: `/api/user/channel/media`
- Query params:
  - `status`: `String`, optional (Filter by `PENDING`, `APPROVED`, or `REJECTED`)
  - `page`: `int`, optional
  - `size`: `int`, optional
  - `sort`: `String`, optional
- Success response: `200 OK` with `Page<UserMediaResponse>`

### 1.7 Delete My Media

- Method: `DELETE`
- Path: `/api/user/channel/media/{mediaId}`
- Path params:
  - `mediaId`: `UUID`, required
- Success response: `204 No Content`
- Rules:
  - Can only delete media that is currently in `PENDING` or `REJECTED` status.
  - Approved media deletion might require admin intervention or a different flow (check business rules).

### 1.8 View Public Channel

- Method: `GET`
- Path: `/api/user/channel/public/{channelId}`
- Path params:
  - `channelId`: `UUID`, required
- Success response: `200 OK` with `ChannelResponse`
- Error cases:
  - `404 Not Found`: If channel ID does not exist.

### 1.9 Browse Public Channel Media

- Method: `GET`
- Path: `/api/user/channel/public/{channelId}/media`
- Path params:
  - `channelId`: `UUID`, required
- Query params:
  - `page`, `size`, `sort`
- Success response: `200 OK` with `Page<UserMediaResponse>`
- Behavior:
  - Returns only `APPROVED` media for the specified channel.
