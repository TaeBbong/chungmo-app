import 'package:chungmo/core/utils/map_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const location = '신도림 라마다 호텔 2층 그랜드볼룸홀';

  test('should build a geo: intent uri on Android', () {
    final uri = mapSearchUri(location, isAndroid: true);

    expect(uri.scheme, 'geo');
    expect(uri.toString(), contains(Uri.encodeComponent(location)));
  });

  test('should build an Apple Maps uri on iOS', () {
    final uri = mapSearchUri(location, isAndroid: false);

    expect(uri.host, 'maps.apple.com');
    expect(uri.queryParameters['q'], location);
  });
}
