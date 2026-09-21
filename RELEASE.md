<!-- RELEASE.md -->

[한국어](./RELEASE.ko.md)

# Release Notes

This file documents the main changes for each release.

---

### Version 2.0.2+10 (2026-09-21)

Fixes the map hand-off for parsed schedules.

- **Fixed**
  - Tapping the location opened the map app with the full extracted line ("OOO웨딩홀 3층 OO홀"), which map searches routinely fail to find. The parser now extracts a searchable venue name as its own field and the map queries that instead; hand-editing the location falls back to the edited text.
  - Already-saved upcoming schedules get their venue backfilled once after the update, in a single batched AI call, so the fix applies to existing schedules too.
- **Changed**
  - The parsing benchmark scores the new venue field: 38/38 exact on the current run, with core accuracy holding at 100%.

---

### Version 2.0.1+9 (2026-09-10)

Hotfix for App Store users who saw an immediate "try again" error on every
AI request after the 2.0.0 launch.

- **Fixed**
  - Release iOS builds activated the DeviceCheck App Check provider while the Firebase console registers the app with App Attest, so attestation was rejected and every AI call failed instantly. Release builds now use the App Attest provider, with the required entitlement added.
- **Deployment**
  - Released on both Google Play and the App Store (version-code sync on Android; no functional Android change).

---

### Version 2.0.0+8 (2026-09-08)

A major update: the app grows from a link parser into an AI wedding assistant.
Invitations can now be registered from images, plain text, or the OS share
sheet — no link required.

- **Added**
  - Image invitation parsing: analyze a 카톡 capture or photo of an invitation with Gemini multimodal input (gallery pick + camera).
  - Text invitation parsing: paste an invitation SMS/message and parse it without a link.
  - OS share sheet integration: share a link, image, or text from other apps straight into 청모 (Android Share Intent / iOS Share Extension).
  - AI gift money recommendation: suggests an amount from the relationship, your past records, and public survey data, with a dedicated attendance/gift record page.
  - Gift money statistics dashboard: yearly and per-relation charts of amounts given and received.
  - Home screen widget (Android/iOS): D-day for the next wedding with the invitation photo as background, rolling over at midnight.
  - Manual schedule entry, and a fallback form pre-filled with partially parsed fields when the invitation has no date.
  - Device calendar hand-off: register a saved schedule into the OS calendar.
  - Redesigned onboarding: intro carousel plus a versioned coach-mark tour, replayable from settings.
- **Changed**
  - Structured output (`responseJsonSchema`) is enforced for all parsers sharing one schema.
  - App-wide micro-interaction polish: motion tokens, pressed feedback, count-up statistics, haptics, and smoother transitions.
  - Image preprocessing and hashing moved to isolates; uploads shrink from ~487KB to ~65KB and the UI stays at 60fps.
  - The iOS paste permission popup appears only when actually pasting.
- **Fixed**
  - Calendar month swipes no longer stutter (removed a full calendar remount on every state change).
  - Returning to the home screen no longer re-summons the keyboard; tapping the background dismisses it.
- **Deployment**
  - Released on both Google Play and the App Store (2026-09-08).

---

### Version 1.3.1+7 (2026-08-26)

- **Added**
  - Firebase Analytics and Crashlytics for stability and usage metrics.
- **Changed**
  - Upgraded to Flutter 3.47.1; the minimum supported iOS version is now 15.

---

### Version 1.3.0+6 (2026-08-21)

- **Added**
  - Gift money accounts (groom/bride sides) are now parsed from invitations, with tap-to-copy.
  - Record attendance and gift amount per wedding, with a yearly total.
  - Upcoming schedules preview on the home screen.
- **Changed**
  - Redesigned the detail page with a D-day badge, and tap a location to open it in Maps.

---

### Version 1.2.0+5 (2025-12-08)

- **Changed**
  - Migrated AI backend from `GPT API` to `Gemini(Firebase AI Logic)`.
- **Fixed**
  - Removed unnecessary `_initialized` flag which disturbed `watchAllSchedules()`.

---

### Version 1.1.0+4 (2025-07-27)

- **Added**
  - Clipboard Detection: The app can now detect a wedding invitation link in the clipboard for faster registration.
- **Changed**
  - Improved backend request stability by adding a timeout and retry logic for long-running requests.
- **Fixed**
  - Applied `SafeArea` to prevent UI elements from being obscured by system intrusions (like notches or status bars).

---

### Version 1.0.2+3 (2025-05-18)

- **Fixed**
  - **Hotfix:** Resolved an issue where newly registered schedules were not displayed correctly on the calendar page. This was fixed by properly implementing a `Stream` to update the UI in real-time from the local database (`lib/domain/usecases/watch_all_schedules_usecase.dart`).

---

### Version 1.0.1+2 (2025-05-12)

- **Added**
  - Onboarding Tutorial: Added an onboarding tutorial for new users using the `tutorial_coach_mark` package.
  - Push notification permission requests are now more explicit to improve user understanding.
- **Changed**
  - The internal data model for dates was unified to use `DateTime` objects within the domain entities. Mapping to and from `String` now occurs at the data layer boundary (`lib/data/mapper/schedule_mapper.dart`).
- **Deployment**
  - The app is now available on the Google Play Store.
  - iOS version has been tested and prepared for App Store submission.

---

### Version 1.0.0+1 (2025-03-27)

- Initial release of the application.
