<!-- docs/MICRO_INTERACTIONS.md -->

# Micro-Interactions: Motion as a System

How chungmo went from "almost no animation" to consistent app-wide motion
using only Flutter's implicit animation widgets — no `AnimationController`
anywhere. Each section: the concept, the actual code in this repo, and why
it works.

---

## 0. The starting point, and the one rule

An audit found the app essentially static: analyze states hard-swapped,
list tiles gave no touch feedback, charts appeared fully formed, no haptics.
Motion was added under one rule:

> **Prefer implicit animation widgets over explicit controllers.**

Flutter has two animation families. *Explicit* animations
(`AnimationController` + `Ticker`) give frame-level control at the cost of
a `StatefulWidget`, lifecycle management and disposal. *Implicit* widgets
(`AnimatedScale`, `AnimatedSwitcher`, `TweenAnimationBuilder`, …) own their
controller internally: you declare the target value, they animate toward it
whenever it changes. Every effect below turned out to be reachable with the
implicit family, which keeps the widgets stateless-ish, testable and
impossible to leak.

---

## 1. Motion tokens — the design-system move

**Concept.** Ad-hoc `Duration(milliseconds: 300)` scattered per widget is
the motion equivalent of hard-coded paddings. The fix is the same one
[`Dimens`](../lib/presentation/theme/dimens.dart) applies to spacing: a
token vocabulary. [`motions.dart`](../lib/presentation/theme/motions.dart):

```dart
abstract class Motions {
  static const Duration quick = Duration(milliseconds: 150);     // feedback
  static const Duration standard = Duration(milliseconds: 250);  // state changes
  static const Duration emphasized = Duration(milliseconds: 600); // one-off drama
  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve emphasizedEase = Curves.easeOutQuart;
  static const double pressedScale = 0.97;
}
```

**Why decelerate curves as the default:** UI motion is a *response to
input*. A curve that starts fast and settles (`easeOut*`) makes the
response appear instantly and land gently; a symmetric or ease-in curve
adds perceived latency before anything visibly happens. The `emphasized`
duration pairs with the stronger `easeOutQuart` for the same reason: most
of the change lands early, so a 600ms chart draw still *feels* responsive.

---

## 2. Pressed feedback — `AnimatedScale` (implicit animation #1)

**Concept.** A bare `GestureDetector` swallows the tap silently; Material's
`InkWell` answers with a ripple, but ripples fight the app's flat,
Toss-style cards. The third convention — used by Toss itself — is a subtle
scale-down while the finger is down.

[`pressable.dart`](../lib/presentation/widgets/pressable.dart):

```dart
class _PressableState extends State<Pressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? Motions.pressedScale : 1.0,
        duration: Motions.quick,
        curve: Motions.easeOut,
        child: widget.child,
      ),
    );
  }
}
```

**Explanation.** The entire animation is one line of *declared state*:
`scale: _pressed ? 0.97 : 1.0`. `AnimatedScale` notices the target changed
and tweens to it — down on `tapDown`, back up on `tapUp`/`tapCancel`
(`tapCancel` matters: without it a drag-away leaves the card stuck small).
Wrapping this once in `Pressable` instead of re-implementing per call site
is what makes it a *system*; list tiles and preview cards now share the
identical response.

---

## 3. State transitions — `AnimatedSwitcher` and widget identity

**Concept.** The home screen's analyze flow renders one of four subtrees
(idle / loading / error / result) from a `BlocBuilder`. Replacing one
subtree with another normally *pops*: old gone, new there, same frame.
`AnimatedSwitcher` cross-fades between its old and new `child` — but only
when it can tell the child *changed*, and that is where Flutter's identity
rules earn their keep:

- Flutter considers two widgets "the same element" when `runtimeType` and
  `key` match at the same tree position.
- Therefore each branch must carry a distinct **key** — otherwise a
  `Column` swapping to another `Column` looks like "no change".
- And the `AnimatedSwitcher` itself must be **the same element across
  builds** — if each branch built its own switcher *with different child
  types around it*, the switcher would be replaced along with its child and
  nothing would animate.

The implementation in
[`create_page.dart`](../lib/presentation/pages/create_page.dart) leans on
rule three explicitly — every branch `return`s through one helper, so the
switcher always sits at the same position in the tree and survives:

```dart
/// Every branch returns this wrapper at the same tree position, so the
/// AnimatedSwitcher element persists across builds and only its keyed
/// child changes — which is what triggers the transition.
Widget _analyzeBranch(String branch, Widget child) {
  return AnimatedSwitcher(
    duration: Motions.standard,
    switchInCurve: Motions.easeOut,
    switchOutCurve: Motions.easeOut,
    transitionBuilder: (Widget child, Animation<double> animation) =>
        FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: Motions.emergeScale, end: 1)
            .animate(animation),
        child: child,
      ),
    ),
    child: KeyedSubtree(key: ValueKey<String>(branch), child: child),
  );
}
// if (state.isLoading) return _analyzeBranch('loading', ...);
// if (state.isError)   return _analyzeBranch('error', ...);
// return _analyzeBranch(state.schedule != null ? 'result' : 'idle', ...);
```

**Details worth stealing:**

- `KeyedSubtree` attaches a key to an arbitrary child without wrapping it
  in a container that would affect layout.
- The transition combines fade with a `Motions.emergeScale → 1.0` scale.
  Full-size cross-fades look like a video dissolve; the 2% scale adds just
  enough depth to read as "new content arriving".
- The clipboard paste chip takes the simpler path: it is conditionally
  mounted inside a `FadeSlideIn` (§4), so detection slides it in through
  the shared entrance widget instead of a second bespoke slide.
- The copy button in
  [`account_section.dart`](../lib/presentation/widgets/account_section.dart)
  is the smallest possible instance: two keyed `Icon`s (copy ⇄ check) under
  a `ScaleTransition`, reverted by a 2-second `Timer`.

---

## 4. One-shot entrances — `TweenAnimationBuilder`

**Concept.** `TweenAnimationBuilder<T>` animates from its current value to
`tween.end` whenever the tween changes — and, crucially, **it plays once on
first build** (from `begin` to `end`). That makes it the lightest possible
"entrance animation" primitive: no controller, no `initState`, and the
animated value is handed to you as a plain number to use however you like.

The stats dashboard drives *all* of its entrance from one such widget,
[`stats_page.dart`](../lib/presentation/pages/stats_page.dart):

```dart
class _Entrance extends StatelessWidget {
  final Widget Function(BuildContext context, double t) builder;
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Motions.emphasized,
      curve: Motions.emphasizedEase,
      builder: (BuildContext context, double t, _) => builder(context, t),
    );
  }
}
```

The `t ∈ [0, 1]` is then *multiplied into the data*, which is the trick —
the same scalar animates three visually different things:

```dart
Text(format((value * t).round()))            // summary numbers count up
BarChartRodData(toY: total.toDouble() * t)   // bars grow from the baseline
LinearProgressIndicator(value: share * t)    // relation fills sweep in
```

**Why multiply into data instead of wrapping in `ScaleTransition`?**
Scaling the *widget* would distort labels and round corners; scaling the
*value* redraws the chart at every intermediate data point, so bars grow
along their own axis with correct labels throughout. It is the same
principle as the D-day widget computing at render time: animate the source
of truth, not a picture of it.

The detail page's card entrance,
[`fade_slide_in.dart`](../lib/presentation/widgets/fade_slide_in.dart),
shows one more pattern on the same primitive — a **delay without a
controller**. The delay is encoded as the leading, clamped-to-zero fraction
of one longer tween:

```dart
final double local = Motions.easeOut.transform(
    ((t - delayFraction) / (1 - delayFraction)).clamp(0, 1));
return Opacity(
  opacity: local,
  child: Transform.translate(
      offset: Offset(0, Motions.slideOffset * (1 - local)), ...),
);
```

For the first `delayFraction` of the duration `local` stays 0 (child held
invisible); after that it runs the eased 0→1. Note the curve is applied
*manually* via `curve.transform(...)` — the outer tween must stay linear or
the delay fraction would be warped by the easing.

---

## 5. Haptics — the non-visual channel

**Concept.** `HapticFeedback` (from `flutter/services.dart`) is a
zero-dependency, one-line channel that confirms an action even when the
user isn't looking at the exact pixel that changed. The discipline is
*sparseness*: haptics on everything is noise; haptics on **terminal or
destructive actions** is confirmation.

Where this app vibrates, and the reasoning recorded next to each call:

| Site | Call | Why |
|---|---|---|
| Account number copied | `lightImpact` | the one action performed mid-motion, on the way to a bank app |
| Record saved (page pops) | `mediumImpact` | terminal step of the record flow |
| Analyze result saved | `mediumImpact` | terminal step of the parse flow |
| Delete confirmed | `mediumImpact` | destructive, deserves physical weight |

`light`/`medium`/`heavy` map to platform-defined strengths; matching the
weight of the action (light for a convenience, medium for a commit) is the
whole art.

---

## 6. What was tried and rolled back: the Hero flight

The first iteration also wired a `Hero` shared-element transition — list
thumbnail flying into the detail header. Technically it worked (same tag on
both routes, unique per schedule link), but visually it zoomed a small
*circle* avatar into a full-bleed *rectangular* header, and the shape
mismatch made the flight feel heavy-handed rather than continuous. It was
removed in favor of the standard Cupertino push plus the card's
`FadeSlideIn`.

Two lessons kept from the exercise:

1. `Hero` is trivial to add (wrap both ends, match the `tag`) — the cost
   is not code but *judgment*: shared-element transitions only read well
   when the two endpoints have similar shape and aspect.
2. Motion polish is subtractive as often as additive. The rollback commit
   is part of the polish.

---

## 7. Performance footnote

None of this holds 60fps by itself — the loading transition cross-fades
into a Lottie that used to be parsed on the main isolate at that exact
moment, and a shared image used to be hashed there too. The groundwork
that keeps these animations smooth is documented separately in
[`ISOLATES.md`](./ISOLATES.md); the two documents describe one feature
branch.
