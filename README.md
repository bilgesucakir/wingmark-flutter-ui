# wingmark (Flutter)

Flutter port of the [wingmark](../wingmark) SwiftUI app — log the birds you've
seen, anywhere on a map — talking to the same deployed backend
([wingmark-backend](../wingmark-backend), live at
`https://wingmark-backend.onrender.com`). Unlike the Swift app, which only
ever wired up auth against the backend and kept sightings/species/badges in
local mocks, this client is fully backend-integrated end to end.

## Features

### Authentication
- Log in / Sign up
- Handles the backend's "login blocked until email verified" behavior: after
  registering, or if a login is rejected for an unverified account, the app
  shows a dedicated verify-your-email screen with a resend action
- JWT access/refresh tokens persisted in secure storage, with transparent
  refresh-and-retry on an expired access token — no user-visible re-login
- Log out (revokes the refresh token on the backend)

### Map
- Interactive map (OpenStreetMap tiles) plotting every one of the user's
  sightings
- Each pin shows that sighting's own photo, or a bundled bird-silhouette
  placeholder if none was attached
- Tapping a pin first focuses/centers the map on it, then opens a summary
  sheet (photo, name, date, location)
- Tapping the photo in that sheet opens the sighting's full detail screen
- Manual refresh button, plus auto-refresh whenever you switch back to this
  tab

### Guide (species catalog)
- Live search-as-you-type against the backend's species catalog
- Infinite scroll — loads the next page automatically as you near the bottom
  of the list
- Tapping a species opens a detail screen: photo carousel, localized
  description/habitat/diet/lifespan/size/conservation status/native range,
  and playable Xeno-canto sound recordings with license attribution
- Pull-to-refresh, plus auto-refresh on tab reselect

### Diary (sighting log)
- Chronological list of every sighting the user has logged, with
  swipe-to-delete
- Tapping a sighting opens its full detail (photo, species or custom name,
  date, location + a small map, life stage, gender, pet flag, notes) with an
  Edit action
- Logging a new sighting captures: date/time, GPS location (auto-captured,
  adjustable by tapping the map, or re-fetched on demand), species — searched
  and selected from the live catalog, with a "guess" vs. "confident"
  indicator, or an "I don't know" toggle for unidentified birds — life stage,
  gender, a pet flag, an optional custom name, a photo (picked from the
  gallery, previewable and removable), and free-text notes
- Editing reopens the same form pre-filled (including the existing photo) and
  saves via update instead of create
- Pull-to-refresh, plus auto-refresh on tab reselect

### Badges
- Full badge catalog with real per-user progress from the backend (earned vs.
  locked, current/target counts), tier-colored icons (bronze/silver/gold)
- Pull-to-refresh, plus auto-refresh on tab reselect

### Profile
- Name, username, email, join date, total sightings, distinct species logged,
  and favorite species (shown in whichever language is selected)
- Edit profile: first/last name and a favorite-species picker (searches the
  live catalog)
- Settings: language (System / English / Türkçe) and units (metric /
  imperial). Both are persisted to the backend together, so changing one
  never silently clears the other. Changing language updates the app's
  outgoing `Accept-Language` header immediately and refreshes the cached
  profile, so backend-resolved text (species names, favorite species, badge
  names) catches up right away instead of on the next unrelated request
- Log out

### Cross-cutting
- Full English/Turkish localization for all static UI text; backend-resolved
  text (species/badge/favorite-species names) follows the same language via
  `Accept-Language`
- Pastel-dark theme with flowing script titles — a visual port of the Swift
  app's `Theme.swift`
- Handles Render's cold starts gracefully (90s request timeout, matching the
  Swift client's own tuning)

## Running it

```bash
flutter pub get   # only needed if pubspec.yaml changed since last run
flutter run       # pick a device — Chrome and Windows desktop both work
                   # out of the box here; Android needs Android Studio's SDK,
                   # iOS/macOS need Xcode (e.g. on your Mac)
```

`flutter analyze` and `flutter test` both pass clean.

## Testing

```bash
flutter test
```

142 unit tests: JSON parsing and business logic for every model, `ApiClient`
(header injection, error mapping, the 401 refresh-and-retry flow, multipart
upload), `TokenStore` (persistence, refresh rotation), every service's
request/response shape, and `AuthSession`'s full state machine
(bootstrap/login/register/resend/logout/refreshProfile). See `test/`.

## Platform permissions (already applied)

The app captures GPS location for sightings (`geolocator`) and picks photos
from the gallery (`image_picker`):

- **Android** (`android/app/src/main/AndroidManifest.xml`):
  `ACCESS_FINE_LOCATION` + `ACCESS_COARSE_LOCATION`. `INTERNET` is already
  included by the default Flutter template.
- **iOS** (`ios/Runner/Info.plist`): `NSLocationWhenInUseUsageDescription` +
  `NSPhotoLibraryUsageDescription`.

macOS/Linux/Windows desktop targets don't need these for the fields this app
currently uses, but macOS will additionally need a location entitlement in
`macos/Runner/*.entitlements` if you build for it later.

## Architecture notes

- **Auth**: JWT access/refresh pair persisted in `flutter_secure_storage`
  (`lib/core/token_store.dart`). `ApiClient` (`lib/core/api_client.dart`)
  transparently refreshes and retries once on a 401. Because
  `AuthResponseDto` has no embedded profile, the user id is read from the
  access token's `sub` claim (`jwt_decoder`), then `GET /api/users/{sub}`
  fetches the full profile — same pattern the Swift `BackendAuthService`
  uses.
- **Localization**: hand-written (`lib/core/app_localizations.dart`), no
  `flutter gen-l10n` step. Mirrors the Swift app's `AppLanguage`
  (System/English/Türkçe), persisted via `shared_preferences`, and also
  drives the backend `Accept-Language` header via `ApiClient.languageCode`
  (kept in sync in `app.dart` and updated immediately on a Settings change).
- **Pagination**: `GET /api/species` returns a versioned envelope —
  `{content: [...], page: {totalElements, totalPages, number, size}}` — see
  `SpeciesPage` in `lib/models/species.dart`.
- Species/badge/favorite-species display text comes back from the backend
  already locale-resolved (or, for species/badge catalog entries, as locale
  maps like `{"en": "...", "tr": "..."}` — see `localizedText()` in
  `lib/models/species.dart`).
- **Tab refresh**: `RootTabView` keeps every tab's `State` alive via
  `IndexedStack`, so each data-driven tab (Map/Guide/Diary/Badges) exposes a
  public `refresh()` the tab bar calls on reselect, plus pull-to-refresh.
