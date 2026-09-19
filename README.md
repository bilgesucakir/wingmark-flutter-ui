# wingmark (Flutter)

Flutter port of the [wingmark](../wingmark) SwiftUI app — log the birds you've
seen, anywhere on a map — talking to the same deployed backend
([wingmark-backend](../wingmark-backend), live at
`https://wingmark-backend.onrender.com`).

This was scaffolded on a machine with **no Flutter SDK installed**, so only
`pubspec.yaml` + `lib/` exist so far — no `android/`, `ios/`, `web/`, etc.
Do this once Flutter is available (e.g. on your other Mac):

## First-time setup

```bash
# 1. Generate the missing platform folders in place (safe — it won't touch
#    the existing lib/ or pubspec.yaml, only adds android/ios/etc.)
flutter create .

# 2. Fetch packages
flutter pub get

# 3. Run it
flutter run
```

## Required platform permissions (add after step 1 above)

The app captures GPS location for sightings (`geolocator`) and picks photos
from the gallery (`image_picker`):

**Android** — `android/app/src/main/AndroidManifest.xml`, inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```
(`INTERNET` is already included by the default Flutter template.)

**iOS** — `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>wingmark uses your location to log where you saw a bird.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>wingmark needs photo access to attach a picture to a sighting.</string>
```

## Architecture notes

- **Backend integration is real**, not mocked — unlike the current Swift app
  (which only wires up `/api/auth/*` and `/api/users/{id}`, keeping bird
  sightings/species/badges in local SwiftData/hardcoded mocks). This Flutter
  client calls the full REST surface: `/api/bird-logs`, `/api/species`,
  `/api/badges`, `/api/uploads/photo`.
- **Auth**: JWT access/refresh pair persisted in `flutter_secure_storage`
  (`lib/core/token_store.dart`). `ApiClient` (`lib/core/api_client.dart`)
  transparently refreshes and retries once on a 401. Because
  `AuthResponseDto` has no embedded profile, the user id is read from the
  access token's `sub` claim (`jwt_decoder`), then `GET /api/users/{sub}`
  fetches the full profile — same pattern the Swift `BackendAuthService`
  uses.
- **Backend cold starts**: Render's starter plan sleeps the instance; the
  first request after idle can take up to ~60-90s. `ApiClient` uses a 90s
  timeout to match the Swift app's `URLSessionConfiguration` setting.
- **Localization**: hand-written (`lib/core/app_localizations.dart`),
  English/Turkish, no `flutter gen-l10n` step (that requires the Flutter
  tool, unavailable when this was scaffolded). Mirrors the Swift app's
  `AppLanguage` (System/English/Türkçe), persisted via `shared_preferences`.
- **Units**: unlike the Swift app (local-only `AppStorage`), unit preference
  here syncs with the backend via `GET`/`PUT /api/users/{id}/settings`.
- **Gaps intentionally filled in vs. the Swift app**: the original
  `AddSightingView` had no photo picker, no gender field, and no lat/lng
  capture at all — despite the backend *requiring* lat/lng on every bird log
  and already having a full photo-upload pipeline. This port adds all three
  (GPS auto-capture + tap-to-adjust map, gender picker, photo upload via
  `POST /api/uploads/photo`).
- Species/badge display text comes back from the backend as locale maps
  (e.g. `{"en": "...", "tr": "..."}`) — see `localizedText()` in
  `lib/models/species.dart`.
