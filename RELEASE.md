<!-- RELEASE.md -->
[한국어](./RELEASE.ko.md)

# Release Notes

This file documents the main changes for each release.

---

### Version 1.1.0+4 (2025-07-27)

-   **Added**
    -   Clipboard Detection: The app can now detect a wedding invitation link in the clipboard for faster registration.
-   **Changed**
    -   Improved backend request stability by adding a timeout and retry logic for long-running requests.
-   **Fixed**
    -   Applied `SafeArea` to prevent UI elements from being obscured by system intrusions (like notches or status bars).

---

### Version 1.0.2+3 (2025-05-18)

-   **Fixed**
    -   **Hotfix:** Resolved an issue where newly registered schedules were not displayed correctly on the calendar page. This was fixed by properly implementing a `Stream` to update the UI in real-time from the local database (`lib/domain/usecases/watch_all_schedules_usecase.dart`).

---

### Version 1.0.1+2 (2025-05-12)

-   **Added**
    -   Onboarding Tutorial: Added an onboarding tutorial for new users using the `tutorial_coach_mark` package.
    -   Push notification permission requests are now more explicit to improve user understanding.
-   **Changed**
    -   The internal data model for dates was unified to use `DateTime` objects within the domain entities. Mapping to and from `String` now occurs at the data layer boundary (`lib/data/mapper/schedule_mapper.dart`).
-   **Deployment**
    -   The app is now available on the Google Play Store.
    -   iOS version has been tested and prepared for App Store submission.

---

### Version 1.0.0+1 (2025-03-27)

-   Initial release of the application.
