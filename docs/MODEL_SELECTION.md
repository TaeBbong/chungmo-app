<!-- docs/MODEL_SELECTION.md -->

# Choosing the Gemini model without a release

Every Firebase AI Logic call in chungmo — invitation parsing (link, image,
text), the venue backfill and the pay recommendation — runs on one Gemini
model. This document explains why that model is configuration rather than
code, how the app picks it at runtime, the policy for choosing it, and how
to change it.

---

## 1. Why the model id is not a constant

Until 2.1.0 the id was `Constants.geminiModel`, compiled into each release.
Three things measured in 2026-10 made that untenable:

- **Models retire on Google's schedule, not ours.** `gemini-2.5-flash`, the
  model 2.0.x shipped with, is deprecated on the Gemini Developer API and
  kept only for projects that already used it (#73). When it goes, every
  parse fails for every user until a new build clears store review.
- **Listed is not served.** `models.list` returned `gemini-2.5-flash-lite`
  as a `generateContent` model on 2026-10-28, and calling it returned
  **404 NOT_FOUND**. No client can trust the listing to pick a model.
- **Price is not in the listing at all.** `models.list` returns token limits
  and sampling defaults, no prices. Prices live in the Cloud Billing Catalog
  under service `AEFD-7695-64FA` ("Gemini API"), which needs an OAuth token
  that an app does not have.

So the app cannot choose for itself, and a person choosing must not need a
release to act.

## 2. The established approach

Firebase documents this case for AI Logic:
[Change the model name remotely](https://firebase.google.com/docs/ai-logic/change-model-name-remotely).
A Remote Config parameter `model_name` holds the id; the app sets in-app
defaults with `setDefaults`, calls `fetchAndActivate`, and listens to
`onConfigUpdated` so a published change is activated within seconds rather
than at the next fetch.

chungmo follows it with one deliberate difference: **startup does not wait
for the fetch.** The guide's sample reads the value right after fetching.
Here the in-app default is always a model that works, the value is only read
when the user starts a parse, and the splash screen must not depend on the
network. Before the fetch completes, the default is used.

## 3. How it works

```
Remote Config  model_name ──► ModelConfig.models ──► ModelSelector.run(call)
 (or in-app default)          [configured,             try configured
                               gemini-flash-lite-       └─ "models/… is not found"?
                               latest]                       remember it as retired,
                                                             try the safety net
```

| Piece | File | Role |
| --- | --- | --- |
| `ModelConfig` / `RemoteModelConfig` | `lib/core/services/model_config.dart` | Defaults, fetch, real-time activation; returns the ordered list |
| `ModelConfig.chain` | same | Configured id first, safety net last and never twice; a blank value falls back to `Constants.geminiModel` |
| `ModelSelector` | `lib/data/sources/remote/model_selector.dart` | Runs a call on the first model still served |
| `Constants.geminiModel` | `lib/core/utils/constants.dart` | In-app default (and the eval runner's default) |
| `Constants.geminiSafetyNetModel` | same | `gemini-flash-lite-latest` |

`RemoteModelConfig.init()` runs in `main.dart` right after dependency
injection — before the venue backfill, which calls the model on launch.

### 3.1 The safety net

`gemini-flash-lite-latest` is Google's alias for the current Flash-Lite. It
resolved to `gemini-3.5-flash-lite` on 2026-10-28 and 2026-11-04, which is
also the default — so today the two agree.

It is the **fallback, not the default**, because an alias moves without
notice and parsing accuracy moves with it. A pinned id changes only when a
person changes it after checking; the alias is there for the case where
nobody has yet.

### 3.2 Recognising a retired model

The backend answers 404 with status `NOT_FOUND`, but firebase_ai 3.15.0's
`parseError` (`lib/src/error.dart:151`) keeps only the message and turns it
into a `ServerException`. The selector therefore matches the message, and
only its stem — `models/<id> is not found` — because the two backends word
the rest differently:

| Backend | Message |
| --- | --- |
| Gemini API (`generativelanguage`) | `…is not found for API version v1beta, … Call ListModels …` |
| Firebase AI Logic proxy (`firebasevertexai`) — what the app sees | `…is not found for API version v1main, … Call ModelService.ListModels …` |

The second row was captured on a device; the unit tests were written
against the first, and a pattern requiring `v1beta` would have passed all
of them while never firing in the app. Both are now tests.

A retired id is remembered for the life of the process, so later calls do
not pay for the 404 again. If every model has failed, the next call tries
them all once more rather than giving up without a request.

Only "not found" steps forward. An exhausted balance or quota refuses every
model alike, so a second model would spend another call before the same
refusal; those surface as `RemoteUnavailableException` (#72).

## 4. The policy

> `model_name` is the **cheapest stable model that is still served**.

- **Stable** means a release named by version and tier only —
  `gemini-<version>-<flash|flash-lite|pro>`. Previews, experiments, aliases,
  TTS, image and codenamed models are excluded.
- **Served** means it answered a request today, not that it is listed.
- **Cheapest** means no other stable, served model is cheaper or equal on
  both input and output price and strictly cheaper on one. Nothing weights
  the two: the input/output token mix of a parse has not been measured, and
  thinking tokens bill as output, so a model cheaper on one side only is
  printed as a *trade-off* for a person to judge.

Accuracy is a separate gate: re-run the parsing eval
([PARSING_EVAL.md](./PARSING_EVAL.md)) after a change. The move to
`gemini-3.5-flash-lite` shipped before that re-run at the maintainer's call;
it stays open on #73.

### Prices at the time of the switch

KRW per 1M tokens, standard on-demand tier, from the Billing Catalog:

| Model | Input | Output | Served (2026-11-04) |
| --- | ---: | ---: | --- |
| gemini-3.5-flash-lite | 403.0 | 3,358.1 | yes — **configured** |
| gemini-2.5-flash | 403.0 | 3,358.1 | yes (deprecated) |
| gemini-3.8-flash | 1,007.4 | 5,037.2 | yes |
| gemini-2.5-flash-lite | 134.3 | 537.3 | **no** — listed, answers 404 |
| gemini-3.1-flash-lite | — | — | yes, but unpriced (see §5.2) |

`gemini-3.8-flash`, #73's original target, would have cost about 2.4x per
parse.

## 5. Operating it

### 5.1 Checking the model

```bash
export GEMINI_API_KEY=...      # from ~/.zshrc; never echo it
gcloud auth login              # once; for the price list and Remote Config
fvm dart run tool/model_catalog.dart
```

It reads the live `model_name`, joins `models.list` with the Billing
Catalog, probes every stable candidate (about ten one-word requests) and
prints a table. Exit `0` means nothing to do; `1` means change
`model_name` — the configured model is not served, has no price, or a
cheaper one exists; `2` means setup failed. `--model=NAME` judges a
different id. Run it monthly, and whenever a Gemini deprecation notice
arrives.

### 5.2 Reading its notes

- **`NOTE: … has no standard text price`** — served but not nameable in the
  catalog. On 2026-11-04 `gemini-3.1-flash-lite` was served while only
  `gemini-3.1-flash-lite-preview` had a price (339.7 / 2,038.1 on
  2026-10-28, below the configured model). It may be cheaper; confirm on the
  [pricing page](https://ai.google.dev/gemini-api/docs/pricing) before
  switching.
- **`yes -> other-model`** — the id answered as a different version, i.e. it
  is already redirected. `gemini-3.5-flash` answered as `gemini-3.6-flash`
  and `gemini-3.7-flash` as `gemini-3.8-flash`.

### 5.3 Changing the model

1. Run the tool with `--model=<new id>` and confirm it exits `0`.
2. Firebase console → Remote Config → `model_name` → new value → **Publish**.
   Or via REST, as the template was first published (version 1,
   2026-11-04): `GET` then `PUT`
   `https://firebaseremoteconfig.googleapis.com/v1/projects/chung-mo/remoteConfig`
   with the returned `ETag` in `If-Match`.
3. Running apps activate it within seconds through `onConfigUpdated`;
   others at their next launch.
4. If the switch is permanent, move `Constants.geminiModel` in the next
   release so a fresh install without network starts on it too.

Rolling back is the same step with the previous value, or the console's
version history. App versions before 2.1.0 do not read the parameter.

### 5.4 When the alert fires

The Cloud Monitoring alert ([ANALYTICS.md](./ANALYTICS.md) §12) reports
non-2xx responses on the AI Logic path. A burst of **404** means the
configured model was retired; the safety net is already serving users, so
point `model_name` at a pinned successor. **402/429** is billing, and no
model change helps.

## 6. How this was verified

- 308 unit tests, including the fallback end to end through
  `FirebaseAiLogicImpl`. Each new test was checked against a broken
  implementation — always using the first model, forgetting retired ids,
  stepping past every refusal, using a blank value as-is, mis-pricing per
  `displayQuantity` — and failed as intended.
- On the iPhone 17 simulator, with the default temporarily set to a
  non-existent id: the proxy answered 404 with the wording in §3.2, the
  selector stepped to `gemini-flash-lite-latest`, and `nextcard-02` parsed
  correctly. With the real default, `nextcard-03` parsed on
  `gemini-3.5-flash-lite`. Cloud Monitoring recorded exactly one 404 and
  two 200s for those calls.
