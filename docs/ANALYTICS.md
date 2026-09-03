<!-- docs/ANALYTICS.md -->

# Analytics & Observability

Measurement plan for chungmo (청모). It defines what we track, why, the targets
we hold ourselves to, and how instrumentation is structured in the codebase.

The core value the app delivers is **turning a wedding invitation link into a
saved schedule**, so the metric design is organised around that outcome rather
than raw installs.

---

## 1. Goals

| Goal | Question it answers | Primary signals |
| --- | --- | --- |
| Stability | Is the app healthy in production? | crash-free rate, ANR, non-fatal errors |
| Growth | Are we acquiring and keeping users? | installs, MAU, retention |
| Activation | Do new users reach the core value? | parse → save funnel |
| AI quality | Is the parsing pipeline accurate and fast? | parse success rate, latency, failure reasons |
| Performance | Is the app fast and responsive? | cold start, frame render, network latency |

---

## 2. Tooling

| Tool | Responsibility |
| --- | --- |
| Firebase Crashlytics | Fatal crashes, ANR, non-fatal errors |
| Firebase Analytics (GA4) | Events, funnels, retention, MAU/DAU |
| Firebase Performance Monitoring | Cold start, screen render, network traces |
| Play Console / App Store Connect | Installs and store-level metrics |
| Looker Studio (optional) | Consolidated dashboard |

All tools sit on the existing Firebase project, so no new backend is introduced.

---

## 3. North Star & targets

**North Star Metric — weekly successful schedule saves** (schedules parsed from
an invitation and saved). Every other metric exists to move this number.

Service-level targets:

| Metric | Target |
| --- | --- |
| Crash-free users | ≥ 99% |
| Crash-free sessions | ≥ 99.5% |
| ANR rate (Android) | < 0.47% |
| Parse success rate | ≥ 95% |
| Parse latency (p95) | ≤ 8 s |
| App cold start (p95) | ≤ 3 s |

---

## 4. Metric catalog

### 4.1 Stability

| Metric | Definition |
| --- | --- |
| Crash-free users | Share of users with no fatal crash |
| Crash-free sessions | Share of sessions with no fatal crash |
| ANR rate | Share of sessions with an Application Not Responding event |
| Non-fatal errors | Count of caught, reported errors per user |

### 4.2 Growth

| Metric | Definition | Source |
| --- | --- | --- |
| Installs | New device installs | Play Console / App Store Connect |
| New users | First-open users | Analytics |
| MAU / DAU | Active users per month / day | Analytics |
| Retention | Return rate at D1 / D7 / D30 | Analytics |

### 4.3 Activation funnel

| Step | Event |
| --- | --- |
| 1. Submit a link | `invitation_link_submitted` |
| 2. Parse starts | `parse_started` |
| 3. Parse succeeds | `parse_succeeded` |
| 4. Schedule saved | `schedule_saved` |

| Metric | Definition |
| --- | --- |
| Activation rate | New users who save ≥ 1 schedule in the first session |
| Time to first value | Time from install to first saved schedule |
| Step conversion | Conversion between each funnel step |

### 4.4 AI pipeline quality

| Metric | Definition |
| --- | --- |
| Parse success rate | `parse_succeeded` / `parse_started` |
| Parse latency | Time from request to result (p50 / p95) |
| Failure breakdown | Distribution of `parse_failed` reasons |
| Correction rate | Saved schedules the user edits afterwards (accuracy proxy) |

### 4.5 Engagement

| Metric | Definition |
| --- | --- |
| Feature adoption | Users who use map / attendance / gift / calendar |
| Actions per schedule | Feature actions per saved schedule |
| Notification return rate | App opens originating from a notification |

### 4.6 Performance

| Metric | Definition |
| --- | --- |
| Cold start | Time to first frame from a cold launch |
| Frame render | Janky (slow / frozen) frame rate |
| Network latency | Duration and success rate of remote calls |

---

## 5. Event taxonomy

Event and parameter names use `lower_snake_case` and stay within Firebase limits
(≤ 40-char event names, ≤ 25 parameters per event). Names are defined once in
[`lib/core/analytics/analytics_events.dart`](../lib/core/analytics/analytics_events.dart).

| Event | Trigger | Parameters |
| --- | --- | --- |
| `invitation_link_submitted` | User submits an invitation link | `source` |
| `invitation_image_submitted` | User attaches an invitation image | `source` |
| `invitation_text_submitted` | User pastes invitation text | `source` |
| `manual_schedule_submitted` | User saves a hand-entered schedule | `source` |
| `parse_started` | Parsing begins | `input_type` |
| `parse_succeeded` | Parsing returns a schedule | `input_type`, `duration_ms`, `has_accounts`, `account_count` |
| `parse_failed` | Parsing throws | `input_type`, `reason`, `duration_ms` |
| `schedule_saved` | Schedule stored locally | `days_until`, `has_accounts` |
| `schedule_opened` | Detail page opened | `source` |
| `location_map_opened` | Venue tapped to open Maps | — |
| `attendance_recorded` | Attendance set | `status` |
| `gift_recorded` | Gift amount set | `amount_bucket` |
| `account_copied` | Account number copied | `side` |
| `schedule_deleted` | Schedule deleted | — |
| `calendar_viewed` | Calendar opened | `view` |
| `calendar_export_tapped` | Schedule handed off to the device calendar | — |
| `notification_opened` | App opened from a notification | — |
| `pay_reco_requested` | AI gift-amount recommendation requested | `relation` |
| `pay_reco_applied` | Recommended amount applied to the pay field | `relation`, `reco_source` |

`first_open`, `session_start`, `app_open`, and `screen_view` are collected
automatically by Firebase Analytics.

### Parameter values

| Parameter | Values |
| --- | --- |
| `source` | `paste`, `manual`, `clipboard`, `home`, `calendar`, `notification`, `gallery`, `camera`, `blank`, `fallback`, `share` |
| `input_type` | `link`, `image`, `text` |
| `reason` | `crawl`, `format`, `incomplete`, `schema`, `timeout`, `unknown` |
| `status` | `attending`, `absent` |
| `side` | `groom`, `bride` |
| `view` | `calendar`, `list` |
| `amount_bucket` | `50k`, `100k`, `200k`, `300k`, `custom` |
| `relation` | `family`, `friend`, `coworker`, `acquaintance`, `unset` |
| `reco_source` | `model`, `fallback` |

---

## 6. User properties

| Property | Description |
| --- | --- |
| `saved_schedule_count` | Bucketed number of saved schedules (`0`, `1-2`, `3-5`, `6+`) |
| `remote_source` | Active parsing backend (`firebase`) |

---

## 7. Crash reporting

| Channel | Source |
| --- | --- |
| Flutter fatal errors | `FlutterError.onError` → Crashlytics |
| Uncaught async errors | `PlatformDispatcher.instance.onError` → Crashlytics |
| Parse failures (non-fatal) | `parse_failed` also recorded with a `reason` key |

Custom keys attached to reports: `remote_source`, `parse_reason`.

---

## 8. Architecture

Instrumentation is decoupled from Firebase behind a single facade, so call sites
never depend on the analytics backend directly.

| Layer | Element | Role |
| --- | --- | --- |
| `core/analytics` | `AnalyticsService` | Abstract facade for events + crash reporting |
| `core/analytics` | `AnalyticsEvents`, `AnalyticsParams` | Event / parameter name constants |
| `core/analytics` | `NoopAnalyticsService` | Default no-op used before wiring and in tests |
| `core/analytics` | `FirebaseAnalyticsService` | Firebase-backed implementation |
| `presentation` | `FirebaseAnalyticsObserver` | Automatic `screen_view` on navigation |

Call sites:

| Where | Events |
| --- | --- |
| `CreateCubit.analyzeLink` | funnel: submitted → started → succeeded / failed → saved |
| Detail page / cubit | `schedule_opened`, `location_map_opened`, `attendance_recorded`, `gift_recorded`, `account_copied`, `schedule_deleted`, `pay_reco_requested`, `pay_reco_applied` |
| Calendar page | `calendar_viewed` |
| Notification handler | `notification_opened` |

---

## 9. Implementation checklist

| # | Task | Status |
| --- | --- | --- |
| 1 | Analytics facade, event constants, no-op implementation | Done |
| 2 | Add `firebase_analytics` and `firebase_crashlytics` dependencies | Done |
| 3 | Firebase-backed `AnalyticsService` implementation | Done |
| 4 | Crashlytics init and global error handlers in `main` | Done |
| 5 | `FirebaseAnalyticsObserver` for screen views | Done |
| 6 | Instrument the activation funnel in `CreateCubit` | Done |
| 7 | Instrument engagement events (detail, calendar, notifications) | Done |
| 8 | Native setup (Android Crashlytics Gradle plugin) | Done |
| 9 | iOS dSYM upload build phase for symbolicated crashes | Pending |
| 10 | Enable Analytics and Crashlytics in the Firebase console | Done |
| 11 | Verify events in DebugView and a test crash in Crashlytics | Pending |

---

## 10. Rollout phases

| Phase | Scope |
| --- | --- |
| 1 — Foundation | Crashlytics + Analytics, activation funnel, crash-free and MAU |
| 2 — Depth | AI pipeline metrics, retention, engagement |
| 3 — Refinement | Performance monitoring, dashboard, SLO tracking |

---

## 11. Privacy

- No personally identifiable information is sent to analytics.
- Invitation content and account numbers stay on-device and are never logged as
  event parameters.
- Analytics collection follows the platform consent model.
