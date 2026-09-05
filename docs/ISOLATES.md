<!-- docs/ISOLATES.md -->

# Keeping the Main Isolate Free: `compute()` in Practice

How chungmo moved image hashing and image re-encoding off the UI thread,
and why the Lottie parser could not follow them. Written as a working
reference: each section is concept → the actual code in this repo → why it
is shaped that way.

---

## 1. The problem: one isolate, 16.7ms per frame

Dart is single-threaded by default. Everything — your business logic,
`async` callbacks, and **rendering** — runs on one *isolate* (the "main
isolate"), driven by an event loop. At 60fps the UI must produce a frame
every **16.7ms**; whatever your code spends inside one event-loop turn is
subtracted from that budget.

The crucial misconception to kill first: **`async`/`await` does not buy
parallelism.** `await` only yields the event loop *between* chunks of work;
a single synchronous chunk (decode an image, hash 6MB, parse a big JSON)
still blocks rendering for its full duration. If a computation takes 160ms,
the app drops ~10 frames no matter how many `await`s surround it.

An *isolate* is Dart's unit of true parallelism: a separate thread with its
**own heap and its own event loop**. Nothing is shared — no locks, no data
races — which is why the model is called an isolate. The price of that
safety is that isolates communicate only by **message passing**, and every
message is (conceptually) copied.

Flutter wraps the spawn/send/receive/kill lifecycle in one function:

```dart
final result = await compute(entryPointFunction, message);
```

`compute()` spawns a short-lived isolate, runs `entryPointFunction(message)`
there, sends the return value back and shuts the isolate down. Both the
message and the result must be *sendable* (primitives, lists/maps of
sendables, `TypedData`, and plain objects whose fields are sendable — no
open sockets, no `BuildContext`, nothing tied to the UI).

### Where this app was blocking the main isolate

Profiling the invitation-parsing flow surfaced three offenders, all sitting
exactly where the user is watching an animation:

| Site | Work on the main isolate | Cost (host, M4 Pro)¹ |
|---|---|---|
| `image://` key hashing | base64-encode a whole capture, then murmur3 the string | **161ms** on a 6MB capture |
| Share-sheet images | none — but the *upload* paid for it | 487KB sent instead of 65KB |
| Analyze Lottie | unzip + JSON-parse at the moment the loading screen appears | tens of ms, at the worst moment |

¹ A phone is typically several times slower, so on-device costs are worse.

---

## 2. Case 1 — hashing image bytes (`compute` at its simplest)

Schedules parsed from an image get a content-addressed key,
`image://<hash>`, so re-submitting the same capture maps to the same
schedule. The original code:

```dart
final String syntheticLink =
    'image://${await base64Encode(bytes).hashUrl}';
```

Two problems. First, `base64Encode` inflates the input ~1.33× and exists
only to feed a *string* hashing helper — the content being hashed is the
same. Second, all of it ran on the main isolate. The fix, in
[`string_extension.dart`](../lib/core/utils/string_extension.dart):

```dart
extension BytesHashExtension on Uint8List {
  /// Content hash used for `image://` schedule keys, computed in a
  /// background isolate ...
  Future<int> get hashBytes => compute(_murmurOfBytes, this);
}

Future<int> _murmurOfBytes(Uint8List bytes) async {
  final BigInt hash128 = await murmur3f(bytes);
  return hash128.toSigned(32).toInt().abs();
}
```

Call site becomes `'image://${await bytes.hashBytes}'`.

Things worth noticing:

- **The entry point is a top-level function.** `compute` must be able to
  send the function to the new isolate; top-level and static functions
  qualify, closures over local state do not.
- **`Uint8List` is a first-class message.** `TypedData` crosses the isolate
  boundary efficiently; you do not need to convert to `List<int>`.
- **Dropping base64 was the bigger win** (161ms → 18ms even on the same
  thread). Moving to an isolate then turned the remaining 18ms into zero
  main-thread cost. Optimize the work first, then relocate it.
- **Tradeoff:** the derived key changed, so one image re-submitted across
  the update maps to a new schedule once. Content-addressing is a
  convenience here, not an invariant, so that was acceptable — but a hash
  function change is an API change whenever hashes are persisted. Know
  which one you have before "just optimizing" it.

---

## 3. Case 2 — downscaling share-sheet captures (CPU-heavy, worth an isolate)

Images picked from the gallery were already bounded
(`ImagePicker.pickImage(maxWidth: 1600, imageQuality: 85)` — resized by the
OS, off our thread). Images arriving through the share sheet were read raw
and uploaded raw: a modern phone capture is several MB and several thousand
pixels wide, none of which helps a model that reads text off a screenshot.

[`image_preprocessor.dart`](../lib/core/utils/image_preprocessor.dart):

```dart
abstract class ImagePreprocessor {
  static const int maxDimension = 1600;
  static const int jpegQuality = 85;

  static Future<InvitationImage> downscale(InvitationImage image) =>
      compute(downscaleSync, image);

  @visibleForTesting
  static InvitationImage downscaleSync(InvitationImage image) {
    img.Image? decoded;
    try {
      final img.Decoder? decoder = img.findDecoderForData(image.bytes);
      // Header-only parse: dimensions without allocating the raster. The
      // bytes are external input, so a crafted or gigantic image must not
      // OOM the process — isolates share memory, compute() is no shield.
      final img.DecodeInfo? info = decoder?.startDecode(image.bytes);
      if (decoder == null || info == null) return image;
      if (info.width * info.height > maxDecodePixels) return image;
      if (info.width <= maxDimension && info.height <= maxDimension) {
        return image; // small: skip the decode entirely
      }
      decoded = decoder.decodeFrame(0);
      // A portrait phone shot is a landscape frame + EXIF orientation;
      // copyResize bakes that in first, so the long side must be judged
      // on the baked frame.
      if (decoded != null) decoded = img.bakeOrientation(decoded);
    } catch (_) {
      decoded = null; // truncated garbage: pass through, Gemini decides
    }
    if (decoded == null) return image;
    final bool wide = decoded.width >= decoded.height;
    final img.Image resized = img.copyResize(
      decoded,
      width: wide ? maxDimension : null,
      height: wide ? null : maxDimension,
      // Box filter: samples every source pixel on a 2-3x shrink, keeping
      // the invitation's small text readable where linear would alias it.
      interpolation: img.Interpolation.average,
    );
    return InvitationImage(
      bytes: img.encodeJpg(resized, quality: jpegQuality),
      mimeType: 'image/jpeg',
    );
  }
}
```

And the single choke point in `ScheduleRepositoryImpl.analyzeImage` — the
one path every image parse goes through, so all callers get the same
preprocessing. The repository (data layer) rather than the usecase, because
`compute` is a Flutter API and `lib/domain` stays Flutter-free; the data
layer already runs this flow's other isolate work (the image key hash). The
loading state is showing by then: the cubit emits it before the call.

```dart
final InvitationImage prepared = await ImagePreprocessor.downscale(image);
final schedule = await remoteSource.fetchScheduleFromImage(
    prepared.bytes, prepared.mimeType);
```

Why this shape:

- **`package:image` is pure Dart** — decode, resize and encode are ~425ms
  of raw CPU for a 4032×3024 capture (host measurement). That is the
  textbook profile for `compute()`: big, synchronous, self-contained, with
  sendable input and output. (`InvitationImage` is a plain
  `bytes + mimeType` class, so it crosses the boundary as-is.)
- **The sync body is public `@visibleForTesting`.** Unit tests exercise
  `downscaleSync` directly and deterministically; one extra test goes
  through `downscale` to prove the isolate path works end to end.
- **The measured payoff is in the network**, not the CPU: the upload for a
  typical capture shrank 487KB → 65KB (−87%), which is both faster on
  mobile data and cheaper in model input.

### The copy semantics will bite your mocks

`compute` **copies** its message. The `InvitationImage` that reaches the
usecase is *not* the instance the page created. Our cubit test stubbed
`when(analyzeImage.execute(tImage))` — identity-matched — and started
returning null answers. The fix is to match by content:

```dart
verify(analyzeImage.execute(argThat(
    predicate<InvitationImage>(
        (i) => listEquals(i.bytes, tImage.bytes)))));
```

Rule of thumb: anything that crosses an isolate boundary loses identity;
tests (and caches keyed by identity) must key on value instead.

---

## 4. Case 3 — the Lottie that could *not* move (reschedule, don't offload)

The "분석 중" loading screen plays `analyze.lottie`. The old code parsed it
lazily, inside the loading branch's `build`:

unzip the `.lottie` archive → parse the animation JSON → build a
`LottieComposition` — tens of milliseconds on the main isolate, spent at
the exact moment the loading screen appears. The one animation whose whole
job is to look smooth started life by dropping its own frames.

The obvious idea — `compute()` it — **does not work here**, and the reason
is the most useful lesson in this document: a `LottieComposition` is a
complex object graph that is not sendable, and even if it were, copying a
parsed composition back across the boundary would cost roughly what parsing
costs. Isolates can only return *data*; they cannot hand you live objects.

When the result cannot move, move the *timing* instead.
[`analyze_animation.dart`](../lib/presentation/widgets/analyze_animation.dart):

```dart
class AnalyzeAnimation extends StatelessWidget {
  static Future<LottieComposition>? _composition;

  /// Starts parsing the composition (idempotent).
  static Future<LottieComposition> preload() => _composition ??= _load();

  static Future<LottieComposition> _load() async {
    final ByteData data = await rootBundle.load('assets/images/analyze.lottie');
    return LottieComposition.fromByteData(
      data,
      decoder: (List<int> bytes) => LottieComposition.decodeZip(
        bytes,
        filePicker: (files) => files.firstWhere(
          (f) => f.name.startsWith('animations/') && f.name.endsWith('.json'),
        ),
      ),
    );
  }
  // build(): FutureBuilder → Lottie(composition: ...)
}
```

`CreatePage.initState` calls `AnalyzeAnimation.preload()` while the screen
is idle. By the time a user pastes a link, the composition has been parsed
for seconds; entering the loading state swaps in a ready animation.

Two side discoveries along the way:

- The `lottie` package decodes `.lottie` zip archives itself, which made
  the `dotlottie_loader` dependency removable. Its default behavior picks
  the *first* `.json` in the archive — which in a dotLottie file is
  `manifest.json`, not the animation — hence the explicit `filePicker`.
- The memoized static future doubles as a cache: every later loading
  screen reuses the same parsed composition.

The general principle: **offload what is sendable; reschedule what is
not.** Both remove the cost from the frame where it hurts.

---

## 5. When to reach for `compute()` — and when not to

Reach for it when the work is:

1. **Synchronous CPU** measured in ≥ a few milliseconds (image codecs,
   hashing, compression, big JSON). Under ~1ms the spawn+copy overhead of
   `compute` exceeds the work; leave it on the main isolate.
2. **Self-contained**: a pure `input → output` function, no platform
   channels, no plugins, no UI objects. (Platform channels are registered
   per-isolate; most plugins simply do not work inside a background
   isolate.)
3. **Sendable on both ends.**

Prefer other tools when:

- The work is **I/O-bound** (`dio`, `sqflite`, file reads): the OS already
  does that off-thread; `await` is enough.
- The result is **not sendable** → reschedule (the Lottie case).
- The platform already offers an off-thread path → use it (the
  `ImagePicker` native resize is why the gallery path never needed any of
  this).
- The work repeats at high frequency → a long-lived isolate with a message
  loop (`Isolate.spawn`) amortizes the spawn cost; this app has no such
  case yet, `compute`'s one-shot model fits everything above.

## 6. Measurements

Micro-benchmark (Apple M4 Pro host, `dart run`; phones are several × slower):

```
hash old (base64 + murmur3 on 6MB): 161ms   ← was on the main isolate
hash new (murmur3 on raw bytes):     18ms   ← now in a background isolate
source jpeg (4032x3024, q92):       487KB
resized jpeg (1600px, q85):          65KB   (-87% upload)
decode+resize+encode:               425ms   ← pure CPU, in an isolate
```

Verified on device (Galaxy S20+ / iPhone 17 Pro simulator): the analyze
animation now runs from its first frame, and share-sheet parses upload the
downscaled JPEG.
