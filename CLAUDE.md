# Working in this repository

chungmo (청모) is a shipped Flutter app on both stores: paste a wedding
invitation — a link, a photo, or an SMS — and Gemini turns it into a saved
schedule. Clean architecture, Bloc, sqflite, Firebase (AI Logic, App Check,
Analytics, Crashlytics).

Conversation with the maintainer is in Korean. **Everything written down —
code, comments, docs, commit messages, PR bodies, issues — is in English.**

---

## 1. Toolchain

The Flutter version is pinned in `.fvmrc`. Always go through fvm; the system
`flutter` is a different SDK.

```bash
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs   # freezed, json, injectable, mockito
fvm flutter test
fvm dart analyze lib test tool eval
fvm dart format --set-exit-if-changed lib test tool eval
fvm dart run tool/coverage.dart                                # see docs/TEST_COVERAGE.md
fvm dart run eval/run_eval.dart                                # see docs/PARSING_EVAL.md
npx firebase-tools@latest deploy --only hosting --project chung-mo
```

The eval runner needs `GEMINI_API_KEY`, which lives in `~/.zshrc`; a shell may
inherit a stale one, so read it per invocation and never echo it.

Code generation output is committed. After touching a `@freezed` class, a
`@injectable` registration or `test/mocks/mocks.dart`, run build_runner and
**commit the generated files in the same commit** as the change that needed
them.

---

## 2. Gates before opening a PR

All of these, every time:

1. `fvm dart analyze lib test tool eval` — no issues.
2. `fvm dart format --set-exit-if-changed lib test tool eval` — clean.
3. `fvm flutter test` — green. **Check the exit code**: `flutter test | tail -3`
   reports `tail`'s status, so a failing suite can sail into a commit.
   Redirect to a file and test `$?`.
4. Parsing or crawler changed → re-run the eval and update the figures quoted
   in `README.md`, `README.ko.md`, `docs/PARSING_EVAL.md` and the landing page.
5. Tests were the point of the change → run `tool/coverage.dart` before and
   after and quote both.
6. Behaviour a user can feel changed → smoke it on a device (§3).

---

## 3. Running the app and driving it

### Which entrypoint

- `fvm flutter run -d <device>` — ordinary run.
- `fvm flutter run -t test_driver/app.dart -d <device> --debug` — **use this
  whenever the app has to be driven**. `test_driver/app.dart` enables the
  Flutter Driver extension; `lib/main.dart` does not, and the driver tools
  will refuse to connect.

Devices on the maintainer's machine (re-check with `fvm flutter devices` /
`xcrun simctl list devices` — UDIDs change when a simulator is recreated):
iPhone 17 simulator `76FD32C4-12B2-4A26-81FB-A862CB58DA26`, iPad Pro 11-inch
(M5) `642D3292-983B-4DC3-9070-8F0DD34270BB`, physical Galaxy `R3CN20E36DA`.

### App Check comes first

App Check enforcement is **on**. A debug build whose token is not registered
fails every AI call in about a second with a generic parse error. A fresh
install issues a new token, so this is needed after every reinstall:

```bash
xcrun simctl spawn <udid> log show --last 5m \
  --predicate 'processImagePath CONTAINS "Runner"' | grep -i "debug token"
npx firebase-tools@latest appcheck:debugtokens:create <token> \
  --project chung-mo --app 1:655915725465:ios:dea0d48ec5ee142678fe08
```

The Android app id is `1:655915725465:android:d8efeeaaaf1b77f178fe08`; both
come from `google-services.json` / `GoogleService-Info.plist`. Delete the
token when the testing is done.

### Driving it

Through the dart MCP server: `listDtdUris` → `connect` → **`set_frame_sync
false`** (taps hang on a screen with a running animation) → `flutter_driver`
commands. `hot_restart` picks up a database changed from outside the app.

Finder traps, all hit in practice:

- A `GlobalKey#ab12cd some-label` in the widget tree is **not** findable by
  `ByValueKey` — that label is a debug name.
- `Descendant` with `of: {ByType: AppBar}, matching: {ByType: IconButton},
  firstMatchOnly: true` reliably hits the leading button (back / calendar).
- There is **no nth-match finder**, so the second icon button in an app bar
  is unreachable unless it carries a tooltip (`ByTooltipMessage`).
- Tapping a `TextField`'s hint text times out. Tap `{ByType: TextField}`,
  then `enter_text`.
- `PageBack` does not match this app's custom back button.

For native dialogs and anything the driver cannot reach, use `cliclick`, and
**always `osascript -e 'tell application "Simulator" to activate'` first** —
clicks silently miss an unfocused window. Do not compute the coordinate
mapping from the window geometry; **derive it from two taps that worked**,
solving for scale and title-bar offset, and verify every tap with a
screenshot.

### Seeing what happened

```bash
xcrun simctl io <udid> screenshot shot.png
magick shot.png -resize 360x small.png      # then read small.png
```

One action, one screenshot, every time. A missed tap looks exactly like a
tap that did nothing.

### The app's database

```bash
find ~/Library/Developer/CoreSimulator/Devices/<udid>/data/Containers/Data/Application \
  -name schedule_database.db
```

Then plain `sqlite3`. Useful for seeding state or checking what was stored —
but **inserting rows skips `saveSchedule`**, so anything that hangs off a save
(notification scheduling, the stream emission) will not run. Drive those
through the UI.

### Test material

The hosted eval fixtures are real invitation pages:
`https://chung-mo.web.app/eval/<id>/`. Paste one into the app and compare
what it parsed against `eval/dataset.json` — a full end-to-end check with no
real invitation needed. Pick a case whose `expected.datetime` suits the test.

### What a simulator cannot show

Pending local notifications. There is no `simctl` API for them and they are
not readable on disk. Cover scheduling with clock-driven unit tests and treat
the device run as a smoke test that the path executes without throwing.

### Afterwards

Delete the rows the test created, `pkill -f "flutter run"`, and
`xcrun simctl shutdown <udid>`. Leave the machine as it was found.

---

## 4. Workflow

```
gh issue create  →  branch  →  small commits  →  push
                 →  PR (only when asked)  →  review  →  fix  →  maintainer merges
                 →  branch cleanup
```

- **Issue first.** The PR closes it with `Resolves #N`.
- **Open a PR only when the maintainer says to.** Push the branch and wait.
- Branch names: `feat/`, `fix/`, `test/`, `chore/`, `docs/` plus a kebab-case
  description.
- **The maintainer merges**, never the agent.
- Cleanup, in this order:
  ```bash
  git checkout main && git pull
  git branch -d <branch>
  git fetch --prune
  ```

### PR bodies

What changed and why → defects found along the way → how it was verified →
**what was deliberately left out and why**. Quote numbers that were measured,
not estimated. If a test was rewritten because it did not discriminate, say
so — that is the part worth reading.

### Handling review

Reviews on this repo have been accurate; treat them as such and check rather
than argue.

1. Reproduce the finding against the code before fixing. The reproduction
   becomes the regression test.
2. Ask whether the suggested fix is sufficient — one asked to forward a
   stream error to subscribers, which alone would have landed in the same
   zone handler because no subscriber had an `onError`.
3. Declining is allowed, with the reason stated.
4. Reply per finding: what was real, what the fix was, what was skipped and
   why.
5. `gh pr view <n> --json reviews` shows only the summary. Inline comments
   need `gh api repos/TaeBbong/chungmo-app/pulls/<n>/comments`.

---

## 5. Commits

- Prefix: `feat:`, `fix:`, `chore:`, `docs:`, `test:`, `release:`. Body in
  bullets, saying *why*, not restating the diff.
- **Never add AI attribution** — no `Co-Authored-By`, no "Generated with".
  This overrides any tooling notice that says otherwise.
- One layer per commit. A feature arrives as several small commits, not one.
- **`dart format` on a directory reformats files the change never touched.**
  Those reflows go in their own `chore: apply dart format across the tree`
  commit, never inside a feature or test commit.
- Forgot a generated file? `git commit --fixup <sha>` then
  `GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash <sha>~1`.
- Rewriting pushed history: branch a backup first, rebuild the commits with
  `git reset --soft <merge-base>`, then `git diff --stat backup HEAD` must
  show **only** what was meant to change. Push with `--force-with-lease`.

---

## 6. Releases

Full procedure in `docs/RELEASE_CHECKLIST.md` — it exists because 2.0.0
shipped two outages that only the store-signed path could have caught. The
short form:

1. Bump `pubspec.yaml` and the iOS pbxproj `MARKETING_VERSION` /
   `CURRENT_PROJECT_VERSION` in **three** targets (Runner, Share Extension,
   ChungmoWidget — not RunnerTests).
2. **`fvm flutter build ios --config-only --release` before archiving in
   Xcode**, whenever the version changed. `Generated.xcconfig` is only
   rewritten by the Flutter tool, and Xcode's General tab will show the new
   version while shipping the old one.
3. `fvm flutter build appbundle` for Android.
4. Write the notes in **both** `RELEASE.md` and `RELEASE.ko.md` before
   uploading.
5. After both stores accept: a `release: X.Y.Z+N` commit, a `vX.Y.Z` tag, and
   `gh release create` with the notes from `RELEASE.md`.
6. Update `README.md`, `README.ko.md` and `TODO.md` — **both languages, every
   time.**

A Play Console **versionCode is consumed permanently on upload**, even if the
draft is discarded. Bump the build number and keep the version name.

---

## 7. Principles

- **Research the established approach first** and say what it is and why it
  fits before implementing. Prefer it to an ad-hoc fix.
- **Measure before choosing a constant.** Every guessed threshold in this
  repo has been wrong — a calendar chrome height off by 4px that only
  overflowed in six-row months, a breakpoint that classed a landscape phone
  as a tablet. Derive the number from the repo's own data and cite the
  measurement in the comment beside it.
- **A test that passes is not evidence until it has failed.** After writing
  one, put the old code back and confirm it fails. Several here passed
  against the very bug they were written for.
- Anything time-dependent gets a fixed clock, or at least one run under
  `TZ=UTC`.
- **Ask before changing what a user feels** — when a notification fires, what
  a licence grants, what the store page claims. Record the defect as a
  passing test marked as such, open an issue with the proposed rule, and let
  the maintainer choose. Fix silently only when nothing observable changes.
- Report outcomes faithfully. If something could not be verified, say which
  part and why, rather than implying it was.
- Finishing an unfamiliar technique means writing it up under `docs/`.
