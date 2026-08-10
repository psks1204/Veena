# Custom Audio Ad System — Lock Screen Compatible

## Problem
Google AdMob banner ads are visual-only and stop rendering when the screen is locked. Since Veena is primarily a music app where users listen with the screen off, banner ads provide zero revenue during the most active usage period. We need **custom audio/video ads** that the admin can upload via the admin panel, and the Flutter app plays them **between songs** — working even when the screen is locked.

## Existing Infrastructure (Already Built ✅)

Investigating the codebase revealed that a significant portion of the backend is **already built**:

| Component | Status | Details |
|-----------|--------|---------|
| `FeaturedContentEntity` | ✅ Built | JPA entity with `contentType` (`AUDIO_AD`, `VIDEO_AD`, `IMAGE_AD`), `adMediaUrl`, `adImageUrl`, scheduling fields |
| `AdminFeaturedController` | ✅ Built | `POST /api/admin/featured/ad` — multipart upload for ad file + image to S3 |
| `FeaturedController` (public) | ✅ Built | `GET /api/featured/active/ads` — returns active ads to mobile app |
| `FeaturedContentResponse` DTO | ✅ Built | Returns `adMediaUrl`, `adImageUrl`, `contentType`, scheduling info |
| Featured Content Admin Page | ✅ Built | [featured-content.component.ts](file:///Users/w7hyydv/workspace/dgfly/veena/veena-admin/src/app/pages/featured-content/featured-content.component.ts) — full CRUD for ads with IMAGE_AD, VIDEO_AD, AUDIO_AD types |
| `VeenaAudioHandler` | ✅ Built | Background audio with lock screen controls via `audio_service` |
| `PlayerProvider._onTrackCompleted()` | ✅ Built | Auto-advance hook — perfect insertion point for ads |

> [!IMPORTANT]
> The backend and admin panel already support uploading audio/video ads. The **only missing piece** is the Flutter app consuming and playing these ads between songs.

## What Needs to Be Built

### Flutter App Only — 4 Components

---

### 1. Custom Ad Service (`custom_ad_service.dart`)

#### [NEW] [custom_ad_service.dart](file:///Users/w7hyydv/workspace/dgfly/veena/Veena/lib/core/services/custom_ad_service.dart)

A service that fetches active audio/video ads from the backend and manages ad rotation:

- Call `GET /api/featured/active/ads` on app start + periodic refresh (every 30 min)
- Cache the list of active `AUDIO_AD` entries
- Provide `getNextAudioAd()` — returns the next ad to play (round-robin rotation)
- Track ad impressions (optional: `POST /api/featured/{id}/impression` — can add this backend endpoint later)
- Respect subscription status: if user is subscribed (no-ads), never return an ad

**Key fields from backend response used:**
```json
{
  "id": "uuid",
  "contentType": "AUDIO_AD",
  "title": "Sponsor Ad - Brand X",
  "adMediaUrl": "https://cdn.../ads/brand-x.mp3",
  "adImageUrl": "https://cdn.../ads/brand-x-thumb.jpg",
  "isActive": true
}
```

---

### 2. Integrate Ad Playback into PlayerProvider

#### [MODIFY] [player_provider.dart](file:///Users/w7hyydv/workspace/dgfly/veena/Veena/lib/core/providers/player_provider.dart)

Inject ad playback into the `_onTrackCompleted()` flow:

- Add a `CustomAdService` dependency (injected via setter like `setMediaService`)
- Add a counter: play an audio ad every **N songs** (configurable, default: every 3 songs)
- When `_onTrackCompleted()` fires and it's time for an ad:
  1. Get next audio ad from `CustomAdService.getNextAudioAd()`
  2. Play the ad audio URL via `VeenaAudioHandler` (same `playFromUri` flow)
  3. Update lock screen notification to show "Ad — [Title]" with ad thumbnail
  4. When ad completes → auto-advance to the next song in queue
  5. **Disable skip/seek** during ad playback (optional, configurable)
- Add `_isPlayingAd` flag so UI can show ad indicator

**Lock screen behavior:** Since we play ads through the same `VeenaAudioHandler` → `just_audio` pipeline, ads automatically play through the lock screen notification — no extra work needed.

---

### 3. Ad Indicator UI Widget

#### [NEW] [audio_ad_overlay.dart](file:///Users/w7hyydv/workspace/dgfly/veena/Veena/lib/shared/widgets/audio_ad_overlay.dart)

When an ad is playing, show an overlay on the player screen:

- "Ad playing — [title]" banner with ad thumbnail
- Countdown timer showing remaining seconds
- "Skip Ad" button (appears after 5 seconds, if skip is enabled)
- Transparent overlay so the user knows what's happening

#### [MODIFY] Player UI screens

- Check `playerProvider.isPlayingAd` flag
- When `true`, show the ad overlay and disable seek bar
- When `false`, show normal player controls

---

### 4. Wire Up in Main App

#### [MODIFY] [main.dart](file:///Users/w7hyydv/workspace/dgfly/veena/Veena/lib/main.dart)

- Create `CustomAdService` instance
- Pass it to `PlayerProvider` via `setCustomAdService()`
- Fetch ads on app startup

---

## User Review Required

> [!IMPORTANT]
> **Ad Frequency:** How often should audio ads play between songs? Recommended: **every 3 songs**. Should this be configurable from the admin panel, or is a hardcoded default fine for now?

> [!IMPORTANT]
> **Skip Ad:** Should users be able to skip audio ads after 5 seconds (like YouTube), or must they listen to the full ad? Recommended: Allow skip after 5 seconds.

> [!IMPORTANT]  
> **Ad Type Scope:** The backend already supports `VIDEO_AD`, `AUDIO_AD`, and `IMAGE_AD`. For the lock screen use case, only `AUDIO_AD` makes sense. Should we also support `VIDEO_AD` playback between songs when the app is in the foreground (video ads would pause if screen is locked)?

## Open Questions

> [!NOTE]
> The existing admin panel Featured Content page (`/admin/featured`) already has full CRUD for uploading audio ads. Do you want any changes to that admin page, or is it working well for ad uploads?

> [!NOTE]
> Currently there's no backend endpoint to track ad impressions/plays. Should we add a `POST /api/featured/{id}/impression` endpoint to track how many times each ad was played? This would be useful for advertiser reporting.

## Proposed Changes

### Flutter App — Custom Ad Service

#### [NEW] [custom_ad_service.dart](file:///Users/w7hyydv/workspace/dgfly/veena/Veena/lib/core/services/custom_ad_service.dart)
- Fetch active audio ads from `GET /api/featured/active/ads`
- Round-robin ad rotation with `getNextAudioAd()`
- Periodic refresh (30 min cache TTL)
- Respects subscription status

---

### Flutter App — PlayerProvider Integration

#### [MODIFY] [player_provider.dart](file:///Users/w7hyydv/workspace/dgfly/veena/Veena/lib/core/providers/player_provider.dart)
- Add `CustomAdService` dependency via `setCustomAdService()`
- Add `_isPlayingAd`, `_currentAd`, `_songsSinceLastAd` fields
- Modify `_onTrackCompleted()` to check if ad should play before advancing
- Add `_playAudioAd()` method that plays ad through existing audio pipeline
- Add `skipAd()` method (if skip is enabled)
- After ad finishes → resume normal queue playback

---

### Flutter App — Ad UI Widget

#### [NEW] [audio_ad_overlay.dart](file:///Users/w7hyydv/workspace/dgfly/veena/Veena/lib/shared/widgets/audio_ad_overlay.dart)
- Visual indicator during ad playback
- Countdown timer, ad title, thumbnail
- Optional "Skip Ad" button after 5 seconds

---

### Flutter App — Wiring

#### [MODIFY] [main.dart](file:///Users/w7hyydv/workspace/dgfly/veena/Veena/lib/main.dart)
- Initialize `CustomAdService` and inject into `PlayerProvider`

---

## Verification Plan

### Manual Verification
1. Upload an `AUDIO_AD` via the admin panel at `/admin/featured` (this already works)
2. Run the Flutter app on emulator
3. Play 3 songs → verify audio ad plays automatically between songs 3 and 4
4. Lock the screen during music playback → verify audio ad still plays through lock screen notification
5. Verify lock screen notification shows "Ad — [title]" during ad playback
6. Verify "Skip Ad" button works after 5 seconds (if enabled)
7. Verify subscribed users never hear audio ads
8. Verify ad auto-advances to next song after completing

### Automated Tests
```bash
# Build APK to verify compilation
cd /Users/w7hyydv/workspace/dgfly/veena/Veena && flutter build apk --release
```
