<!-- README.md -->

[한국어](./README.ko.md)

# chungmo: An AI Wedding-Invitation Assistant

![Brand Preview](./designs/previews_submission/cover.png)

<p align="center">
  <strong>Paste an invitation — a link, a KakaoTalk capture, or plain text — and AI turns it into a schedule, down to the gift-money accounts.</strong>
</p>

<p align="center">
  <a href="https://play.google.com/store/apps/details?id=com.taebbong.chungmo">
    <img src="https://img.shields.io/badge/google play-414141?style=for-the-badge&logo=googleplay&logoColor=white" alt="Google Play">
  </a>
  <a href="https://apps.apple.com/kr/app/id6745786004">
    <img src="https://img.shields.io/badge/appstore-0D96F6?style=for-the-badge&logo=appstore&logoColor=white" alt="App Store">
  </a>
  <a href="https://chung-mo.web.app">
    <img src="https://img.shields.io/badge/website-800020?style=for-the-badge&logo=firebase&logoColor=white" alt="Website">
  </a>
</p>

## Features

- **AI invitation parsing — link, photo, or text**
  - Paste a mobile invitation URL, share a KakaoTalk capture or paper-invitation photo, or paste the announcement SMS. Gemini (Firebase AI Logic) extracts the couple, date, venue and both families' gift-money accounts through a structured-output schema shared by all three paths (`lib/data/sources/remote/invitation_prompt.dart`).
  - Links are crawled by a purpose-built extractor (`lib/core/utils/crawler.dart`): document-order text walk, OpenGraph metadata, EUC-KR decoding, same-host iframe follow and a CSR-shell JSON fallback.
  - When an invitation states no date, the partial extraction pre-fills a manual form instead of failing.
- **OS share-sheet integration**
  - "Share → 청모" from any app starts the analysis immediately (Android Share Intent / iOS Share Extension).
- **AI gift-money recommendation**
  - Describe the relationship and closeness; the model grounds its suggestion in your own records and public survey statistics, and explains the amount.
- **Records and statistics**
  - Track attendance and the amount given per wedding; see yearly and per-relationship charts (`lib/presentation/pages/stats_page.dart`).
- **Around the schedule**
  - Home-screen widget with the next wedding's D-day (Android/iOS), day-before push reminder, one-tap hand-off to the device calendar, tap-to-copy account numbers, and clipboard link detection.

### Measured accuracy

The parser is scored against a self-built benchmark: 38 fixture invitations reproducing 15 real vendor markup styles, hosted at [chung-mo.web.app/eval](https://chung-mo.web.app), with an automatic scorer.

| | value |
|---|---|
| Core accuracy (schedule saves with no manual fix) | **100%** (38/38) |
| Per field — names · datetime · venue · accounts | 100% each |
| Journey | 63% → 85% (crawler rewrite) → 100% (year inference, CSR JSON follow) |

How it is built and scored: [docs/PARSING_EVAL.md](./docs/PARSING_EVAL.md), [docs/CRAWLER_COVERAGE.md](./docs/CRAWLER_COVERAGE.md).

### App Screenshots

| ![](./designs/screenshots_new_ios/home_light.png) | ![](./designs/screenshots_new_ios/result_light.png) | ![](./designs/screenshots_new_ios/detail_light.png) | ![](./designs/screenshots_new_ios/calendar_light.png) |
| --- | --- | --- | --- |
| ![](./designs/screenshots_new_ios/list_light.png) | ![](./designs/screenshots_new_ios/onboarding1_light.png) | ![](./designs/screenshots_new_ios/coachmark_light.png) | ![](./designs/screenshots_new_ios/home_dark.png) |

## Get Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) — the project pins its version with [fvm](https://fvm.app) (`.fvmrc`)
- A Firebase project of your own: the app relies on Firebase AI Logic, App Check, Analytics and Crashlytics, so run `flutterfire configure` to generate your `firebase_options.dart` and platform config files
- For AI calls in debug builds, register the App Check debug token printed on first run (Firebase console → App Check → Manage debug tokens)

### Installation

1.  Clone the repository:

    ```bash
    git clone https://github.com/TaeBbong/chungmo-app.git
    cd chungmo-app
    ```

2.  Install dependencies:

    ```bash
    fvm flutter pub get
    ```

3.  Run the code generator:

    ```bash
    fvm dart run build_runner build --delete-conflicting-outputs
    ```

4.  Run the app:
    ```bash
    fvm flutter run
    ```

## Configuration

### Environment Setup

Environments are still selected through a static class (a Flavor/`dart-define` migration is on the roadmap). `main.dart` picks the environment from the build mode:

```dart
/// lib/core/env.dart (excerpt)
enum Environ { local, dev, production }

enum RemoteSourceEnv { firebase, cloud }

class Env {
  static void init(
      {required Environ environment, required RemoteSourceEnv remoteSource}) {
    // resolves the legacy cloud endpoint and the DI backendType
  }
}
```

`RemoteSourceEnv.firebase` is the shipping path (Firebase AI Logic); `cloud` keeps the legacy GPT-backend implementation selectable through DI.

## Project Architecture

This project is based on **Clean Architecture** to separate concerns and create a scalable, maintainable codebase. The presentation layer is built using the **Bloc** pattern for state management.

```css
📂 core/
   ├── utils/       (Crawler, image preprocessing, extensions)
   ├── di/          (Dependency injection setup)
   ├── navigation/  (Routing logic)
   └── services/    (Notifications, home widget, analytics)

📂 data/
   ├── sources/     (Local and remote data sources, AI prompts)
   ├── repositories/ (Implementation of domain repositories)
   ├── models/      (Data Transfer Objects)
   └── mapper/      (Mappers between models and entities)

📂 domain/
   ├── entities/    (Pure domain models)
   ├── repositories/ (Abstract repository interfaces)
   ├── usecases/    (Business logic for specific tasks)

📂 presentation/  (UI Layer)
   ├── bloc/        (Blocs and Cubits for state management)
   ├── pages/       (UI screens/pages)
   ├── widgets/     (Reusable UI components)
   └── theme/       (App theme, palette, motion tokens)

📂 main.dart      (Application entry point)
```

Beyond `lib/`, the repository carries the parsing benchmark (`eval/` — dataset, runner, scorer), the static site and eval fixtures served from Firebase Hosting (`hosting/public/`, [chung-mo.web.app](https://chung-mo.web.app)), and engineering write-ups under `docs/` (isolates, micro-interactions, crawler coverage, parsing eval, hosting, analytics, release checklist).

The data flow follows a clear, unidirectional pattern from the UI to the data layer, orchestrated by dependency injection (`get_it` and `injectable`).

```txt
┌────────────────────────── UI (Bloc) ──────────────────────────┐
│  View (Widget)                                                │
│     ├──> Bloc / Cubit (State Management)                      │
│     │     ├──> UseCase (Business Logic)                       │
│     │     │     ├──> Repository (Interface)                   │
│     │     │     │     ├──> Remote Data Source (Firebase AI)   │
│     │     │     │     └──> Local Data Source (SQLite)         │
│     │     │     │                                             │
└───────> Dependency Injection (get_it + injectable) ───────────┘
```

## Release History

For detailed information on version changes, see the [Release Notes](./RELEASE.md) or the [GitHub Releases](https://github.com/TaeBbong/chungmo-app/releases).

## Dependencies

This project uses several key packages, including:

- `firebase_ai` (+ `firebase_app_check`) for Gemini calls through Firebase AI Logic.
- `flutter_bloc` for state management.
- `get_it` and `injectable` for dependency injection.
- `sqflite` for local database storage.
- `table_calendar` for the calendar UI.
- `home_widget`, `fl_chart`, `receive_sharing_intent`, `add_2_calendar` for the widget, charts, share sheet and calendar hand-off.

A full list of dependencies is available in the [`pubspec.yaml`](./pubspec.yaml) file.

## License

Copyright © 2026 TaeBbong. The source is public for reading and reference.
