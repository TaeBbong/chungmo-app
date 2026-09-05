import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import '../../core/analytics/analytics_service.dart';
import '../../core/di/di.dart';

/// The looping animation shown while an invitation parse is running.
///
/// The composition (unzipping `analyze.lottie` and parsing its JSON) is
/// prepared once via [preload], during page init, instead of on first
/// build — parsing costs the main isolate tens of milliseconds and used to
/// land exactly when the loading screen appeared. A [LottieComposition]
/// holds non-sendable objects, so this work cannot move to a background
/// isolate; rescheduling it to before any user interaction is the fix.
class AnalyzeAnimation extends StatelessWidget {
  const AnalyzeAnimation({super.key});

  static Future<LottieComposition>? _composition;

  /// Starts parsing the composition (idempotent).
  ///
  /// Called by CreatePage.initState.
  static Future<LottieComposition> preload() {
    final Future<LottieComposition> future = _composition ??= _load();
    // A failed load (missing asset, malformed archive) must not be cached
    // forever — that would pin the loading screen to its spinner. Observing
    // the failure here also keeps the eager initState call from surfacing
    // an unhandled async error; Crashlytics still learns why the animation
    // never appeared.
    future.then<void>((_) {}, onError: (Object error, StackTrace stack) {
      if (identical(_composition, future)) _composition = null;
      getIt<AnalyticsService>()
          .recordError(error, stack, reason: 'analyze_lottie_preload');
    });
    return future;
  }

  static Future<LottieComposition> _load() async {
    final ByteData data = await rootBundle.load('assets/images/analyze.lottie');
    return LottieComposition.fromByteData(
      data,
      // A .lottie archive holds manifest.json next to animations/*.json;
      // the default picker takes the first .json it sees, which may be the
      // manifest, so pick the animation explicitly.
      decoder: (List<int> bytes) => LottieComposition.decodeZip(
        bytes,
        filePicker: (files) => files.firstWhere(
          (f) => f.name.startsWith('animations/') && f.name.endsWith('.json'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LottieComposition>(
      future: preload(),
      builder: (context, snapshot) {
        final LottieComposition? composition = snapshot.data;
        if (composition == null) {
          // Only reachable when a parse starts before preload finished
          // (i.e. a launch-time share); the composition arrives within
          // frames and swaps in.
          return const Center(child: CircularProgressIndicator());
        }
        return Lottie(composition: composition);
      },
    );
  }
}
