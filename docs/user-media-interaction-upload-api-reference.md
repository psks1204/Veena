# User Media Interaction and S3 Upload APIs Reference

## Scope

This document covers the channel media interaction APIs (likes, comments, views, public feed) and the direct-to-S3 multipart upload flow for large media files (audio/video).

## Source Files Analysed

Controllers:

- `src/main/java/com/veena/veenabackend/controller/UserChannelController.java` (Interactions & Feed)
- `src/main/java/com/veena/veenabackend/controller/UserMediaUploadController.java` (S3 Multipart Upload)

---

## 1. UserChannelController (Interactions & Feed)

Base path: `/api/user/channel`

### 1.1 Public Feed

- Method: `GET`
- Path: `/api/user/channel/public/feed`
- Query params:
  - `page`, `size`
- Success response: `200 OK` with `Page<UserMediaResponse>`
- Behavior:
  - Returns all admin-approved media from all channels.
  - Ranked by trending algorithm (popularity, recency, channel authority).

### 1.2 Record Play Count

- Method: `POST`
- Path: `/api/user/channel/media/{mediaId}/play`
- Path params:
  - `mediaId`: `UUID`, required
- Success response: `200 OK` with `UserMediaResponse`
- Behavior:
  - Increments the play count when a user starts playing the media.

### 1.3 Toggle Like

- Method: `POST`
- Path: `/api/user/channel/media/{mediaId}/like`
- Path params:
  - `mediaId`: `UUID`, required
- Success response: `200 OK` with `Map<String, Object>` (e.g., `{ "liked": true, "likeCount": 10, "mediaId": "uuid" }`)
- Behavior:
  - Toggles the like status for the current user (likes if not liked, unlikes if already liked).

### 1.4 Check Like Status

- Method: `GET`
- Path: `/api/user/channel/media/{mediaId}/like`
- Path params:
  - `mediaId`: `UUID`, required
- Success response: `200 OK` with `Map<String, Object>` (e.g., `{ "liked": true, "mediaId": "uuid" }`)
- Behavior:
  - Returns whether the current authenticated user has liked the specified media.

### 1.5 Add Comment

- Method: `POST`
- Path: `/api/user/channel/media/{mediaId}/comments`
- Path params:
  - `mediaId`: `UUID`, required
- Body: `CommentRequest` (`{ "content": "Nice song!" }`)
- Success response: `200 OK` with `UserMediaCommentResponse`
- Behavior:
  - Adds a comment to the specified media.

### 1.6 Get Comments

- Method: `GET`
- Path: `/api/user/channel/media/{mediaId}/comments`
- Path params:
  - `mediaId`: `UUID`, required
- Query params:
  - `page`, `size`
- Success response: `200 OK` with `Page<UserMediaCommentResponse>`
- Behavior:
  - Returns paginated comments for a media, ordered newest first.

### 1.7 Delete Comment

- Method: `DELETE`
- Path: `/api/user/channel/media/{mediaId}/comments/{commentId}`
- Path params:
  - `mediaId`: `UUID`, required
  - `commentId`: `Long`, required
- Success response: `204 No Content`
- Behavior:
  - Deletes the user's own comment from a media.

---

## 2. UserMediaUploadController (S3 Multipart Upload)

Base path: `/api/user/channel/media/s3-upload`

This controller handles the preferred upload flow for large files (audio/video), allowing the frontend to upload directly to S3 via presigned URLs.

### 2.1 Initiate Upload

- Method: `POST`
- Path: `/api/user/channel/media/s3-upload/initiate`
- Body: `InitiateUploadRequest` (`{ "fileName": "song.mp3", "contentType": "audio/mpeg", "mediaType": "AUDIO" }`)
- Success response: `200 OK` with `InitiateUploadResponse` (`{ "uploadId": "...", "key": "...", "mediaId": "..." }`)
- Behavior:
  - Initiates an S3 multipart upload and returns the `uploadId`, `key`, and a pre-generated `mediaId`.

### 2.2 Get Presigned URLs

- Method: `POST`
- Path: `/api/user/channel/media/s3-upload/presigned-urls`
- Body: `PresignedUrlsRequest` (`{ "uploadId": "...", "key": "...", "partCount": 3 }`)
- Success response: `200 OK` with List of `PresignedPartUrlResult` (`[{ "partNumber": 1, "url": "https://s3..." }, ...]`)
- Behavior:
  - Generates presigned URLs for each part to allow direct frontend upload to S3.

### 2.3 Complete Upload

- Method: `POST`
- Path: `/api/user/channel/media/s3-upload/complete`
- Body: `CompleteUploadRequest`
  ```json
  {
    "uploadId": "...",
    "key": "...",
    "mediaId": "uuid",
    "title": "My Song",
    "description": "...",
    "mediaType": "AUDIO",
    "fileSize": 5242880,
    "parts": [{ "partNumber": 1, "eTag": "..." }]
  }
  ```
- Success response: `200 OK` with `UserMediaResponse`
- Behavior:
  - Creates the `user_media` record in the database first.
  - Completes the S3 multipart upload. The S3 event will then trigger the HLS conversion process.

### 2.4 Abort Upload

- Method: `POST`
- Path: `/api/user/channel/media/s3-upload/abort`
- Body: `AbortUploadRequest` (`{ "uploadId": "...", "key": "..." }`)
- Success response: `200 OK` with `{ "message": "Upload aborted" }`
- Behavior:
  - Aborts the S3 multipart upload and cleans up partial chunks on failure or cancellation.
