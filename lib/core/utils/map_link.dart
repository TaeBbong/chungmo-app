import 'dart:io';

/// Builds the URI that opens [query] in the device's map app.
///
/// Android routes `geo:` through the intent chooser, so it lands in whichever
/// map app the user prefers. iOS has no such hook: `maps.apple.com` always
/// opens Apple Maps.
///
/// [isAndroid] is injectable for tests; it defaults to the running platform.
Uri mapSearchUri(String query, {bool? isAndroid}) {
  final String encoded = Uri.encodeComponent(query);
  final bool android = isAndroid ?? Platform.isAndroid;

  return Uri.parse(
    android ? 'geo:0,0?q=$encoded' : 'https://maps.apple.com/?q=$encoded',
  );
}
