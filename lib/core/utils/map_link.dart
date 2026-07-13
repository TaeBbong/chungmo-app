import 'package:flutter/foundation.dart';

/// Builds the URI that opens [query] in the device's map app.
///
/// Android routes `geo:` through the intent chooser, so it lands in whichever
/// map app the user prefers. iOS has no such hook: `maps.apple.com` always
/// opens Apple Maps.
///
/// Uses [defaultTargetPlatform] rather than `dart:io`'s `Platform`, which is
/// unavailable on web and cannot be overridden in tests.
Uri mapSearchUri(String query, {TargetPlatform? platform}) {
  final String encoded = Uri.encodeComponent(query);
  final bool android =
      (platform ?? defaultTargetPlatform) == TargetPlatform.android;

  return Uri.parse(
    android ? 'geo:0,0?q=$encoded' : 'https://maps.apple.com/?q=$encoded',
  );
}
