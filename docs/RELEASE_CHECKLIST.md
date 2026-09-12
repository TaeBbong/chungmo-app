# Release Checklist

Why this exists: the 2.0.0 release shipped two outages that debug builds could
not catch — iOS activated the DeviceCheck App Check provider while the console
registered App Attest, and Firebase only had the upload-key SHA-256 while Play
installs are re-signed with the Play App Signing key. Both failures live in the
**store-signed path**, which neither debug builds nor locally-built release
builds ever exercise. Every ring below exists to close that gap.

## Ring 1 — Before archiving (local)

- [ ] Bump `pubspec.yaml` and iOS pbxproj `MARKETING_VERSION` /
      `CURRENT_PROJECT_VERSION` (Runner, Share Extension, ChungmoWidget —
      leave RunnerTests).
- [ ] Run `fvm flutter build ios --config-only --release` so
      `Generated.xcconfig` picks up the new version — Xcode's General tab
      shows the pbxproj value and will lie to you otherwise.
- [ ] Local release smoke on a device (`flutter run --release`): app boots,
      golden path works. This validates shrinker/release-only code paths but
      **NOT attestation** — local builds are signed with the upload/dev key.

## Ring 2 — Store-signed smoke (the only place attestation is real)

- [ ] **Android**: upload the AAB to the Play **internal testing** track and
      install it from Play on a real device. This install is re-signed with
      the Play App Signing key, so Play Integrity runs for real.
      Golden path: paste an invitation link → AI parse succeeds → save →
      widget shows the schedule.
- [ ] **iOS**: install the build via **TestFlight** on a physical iPhone
      (borrowed device or a real-device cloud that supports TestFlight) and
      run the same golden path. TestFlight builds are App Store-signed, so
      App Attest runs for real. Simulators cannot attest.
- [ ] If either smoke fails with a fast (~1-2s) "try again" error, suspect
      App Check first: provider type must match the console registration
      (Android = Play Integrity, iOS = App Attest) and Firebase must have the
      **Play App Signing key** SHA-256, not just the upload key.

## Ring 3 — Server config changes: monitor, then enforce

- [ ] Any App Check change (provider, SHA/key registration, enforcement, new
      enforced API) ships in monitor mode first: the console App Check
      metrics classify requests as verified/unverified even with enforcement
      off.
- [ ] Enforce only after both platforms show healthy verified traffic on the
      current store builds.

## Ring 4 — Rollout and post-release watch

- [ ] Use staged rollouts: App Store phased release, Play staged rollout
      (e.g. 20% → 100%).
- [ ] T+24h: check Crashlytics top issues (Firebase MCP works from the
      terminal) and the App Check verified ratio. Crashes from a single
      device poking unreachable activities with null intents right after
      release are store robo-test noise — close them.
- [ ] After store deployment: `release: X.Y.Z+N` commit → `vX.Y.Z` tag →
      GitHub Release with the RELEASE.md section as its body.
