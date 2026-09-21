import 'package:chungmo/core/utils/map_link.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const location = '신도림 라마다 호텔 2층 그랜드볼룸홀';

  test('should build a geo: intent uri on Android', () {
    final uri = mapSearchUri(location, platform: TargetPlatform.android);

    expect(uri.scheme, 'geo');
    expect(uri.toString(), contains(Uri.encodeComponent(location)));
  });

  test('should build an Apple Maps uri on iOS', () {
    final uri = mapSearchUri(location, platform: TargetPlatform.iOS);

    expect(uri.host, 'maps.apple.com');
    expect(uri.queryParameters['q'], location);
  });

  test('searches the venue name when the parser extracted one', () {
    expect(
      mapSearchQuery(venue: '더채플앳청담', location: '더채플앳청담 3층 채플홀'),
      '더채플앳청담',
    );
  });

  test('falls back to the full location for legacy and manual entries', () {
    expect(
      mapSearchQuery(venue: '', location: '아펠가모 공덕 라로브홀'),
      '아펠가모 공덕 라로브홀',
    );
  });
}
