# Web ads (AdSense)

Mobile serves ads through AdMob; the web build serves them through AdSense.
Both are switched off for a no-ads subscriber by the same gate
(`AdsService.setAdsEnabled`, driven by `SubscriptionProvider`).

## Configuration

All web build values live in [`env/web.json`](../env/web.json) and are passed in
one flag:

```bash
flutter build web --release --dart-define-from-file=env/web.json
```

| Key | Meaning |
| --- | --- |
| `APP_ENV` | Backend environment. |
| `RAZORPAY_KEY_ID` | Razorpay public key for web checkout. |
| `ADSENSE_CLIENT` | Publisher id. **Must** equal the `client=` value in the loader script in `web/index.html`. |
| `ADSENSE_SLOT_DISPLAY` | `data-ad-slot` of the Display unit. Ads stay hidden while empty. |
| `ADSENSE_SLOT_INFEED` | `data-ad-slot` of the In-feed unit. |
| `ADSENSE_INFEED_LAYOUT_KEY` | `data-ad-layout-key` generated with the in-feed unit. It will not render without this. |

## Which unit goes where

| Placement | Unit | Why |
| --- | --- | --- |
| Featured carousel ad card | In-feed (`3354956458`) | A card among content cards — exactly the in-feed use case. Height comes from the layout key, so the widget adopts whatever height is served, capped so the card cannot overflow. |
| Player ad rotator | Display (`3611087263`) | A fixed banner strip below the player. |
| Player artwork swap | Display (`3611087263`) | Fixed box in place of the album art. |

The display unit is created responsive, but these placements give it an explicit
width and height and omit `data-ad-format`, so it serves at the reserved size
instead of picking its own and overflowing the Flutter box.

Individual values can still be overridden per build; a later `--dart-define`
wins over the file:

```bash
flutter build web --release --dart-define-from-file=env/web.json \
  --dart-define=ADSENSE_SLOT_DISPLAY=1234567890
```

### Adding or replacing a unit

AdSense → **Ads** → **By ad unit** → create the unit and copy the values out of
the generated snippet:

```html
<ins class="adsbygoogle"
     data-ad-client="ca-pub-8580707712580721"
     data-ad-slot="3611087263"></ins>
```

The slot id is digits only — not the ad unit's name and not the `ca-pub-…` id.
A wrong shape is rejected at startup with an explanation in the console rather
than silently serving nothing.

Only **one** loader `<script>` belongs on the page. The snippets AdSense
generates each repeat it; `web/index.html` already has it, so paste only the
slot values here, never the extra script tags.

## Why the app builds the ad markup itself

The loader script alone never renders an ad, and Auto ads cannot help: they scan
the page's HTML for insertion points, and Flutter web paints into a canvas with
no markup to scan. [`adsense_ad_unit_web.dart`](../lib/shared/widgets/adsense_ad_unit_web.dart)
creates each `<ins class="adsbygoogle">` itself, mounts it as a platform view
(which keeps it in the light DOM where Google can measure it), and pushes one
fill request per element.

## Before ads can serve

1. The domain is added under AdSense → **Sites** and shows **Ready**.
2. `ads.txt` is reachable at the site root — [`web/ads.txt`](../web/ads.txt) is
   copied to `build/web/ads.txt` by the build. (`app-ads.txt` is the mobile
   apps' equivalent and does not cover the website.)
3. You are testing on that domain. **AdSense never fills on localhost**, so a
   local run always ends in `unfilled` — that is expected, not a bug.

## Reading the console

Every message is prefixed `[AdSense]`:

| Message | Meaning |
| --- | --- |
| `slot … mounted at 1216x50` | Element created at that size. |
| `requested slot … (queued=true)` | Fill request accepted by Google's queue. |
| `came back unfilled` | Google answered, declined to fill. On a live domain this is inventory/approval, not code. |
| `no ad unit configured` | `ADSENSE_SLOT_DISPLAY` is empty. |
| `configuration ignored — …` | The client or slot id is malformed. |
| `publisher id mismatch` | `ADSENSE_CLIENT` disagrees with the loader tag in `web/index.html`. |
| `loader script blocked (ad blocker?)` | `adsbygoogle.js` failed to load. |
| `placement is only Npx wide … hiding it` | Laid out and on screen but below AdSense's ~120px minimum; the slot collapses instead of erroring. |
| `never came on screen … still pending` | The slot stayed off-screen (e.g. a carousel page that was never swiped to). Nothing was requested; a later rebuild tries again. |

A slot is only requested once it is **on screen in a foreground tab**. An
off-screen platform view measures 0px wide in Flutter web, so requesting then
would be rejected by AdSense anyway — and an impression nobody could see counts
as invalid traffic.

An unfilled or blocked slot renders nothing at all, so the layout never keeps a
blank rectangle.
